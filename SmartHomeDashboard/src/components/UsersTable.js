import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  User, 
  Crown, 
  Shield, 
  ChevronDown, 
  ChevronUp, 
  Mail, 
  Calendar,
  Smartphone,
  Lightbulb,
  Lock,
  Thermometer,
  Power,
  Bell,
  DoorOpen,
  Fan,
  Refrigerator,
  Laptop,
  Wifi
} from 'lucide-react';

const getRoleIcon = (role) => {
  switch (role) {
    case 'admin':
      return <Crown className="h-4 w-4 text-yellow-500" />;
    case 'co-admin':
      return <Shield className="h-4 w-4 text-blue-500" />;
    case 'user':
      return <User className="h-4 w-4 text-green-500" />;
    default:
      return <User className="h-4 w-4 text-gray-500" />;
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
  'default': Smartphone
};

export default function UsersTable({ users, devices, globalUsers }) {
  const [expandedRows, setExpandedRows] = useState(new Set());

  const toggleRow = (userId) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(userId)) {
      newExpanded.delete(userId);
    } else {
      newExpanded.add(userId);
    }
    setExpandedRows(newExpanded);
  };

  // Prepare data for user access per device
  const userAccessData = Object.entries(users).map(([userId, user]) => {
    // Merge environment user data with global user data
    const globalUser = globalUsers?.[userId] || {};
    const mergedUser = {
      ...globalUser,
      ...user,
      id: userId
    };
    
    // Determine accessible devices for the user
    const accessibleDevices = Object.entries(devices)
      .filter(([deviceId, device]) => device.allowedUsers?.[userId])
      .map(([deviceId, device]) => ({ id: deviceId, ...device }));

    return {
      ...mergedUser,
      accessibleDevices
    };
  });

  return (
    <div className="glass-card rounded-xl overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          Users & Device Access
        </h3>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Manage user roles and device permissions
        </p>
      </div>
      
      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead className="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                User
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Device Access
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            {userAccessData.map((user) => (
              <React.Fragment key={user.id}>
                <motion.tr
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3 }}
                  className="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors duration-200"
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10">
                        {user.photoUrl ? (
                          <img
                            className="h-10 w-10 rounded-full object-cover ring-2 ring-gray-300 dark:ring-gray-600"
                            src={user.photoUrl}
                            alt={user.name}
                          />
                        ) : (
                          <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                            <span className="text-white font-medium text-sm">
                              {user.name?.charAt(0)?.toUpperCase() || 'U'}
                            </span>
                          </div>
                        )}
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900 dark:text-white">
                          {user.name || 'Unknown User'}
                        </div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">
                          {user.addedAt ? new Date(user.addedAt).toLocaleDateString() : 'N/A'}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      {getRoleIcon(user.role)}
                      <span className={`ml-2 inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getRoleBadgeColor(user.role)}`}>
                        {user.role || 'user'}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center text-sm text-gray-900 dark:text-white">
                      <Mail className="h-4 w-4 mr-2 text-gray-400" />
                      {user.email || 'No email'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <span className="text-sm font-medium text-gray-900 dark:text-white">
                        {user.accessibleDevices.length} device(s)
                      </span>
                      {user.accessibleDevices.length > 0 && (
                        <div className="ml-2 flex -space-x-1">
                          {user.accessibleDevices.slice(0, 3).map((device, index) => {
                            const DeviceIcon = deviceIcons[device.name] || deviceIcons.default;
                            return (
                              <div
                                key={index}
                                className="h-6 w-6 rounded-full bg-blue-500 flex items-center justify-center border-2 border-white dark:border-gray-900"
                                title={device.name}
                              >
                                <DeviceIcon className="h-3 w-3 text-white" />
                              </div>
                            );
                          })}
                          {user.accessibleDevices.length > 3 && (
                            <div className="h-6 w-6 rounded-full bg-gray-500 flex items-center justify-center border-2 border-white dark:border-gray-900 text-xs text-white">
                              +{user.accessibleDevices.length - 3}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button
                      onClick={() => toggleRow(user.id)}
                      className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200"
                    >
                      {expandedRows.has(user.id) ? (
                        <ChevronUp className="h-4 w-4" />
                      ) : (
                        <ChevronDown className="h-4 w-4" />
                      )}
                    </button>
                  </td>
                </motion.tr>
                
                {expandedRows.has(user.id) && (
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
                          Accessible Devices ({user.accessibleDevices.length})
                        </h4>
                        
                        {user.accessibleDevices.length > 0 ? (
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                            {user.accessibleDevices.map((device) => {
                              const DeviceIcon = deviceIcons[device.name] || deviceIcons.default;
                              return (
                                <motion.div
                                  key={device.id}
                                  initial={{ opacity: 0, scale: 0.9 }}
                                  animate={{ opacity: 1, scale: 1 }}
                                  transition={{ duration: 0.2 }}
                                  className="flex items-center p-3 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-600 transition-colors duration-200"
                                >
                                  <div className={`p-2 rounded-lg ${
                                    device.state 
                                      ? 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400' 
                                      : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                                  }`}>
                                    <DeviceIcon className="h-4 w-4" />
                                  </div>
                                  <div className="ml-3 flex-1">
                                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                                      {device.name}
                                    </p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                      {device.state ? 'Active' : 'Inactive'}
                                    </p>
                                  </div>
                                  <div className={`px-2 py-1 rounded-full text-xs ${
                                    device.state 
                                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                                      : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                  }`}>
                                    {device.state ? 'ON' : 'OFF'}
                                  </div>
                                </motion.div>
                              );
                            })}
                          </div>
                        ) : (
                          <div className="text-center py-6">
                            <Smartphone className="mx-auto h-12 w-12 text-gray-400" />
                            <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                              No accessible devices
                            </p>
                          </div>
                        )}
                      </div>
                    </td>
                  </motion.tr>
                )}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
