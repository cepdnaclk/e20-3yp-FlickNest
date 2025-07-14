import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  User, 
  Clock, 
  Activity, 
  TrendingUp, 
  Eye,
  Zap,
  Calendar,
  BarChart3
} from 'lucide-react';
import { DeviceActivityStorage } from '../utils/deviceActivityStorage';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { useTheme } from 'next-themes';

export default function DeviceUsageDetails({ environmentId, devices }) {
  const { theme } = useTheme();
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [usageStats, setUsageStats] = useState({});

  useEffect(() => {
    // Load user activity stats
    const stats = DeviceActivityStorage.getUserActivityStats(environmentId);
    setUsageStats(stats);
  }, [environmentId]);

  const colors = {
    primary: theme === 'dark' ? '#3b82f6' : '#2563eb',
    secondary: theme === 'dark' ? '#10b981' : '#059669',
    danger: theme === 'dark' ? '#ef4444' : '#dc2626',
    text: theme === 'dark' ? '#e5e7eb' : '#374151',
    grid: theme === 'dark' ? '#374151' : '#e5e7eb'
  };

  const getDeviceUsageStats = (deviceId) => {
    return DeviceActivityStorage.getDeviceUsageStats(deviceId, environmentId);
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const handleDeviceClick = (deviceId) => {
    setSelectedDevice(deviceId === selectedDevice ? null : deviceId);
  };

  const deviceUsageData = selectedDevice ? getDeviceUsageStats(selectedDevice) : null;

  return (
    <div className="space-y-6">
      {/* User Activity Overview */}
      <div className="monitor-card p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
          <User className="h-5 w-5 mr-2 text-blue-600" />
          User Activity Overview
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Object.entries(usageStats).map(([userId, stats]) => (
            <motion.div
              key={userId}
              whileHover={{ scale: 1.02 }}
              className="p-4 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center space-x-2">
                  <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                    <User className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                  </div>
                  <div>
                    <p className="font-medium text-gray-900 dark:text-white">{stats.userName}</p>
                    <p className="text-xs text-gray-500">User ID: {stats.userId}</p>
                  </div>
                </div>
              </div>
              
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Devices Accessed:</span>
                  <span className="font-medium text-gray-900 dark:text-white">
                    {Object.keys(stats.devices).length}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Total Activations:</span>
                  <span className="font-medium text-green-600">{stats.totalActivations}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Total Deactivations:</span>
                  <span className="font-medium text-red-600">{stats.totalDeactivations}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Last Activity:</span>
                  <span className="font-medium text-gray-900 dark:text-white">
                    {formatTimestamp(stats.lastActivity)}
                  </span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
        
        {Object.keys(usageStats).length === 0 && (
          <div className="text-center py-8">
            <Activity className="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <p className="text-gray-500">No user activity recorded yet</p>
            <p className="text-sm text-gray-400">Interact with devices to see usage statistics</p>
          </div>
        )}
      </div>

      {/* Device Access Details */}
      <div className="monitor-card p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
          <Eye className="h-5 w-5 mr-2 text-blue-600" />
          Device Access Details
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          {Object.entries(devices).map(([deviceId, device]) => (
            <motion.div
              key={deviceId}
              whileHover={{ scale: 1.02 }}
              onClick={() => handleDeviceClick(deviceId)}
              className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 ${
                selectedDevice === deviceId
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 hover:border-gray-300 dark:hover:border-gray-500'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium text-gray-900 dark:text-white">{device.name}</h4>
                <div className={`w-2 h-2 rounded-full ${device.state ? 'bg-green-500' : 'bg-red-500'}`} />
              </div>
              
              <div className="text-sm text-gray-500 space-y-1">
                <div className="flex justify-between">
                  <span>Total Access:</span>
                  <span className="font-medium">
                    {DeviceActivityStorage.getDeviceActivities(deviceId, environmentId).length}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>Status:</span>
                  <span className={`font-medium ${device.state ? 'text-green-600' : 'text-red-600'}`}>
                    {device.state ? 'Active' : 'Inactive'}
                  </span>
                </div>
              </div>
              
              {selectedDevice === deviceId && (
                <div className="mt-2 pt-2 border-t border-gray-200 dark:border-gray-600">
                  <p className="text-xs text-blue-600 dark:text-blue-400">Click to view detailed usage</p>
                </div>
              )}
            </motion.div>
          ))}
        </div>

        {/* Detailed Device Usage */}
        {selectedDevice && deviceUsageData && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-6"
          >
            {/* Device Usage Summary */}
            <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <BarChart3 className="h-5 w-5 mr-2 text-blue-600" />
                {devices[selectedDevice].name} - Usage Statistics
              </h4>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                <div className="text-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <Zap className="h-6 w-6 text-green-500 mx-auto mb-2" />
                  <div className="text-lg font-bold text-gray-900 dark:text-white">
                    {deviceUsageData.totalActivations}
                  </div>
                  <div className="text-sm text-gray-500">Activations</div>
                </div>
                
                <div className="text-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <Zap className="h-6 w-6 text-red-500 mx-auto mb-2" />
                  <div className="text-lg font-bold text-gray-900 dark:text-white">
                    {deviceUsageData.totalDeactivations}
                  </div>
                  <div className="text-sm text-gray-500">Deactivations</div>
                </div>
                
                <div className="text-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <Activity className="h-6 w-6 text-blue-500 mx-auto mb-2" />
                  <div className="text-lg font-bold text-gray-900 dark:text-white">
                    {deviceUsageData.totalAccesses}
                  </div>
                  <div className="text-sm text-gray-500">Total Access</div>
                </div>
                
                <div className="text-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <User className="h-6 w-6 text-purple-500 mx-auto mb-2" />
                  <div className="text-lg font-bold text-gray-900 dark:text-white">
                    {Object.keys(deviceUsageData.userAccess).length}
                  </div>
                  <div className="text-sm text-gray-500">Users</div>
                </div>
              </div>

              {/* User Access Breakdown */}
              <div className="space-y-3">
                <h5 className="font-medium text-gray-900 dark:text-white">User Access Breakdown</h5>
                {Object.entries(deviceUsageData.userAccess).map(([userId, access]) => (
                  <div key={userId} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                        <User className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                      </div>
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">{access.userName}</p>
                        <p className="text-sm text-gray-500">
                          Last access: {formatTimestamp(access.lastAccess)}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm space-x-4">
                        <span className="text-green-600">↑{access.activations}</span>
                        <span className="text-red-600">↓{access.deactivations}</span>
                      </div>
                      <div className="text-xs text-gray-500">
                        {access.activations + access.deactivations} total
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Recent Activity */}
              <div className="mt-6">
                <h5 className="font-medium text-gray-900 dark:text-white mb-3">Recent Activity</h5>
                <div className="space-y-2 max-h-60 overflow-y-auto">
                  {deviceUsageData.recentActivity.slice(0, 10).map((activity, index) => (
                    <div key={index} className="flex items-center justify-between p-2 text-sm border-l-2 border-gray-200 dark:border-gray-600 pl-4">
                      <div className="flex items-center space-x-2">
                        <div className={`w-2 h-2 rounded-full ${activity.state ? 'bg-green-500' : 'bg-red-500'}`} />
                        <span className="text-gray-900 dark:text-white">{activity.userName}</span>
                        <span className="text-gray-500">
                          {activity.state ? 'activated' : 'deactivated'} device
                        </span>
                      </div>
                      <span className="text-gray-400 text-xs">
                        {formatTimestamp(activity.timestamp)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
}
