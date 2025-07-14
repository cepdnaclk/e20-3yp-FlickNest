import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  User, 
  Crown, 
  Shield, 
  ChevronDown, 
  ChevronUp,
  Lightbulb,
  Lock,
  Thermometer,
  Power,
  Device,
  Wifi,
  Bell,
  DoorOpen,
  Fan,
  Refrigerator,
  Laptop
} from 'lucide-react';

const getRoleIcon = (role) => {
  switch (role) {
    case 'admin':
      return <Crown className="h-3 w-3 text-yellow-500" />;
    case 'co-admin':
      return <Shield className="h-3 w-3 text-blue-500" />;
    case 'user':
      return <User className="h-3 w-3 text-green-500" />;
    default:
      return <User className="h-3 w-3 text-gray-500" />;
  }
};

const getRoleBadgeColor = (role) => {
  switch (role) {
    case 'admin':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300';
    case 'co-admin':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
    case 'user':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
  }
};

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
  'default': Device
};

export default function DeviceAccessTable({ devices, users, rooms }) {
  const [expandedRows, setExpandedRows] = useState(new Set());

  const toggleRow = (deviceId) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(deviceId)) {
      newExpanded.delete(deviceId);
    } else {
      newExpanded.add(deviceId);
    }
    setExpandedRows(newExpanded);
  };

  // Prepare data for device access
  const deviceAccessData = Object.entries(devices).map(([deviceId, device]) => {
    const allowedUserIds = device.allowedUsers ? Object.keys(device.allowedUsers) : [];
    const allowedUsers = allowedUserIds.map(userId => ({
      id: userId,
      ...users[userId]
    })).filter(user => user.name); // Filter out undefined users

    const roomName = rooms[device.roomId]?.name || 'Unknown Room';

    return {
      id: deviceId,
      ...device,
      roomName,
      allowedUsers
    };
  });

  return (
    <div className="glass-card rounded-xl overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          Device Access Control
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          View and manage which users can access each device
        </p>
      </div>
      
      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead className="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Device
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Room
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Authorized Users
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            {deviceAccessData.map((device) => {
              const DeviceIcon = deviceIcons[device.name] || deviceIcons.default;
              
              return (
                <React.Fragment key={device.id}>
                  <motion.tr
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3 }}
                    className="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors duration-200"
                  >
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className={`p-2 rounded-lg ${
                          device.state 
                            ? 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400' 
                            : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                        }`}>
                          <DeviceIcon className="h-5 w-5" />
                        </div>
                        <div className="ml-3">
                          <div className="text-sm font-medium text-gray-900 dark:text-white">
                            {device.name}
                          </div>
                          <div className="text-sm text-gray-500 dark:text-gray-400">
                            {device.assignedSymbol || 'No symbol'}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900 dark:text-white">
                        {device.roomName}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        device.state 
                          ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                          : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                      }`}>
                        {device.state ? 'Active' : 'Inactive'}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <span className="text-sm font-medium text-gray-900 dark:text-white">
                          {device.allowedUsers.length} user(s)
                        </span>
                        {device.allowedUsers.length > 0 && (
                          <div className="ml-2 flex -space-x-1">
                            {device.allowedUsers.slice(0, 3).map((user, index) => (
                              <div
                                key={index}
                                className="h-6 w-6 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center border-2 border-white dark:border-gray-900 text-xs text-white font-medium"
                                title={`${user.name} (${user.role})`}
                              >
                                {user.name?.charAt(0)?.toUpperCase() || 'U'}
                              </div>
                            ))}
                            {device.allowedUsers.length > 3 && (
                              <div className="h-6 w-6 rounded-full bg-gray-500 flex items-center justify-center border-2 border-white dark:border-gray-900 text-xs text-white">
                                +{device.allowedUsers.length - 3}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        onClick={() => toggleRow(device.id)}
                        className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200"
                      >
                        {expandedRows.has(device.id) ? (
                          <ChevronUp className="h-4 w-4" />
                        ) : (
                          <ChevronDown className="h-4 w-4" />
                        )}
                      </button>
                    </td>
                  </motion.tr>
                  
                  {expandedRows.has(device.id) && (
                    <motion.tr
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.3 }}
                      className="bg-gray-50 dark:bg-gray-800"
                    >
                      <td colSpan="5" className="px-6 py-4">
                        <div className="space-y-4">
                          <h4 className="text-sm font-medium text-gray-900 dark:text-white">
                            Authorized Users ({device.allowedUsers.length})
                          </h4>
                          
                          {device.allowedUsers.length > 0 ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                              {device.allowedUsers.map((user) => (
                                <motion.div
                                  key={user.id}
                                  initial={{ opacity: 0, scale: 0.9 }}
                                  animate={{ opacity: 1, scale: 1 }}
                                  transition={{ duration: 0.2 }}
                                  className="flex items-center p-3 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-600 transition-colors duration-200"
                                >
                                  <div className="flex-shrink-0 h-8 w-8">
                                    {user.photoUrl ? (
                                      <img
                                        className="h-8 w-8 rounded-full object-cover ring-2 ring-gray-300 dark:ring-gray-600"
                                        src={user.photoUrl}
                                        alt={user.name}
                                      />
                                    ) : (
                                      <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                                        <span className="text-white font-medium text-xs">
                                          {user.name?.charAt(0)?.toUpperCase() || 'U'}
                                        </span>
                                      </div>
                                    )}
                                  </div>
                                  <div className="ml-3 flex-1">
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                                      {user.name || 'Unknown User'}
                                    </p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                      {user.email || 'No email'}
                                    </p>
                                  </div>
                                  <div className="flex items-center">
                                    {getRoleIcon(user.role)}
                                    <span className={`ml-1 inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getRoleBadgeColor(user.role)}`}>
                                      {user.role || 'user'}
                                    </span>
                                  </div>
                                </motion.div>
                              ))}
                            </div>
                          ) : (
                            <div className="text-center py-6">
                              <User className="mx-auto h-12 w-12 text-gray-400" />
                              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                                No authorized users - Device is public
                              </p>
                            </div>
                          )}
                        </div>
                      </td>
                    </motion.tr>
                  )}
                </React.Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
