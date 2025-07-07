import React from 'react';
import { motion } from 'framer-motion';
import { 
  Lightbulb, 
  Lock, 
  Thermometer, 
  Wifi, 
  DoorOpen, 
  Bell, 
  Smartphone,
  Refrigerator,
  Fan,
  Car,
  Power,
  Laptop
} from 'lucide-react';
import { ref, set } from 'firebase/database';
import { database } from '../lib/firebase';

const deviceIcons = {
  'Switch': Power,
  'Blub': Lightbulb,
  'Door Lock': Lock,
  'Corridor Light': Lightbulb,
  'Motion Sensor': Wifi,
  'Bathroom Heater': Thermometer,
  'Bathroom Light': Lightbulb,
  'Main Entrance Lock': Lock,
  'Doorbell': Bell,
  'Kitchen Light': Lightbulb,
  'Refrigerator': Refrigerator,
  'Bedroom Light': Lightbulb,
  'Air Conditioner': Fan,
  'Garage Light': Lightbulb,
  'Garage Door': DoorOpen,
  'my_laptop': Laptop,
  'default': Smartphone
};

export default function DeviceCard({ device, deviceId, environmentId, symbol }) {
  const Icon = deviceIcons[device.name] || deviceIcons.default;
  
  const toggleDevice = async () => {
    try {
      await set(ref(database, `environments/${environmentId}/devices/${deviceId}/state`), !device.state);
      // Also update the symbol state if it exists
      if (device.assignedSymbol && symbol) {
        await set(ref(database, `symbols/${device.assignedSymbol}/state`), !device.state);
      }
    } catch (error) {
      console.error('Error toggling device:', error);
    }
  };

  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="device-card cursor-pointer"
      onClick={toggleDevice}
    >
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className={`p-3 rounded-xl ${
            device.state 
              ? 'bg-primary-500/20 text-primary-400' 
              : 'bg-gray-500/20 text-gray-400'
          }`}>
            <Icon size={24} />
          </div>
          <div>
            <h3 className="font-semibold text-lg">{device.name}</h3>
            <p className="text-sm text-gray-400">
              {symbol ? `Symbol: ${symbol.name}` : 'No symbol assigned'}
            </p>
          </div>
        </div>
        
        <div className="flex items-center space-x-3">
          <div className={`px-3 py-1 rounded-full text-xs font-medium ${
            device.state 
              ? 'bg-green-500/20 text-green-400' 
              : 'bg-red-500/20 text-red-400'
          }`}>
            {device.state ? 'ON' : 'OFF'}
          </div>
          
          <button
            className={`toggle-switch ${
              device.state ? 'bg-primary-500' : 'bg-gray-600'
            }`}
            onClick={(e) => {
              e.stopPropagation();
              toggleDevice();
            }}
          >
            <span
              className={`toggle-switch-thumb ${
                device.state ? 'translate-x-6' : 'translate-x-1'
              }`}
            />
          </button>
        </div>
      </div>

      {device.allowedUsers && (
        <div className="pt-3 border-t border-white/10">
          <p className="text-xs text-gray-400">
            Restricted Access • {Object.keys(device.allowedUsers).length} user(s)
          </p>
        </div>
      )}
    </motion.div>
  );
}
