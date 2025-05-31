import 'package:firebase_database/firebase_database.dart';

class   DeviceService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("environments/env_12345");
  final DatabaseReference _symbolsRef = FirebaseDatabase.instance.ref("symbols");

  // New method to listen to symbol changes
  Stream<Map<String, dynamic>> getSymbolsStream() {
    return _symbolsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) {
        print("🟠 No symbols found in stream.");
        return <String, dynamic>{};
        
      }

      final symbolsData = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      print("🔵 Symbol Stream Update: ${symbolsData.length} symbols");
      return symbolsData;
    });
  }

  Future<List<Map<String, String>>> getAvailableSymbols() async {
    try {
      print("🟢 Fetching available symbols...");
      final snapshot = await _symbolsRef.get();

      if (!snapshot.exists) {
        print("🟠 No symbols found in Firebase.");
        return [];
      }

      final symbolsData = snapshot.value as Map<dynamic, dynamic>;
      final availableSymbols = <Map<String, String>>[];

      symbolsData.forEach((symbolId, symbolInfo) {
        final symbol = Map<String, dynamic>.from(symbolInfo);
        if (symbol["available"] == true) {
          availableSymbols.add({
            "id": symbolId as String,
            "name": symbol["name"] as String,
          });
        }
      });

      print("🔵 Available Symbols: $availableSymbols");
      return availableSymbols;
    } catch (e) {
      print("❌ Error fetching available symbols: $e");
      return [];
    }
  }

  Future<String> getSymbolName(String symbolId) async {
    try {
      final snapshot = await _symbolsRef.child(symbolId).get();
      if (snapshot.exists) {
        final symbolData = snapshot.value as Map<dynamic, dynamic>;
        return symbolData["name"] ?? "Unknown Symbol";
      } else {
        return "Unknown Symbol";
      }
    } catch (e) {
      print("❌ Error fetching symbol name: $e");
      return "Unknown Symbol";
    }
  }

  /// 🔥 Fetch used symbols (to prevent duplicates)
  Future<List<String>> getUsedSymbols() async {
    try {
      print("🟢 Fetching used symbols...");
      final snapshot = await _dbRef.child("devices").get();
      if (!snapshot.exists) {
        print("🟠 No devices found.");
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      List<String> usedSymbols = [];

      data.forEach((deviceId, deviceData) {
        final device = Map<String, dynamic>.from(deviceData);
        if (device.containsKey("assignedSymbol")) {
          usedSymbols.add(device["assignedSymbol"]);
        }
      });

      print("🔵 Used Symbols: $usedSymbols");
      return usedSymbols;
    } catch (e) {
      print("❌ Error fetching used symbols: $e");
      return [];
    }
  }

  /// 🔥 Update symbol state (this updates the device state too)
  Future<void> updateSymbolState(String symbolId, bool newState) async {
    try {
      await _symbolsRef.child(symbolId).update({"state": newState});
      print("✅ Symbol $symbolId state updated to: ${newState ? "ON" : "OFF"}");
    } catch (e) {
      print("❌ Error updating symbol state: $e");
    }
  }

  /// 🔥 Add a new device with a symbol
  Future<void> addDevice(String deviceName, String symbolId, String? roomId) async {
    try {
      // Ensure the symbol exists and is available
      final symbolSnapshot = await _symbolsRef.child(symbolId).get();
      if (!symbolSnapshot.exists || !(symbolSnapshot.value as Map)["available"]) {
        print("❌ Symbol $symbolId is not available!");
        return;
      }

      final newDeviceId = "dev_${DateTime.now().millisecondsSinceEpoch}";
      final symbolState = (symbolSnapshot.value as Map)["state"] ?? false;

      Map<String, dynamic> newDevice = {
        "name": deviceName,
        "roomId": roomId ?? "",
        "allowedUsers": {},
        "assignedSymbol": symbolId,
        "state": symbolState, // 🔥 Device state is now the symbol state
      };

      // Add device to Firebase
      await _dbRef.child("devices").child(newDeviceId).set(newDevice);

      // Mark symbol as unavailable
      await _symbolsRef.child(symbolId).update({"available": false});

      // Add device to room if specified
      if (roomId != null && roomId.isNotEmpty) {
        await _dbRef.child("rooms").child(roomId).child("devices").child(newDeviceId).set(true);
      }

      print("✅ Device $deviceName added successfully with symbol $symbolId");
    } catch (e) {
      print("❌ Error adding device: $e");
    }
  }

  /// 🔥 Remove device (also makes the symbol available again)
  Future<void> removeDevice(String deviceId, String symbolId) async {
    try {
      await _dbRef.child("devices").child(deviceId).remove();
      await _symbolsRef.child(symbolId).update({"available": true});
      print("✅ Device $deviceId removed, symbol $symbolId is now available");
    } catch (e) {
      print("❌ Error removing device: $e");
    }
  }
}