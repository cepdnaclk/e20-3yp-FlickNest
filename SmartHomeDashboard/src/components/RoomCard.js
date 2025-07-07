import React from 'react';
import { motion } from 'framer-motion';
import { Home, Lightbulb, Settings } from 'lucide-react';
import DeviceCard from './DeviceCard';

export default function RoomCard({ room, roomId, devices, symbols, environmentId }) {
  const roomDevices = room.devices ? Object.keys(room.devices) : [];
  const activeDevices = roomDevices.filter(deviceId => devices[deviceId]?.state).length;
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="room-card"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-xl bg-primary-500/20 text-primary-400">
            <Home size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold">{room.name}</h2>
            <p className="text-sm text-gray-400">
              {roomDevices.length} device(s) • {activeDevices} active
            </p>
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${
            activeDevices > 0 ? 'bg-green-400 animate-pulse-slow' : 'bg-gray-500'
          }`} />
          <span className="text-sm text-gray-400">
            {activeDevices > 0 ? 'Active' : 'Idle'}
          </span>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {roomDevices.map(deviceId => {
          const device = devices[deviceId];
          if (!device) return null;
          
          const symbol = device.assignedSymbol ? symbols[device.assignedSymbol] : null;
          
          return (
            <DeviceCard
              key={deviceId}
              device={device}
              deviceId={deviceId}
              environmentId={environmentId}
              symbol={symbol}
            />
          );
        })}
      </div>
      
      {roomDevices.length === 0 && (
        <div className="text-center py-12">
          <Settings className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <p className="text-gray-400">No devices in this room</p>
        </div>
      )}
    </motion.div>
  );
}
