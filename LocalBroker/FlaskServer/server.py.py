from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
import json
import os
import threading
import time
import logging
from datetime import datetime
import paho.mqtt.client as mqtt
from flask_cors  import CORS

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = 'your-secret-key-here'
socketio = SocketIO(app, cors_allowed_origins="*", logger=True, engineio_logger=True)

# Configuration
DB_PATH = "db.json"
MQTT_BROKER = "localhost"
MQTT_TOPIC = "esp/data"
MQTT_PORT = 1883
MQTT_KEEPALIVE = 60

# Global MQTT client
mqtt_client = None
mqtt_connected = False

# Hardcoded name → ID map
SYMBOL_NAME_TO_ID = {
    "circle": "sym_001",
    "wave": "sym_002",
    "updown": "sym_003",
    "double_tap": "sym_004",
    "swipe_up": "sym_005",
    "swipe_down": "sym_006",
    "double_wave": "sym_007",
    "flick": "sym_008",
    "knock": "sym_009",
    "clap": "sym_010",
    "press": "sym_011",
    "tilt": "sym_012",
    "rotate": "sym_013",
    "flip": "sym_014",
    "tap": "sym_015",
    "arise": "sym_016",
    "rectangle": "sym_017",
}


def load_db():
    """Load database from JSON file"""
    try:
        if not os.path.exists(DB_PATH):
            logger.info(f"Database file {DB_PATH} not found, creating new one")
            return {"symbols": {}}
        
        with open(DB_PATH, "r") as f:
            data = json.load(f)
            # Ensure symbols key exists
            if "symbols" not in data:
                data["symbols"] = {}
            return data
    except Exception as e:
        logger.error(f"Error loading database: {e}")
        return {"symbols": {}}

def save_db(data):
    """Save database to JSON file"""
    try:
        with open(DB_PATH, "w") as f:
            json.dump(data, f, indent=2)
        logger.info("Database saved successfully")
    except Exception as e:
        logger.error(f"Error saving database: {e}")

@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "mqtt_connected": mqtt_connected,
        "timestamp": datetime.now().isoformat()
    })

@app.route("/symbols", methods=["GET"])
def get_all_symbols():
    """Get all symbols"""
    db = load_db()
    return jsonify(db.get("symbols", {}))

@app.route("/symbols/<symbol>", methods=["GET", "PATCH"])
def handle_symbol(symbol):
    """Handle GET and PATCH requests for specific symbol"""
    logger.info(f"Request for symbol: {symbol}, method: {request.method}")
    
    db = load_db()
    
    if request.method == "GET":
        symbol_data = db["symbols"].get(symbol, {})
        logger.info(f"GET {symbol}: {symbol_data}")
        return jsonify(symbol_data)
    
    elif request.method == "PATCH":
        try:
            update_data = request.get_json()
            if not update_data:
                return jsonify({"error": "No data provided"}), 400
            
            logger.info(f"PATCH {symbol}: {update_data}")
            
            # Initialize symbol if it doesn't exist
            if symbol not in db["symbols"]:
                db["symbols"][symbol] = {}
            
            # Update symbol data
            db["symbols"][symbol].update(update_data)
            db["symbols"][symbol]["source"] = "mobile"
            
            save_db(db)
            symbol_name = db["symbols"][symbol].get("name")
            
            state  = db["symbols"][symbol].get("state")

            publish_to_mqtt(symbol, symbol_name, state)
            # Emit update via WebSocket
            socketio.emit("update", {symbol: db["symbols"][symbol]})
            
            return jsonify({symbol: db["symbols"][symbol]})
            
        except Exception as e:
            logger.error(f"Error updating symbol {symbol}: {e}")
            return jsonify({"error": str(e)}), 500

@app.route("/esp_upload", methods=["POST"])
def esp_upload():
    """Handle ESP32 HTTP uploads"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        logger.info(f"ESP upload data: {data}")
        
        # Find the symbol with boolean value True
        symbol = None
        for key, value in data.items():# Might have problems so change how the json comes symbol: circle
            if isinstance(value, bool) and value:
                symbol = key
                break
        
        if not symbol:
            return jsonify({"error": "No valid symbol with True value found"}), 400
        
        db = load_db()
        symbol_name = symbol.lower()
        found_symbol = SYMBOL_NAME_TO_ID.get(symbol_name)

        if not found_symbol:
                logger.warning(f"Symbol with name '{symbol}' not found in database, ignoring MQTT message")
                return
            
        # Get current state and toggle it
        current_state = db["symbols"][found_symbol].get("state", False)
        new_state = not current_state


        # Update symbol data
        db["symbols"][found_symbol].update({
            "state": new_state,
            "source": "broker",
        })
        
        save_db(db)
        
        # Emit update via WebSocket - use the symbol key for consistency
        socketio.emit("update", {found_symbol: db["symbols"][found_symbol]}) #update the format
        
        logger.info(f"ESP32 HTTP: {symbol} state set to on")
        return jsonify({
            "message": f"{symbol} state toggled to {new_state}", 
            "symbol": found_symbol,
            "symbol_name": symbol,
            "new_state": new_state
        })
    except Exception as e:
        logger.error(f"Error in ESP upload: {e}")
        return jsonify({"error": str(e)}), 500

def mqtt_on_connect(client, userdata, flags, rc):
    """MQTT connection callback"""
    global mqtt_connected
    if rc == 0:
        mqtt_connected = True
        logger.info("MQTT connected successfully")
        client.subscribe(MQTT_TOPIC)
        logger.info(f"Subscribed to topic: {MQTT_TOPIC}")
    else:
        mqtt_connected = False
        logger.error(f"MQTT connection failed with code {rc}")

def mqtt_on_disconnect(client, userdata, rc):
    """MQTT disconnection callback"""
    global mqtt_connected
    mqtt_connected = False
    logger.warning(f"MQTT disconnected with code {rc}")

def mqtt_on_message(client, userdata, msg):
    """MQTT message callback"""
    try:
        payload = msg.payload.decode()
        logger.info(f"MQTT message received: {payload}")
        
        data = json.loads(payload)
        
        # Find the symbol with boolean value True
        symbol = None
        for key, value in data.items():
            if isinstance(value, bool) and value:
                symbol = key.lower()
                break
        
        if symbol:
            db = load_db()
            
            # Initialize symbol if it doesn't exist
            symbol_name = symbol.lower()
            found_symbol_key = SYMBOL_NAME_TO_ID.get(symbol_name)

            if not found_symbol_key:
                logger.warning(f"Symbol with name '{symbol}' not found in database, ignoring MQTT message")
                return
            
            # Get current state and toggle it
            current_state = db["symbols"][found_symbol_key].get("state", False)
            new_state = not current_state
            
            logger.info(f"MQTT: {found_symbol_key} ({symbol}) toggling from {current_state} to {new_state}")
            
            # Update symbol data with toggled state
            db["symbols"][found_symbol_key].update({
                "state": new_state,
                "source": "broker"
            })
            
            save_db(db)
            
            # Emit update via WebSocket
            socketio.emit("update", {symbol: db["symbols"][found_symbol_key]})
            
            logger.info(f"MQTT: {symbol} state set to on")
        else:
            logger.warning(f"No valid symbol found in MQTT message: {data}")
            
    except json.JSONDecodeError as e:
        logger.error(f"MQTT JSON decode error: {e}")
    except Exception as e:
        logger.error(f"MQTT message processing error: {e}")

def start_mqtt():
    """Start MQTT client in a separate thread"""
    global mqtt_client
    
    try:
        mqtt_client = mqtt.Client()
        mqtt_client.on_connect = mqtt_on_connect
        mqtt_client.on_disconnect = mqtt_on_disconnect
        mqtt_client.on_message = mqtt_on_message
        
        logger.info(f"Connecting to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
        mqtt_client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE)
        
        # Start the MQTT loop
        mqtt_client.loop_forever()
        
    except Exception as e:
        logger.error(f"MQTT setup error: {e}")
        logger.info("Server will continue without MQTT functionality")

def mqtt_reconnect():
    """Reconnect to MQTT broker"""
    global mqtt_client, mqtt_connected
    
    while True:
        if not mqtt_connected and mqtt_client:
            try:
                logger.info("Attempting MQTT reconnection...")
                mqtt_client.reconnect()
            except Exception as e:
                logger.error(f"MQTT reconnection failed: {e}")
        
        time.sleep(30)  # Try reconnecting every 30 seconds

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    logger.info(f"Client connected: {request.sid}")
    emit('status', {'message': 'Connected to server'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnection"""
    logger.info(f"Client disconnected: {request.sid}")

@socketio.on('request_all_symbols')
def handle_request_all_symbols():
    """Handle request for all symbols via WebSocket"""
    db = load_db()
    emit('all_symbols', db.get("symbols", {}))

def publish_to_mqtt(symbol_key, symbol_name, state):
    """Publish symbol state to MQTT"""
    global mqtt_client
    
    if mqtt_client and mqtt_connected:
        try:
            # Create message with symbol name and its toggled state
            message = {symbol_name: state}
            
            # Publish to esp/control topic (or whatever topic your ESP32 subscribes to)
            mqtt_client.publish("esp/control", json.dumps(message))
            logger.info(f"Published to MQTT: {message} for symbol {symbol_key}")
            
        except Exception as e:
            logger.error(f"Error publishing to MQTT: {e}")
    else:
        logger.warning("MQTT client not connected, cannot publish")


if __name__ == "__main__":
    # Initialize database
    db = load_db()
    save_db(db)
    logger.info("Database initialized")
    
    # Start MQTT client in a separate thread
    mqtt_thread = threading.Thread(target=start_mqtt, daemon=True)
    mqtt_thread.start()
    
    # Start MQTT reconnection thread
    reconnect_thread = threading.Thread(target=mqtt_reconnect, daemon=True)
    reconnect_thread.start()
    
    # Start the Flask-SocketIO server
    logger.info("Starting Flask-SocketIO server on 0.0.0.0:5000")
    socketio.run(app, host="0.0.0.0", port=5000, debug=False)
