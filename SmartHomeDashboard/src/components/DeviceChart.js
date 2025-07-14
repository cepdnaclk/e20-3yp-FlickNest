import React, { useState } from 'react';
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
  Cell,
  LineChart,
  Line,
  Legend,
  RadialBarChart,
  RadialBar,
  AreaChart,
  Area,
  ComposedChart
} from 'recharts';
import { useTheme } from 'next-themes';
import { motion } from 'framer-motion';
import { useDeviceActivity } from '../hooks/useDeviceActivity';
import { Clock, TrendingUp, Activity } from 'lucide-react';

export default function DeviceChart({ devices, rooms, type = 'bar', environmentId }) {
  const { theme } = useTheme();
  const [timeRange, setTimeRange] = useState('24h');
  const { activityData, loading: activityLoading } = useDeviceActivity(environmentId, timeRange);
  const [selectedDevice, setSelectedDevice] = useState(null);

  // Prepare data for different chart types
  const prepareBarData = () => {
    return Object.entries(rooms).map(([roomId, room]) => {
      const roomDevices = Object.entries(devices).filter(([_, device]) => device.room === roomId);
      const activeDevices = roomDevices.filter(([_, device]) => device.state).length;
      const inactiveDevices = roomDevices.length - activeDevices;
      
      return {
        name: room.name,
        active: activeDevices,
        inactive: inactiveDevices,
        total: roomDevices.length
      };
    });
  };

  const preparePieData = () => {
    const totalDevices = Object.keys(devices).length;
    const activeDevices = Object.values(devices).filter(device => device.state).length;
    const inactiveDevices = totalDevices - activeDevices;

    return [
      { 
        name: 'Active Devices', 
        value: activeDevices, 
        color: theme === 'dark' ? '#10b981' : '#059669',
        percentage: totalDevices > 0 ? ((activeDevices / totalDevices) * 100).toFixed(1) : 0
      },
      { 
        name: 'Inactive Devices', 
        value: inactiveDevices, 
        color: theme === 'dark' ? '#ef4444' : '#dc2626',
        percentage: totalDevices > 0 ? ((inactiveDevices / totalDevices) * 100).toFixed(1) : 0
      }
    ];
  };

  const prepareDeviceTypeData = () => {
    const deviceTypes = {};
    Object.values(devices).forEach(device => {
      const type = device.name.includes('Light') ? 'Lights' : 
                  device.name.includes('Lock') ? 'Security' :
                  device.name.includes('Sensor') ? 'Sensors' :
                  device.name.includes('Heater') || device.name.includes('Air Conditioner') ? 'Climate' :
                  'Others';
      
      if (!deviceTypes[type]) {
        deviceTypes[type] = { total: 0, active: 0 };
      }
      deviceTypes[type].total++;
      if (device.state) deviceTypes[type].active++;
    });

    return Object.entries(deviceTypes).map(([type, data]) => ({
      name: type,
      total: data.total,
      active: data.active,
      inactive: data.total - data.active
    }));
  };

  const prepareRadialData = () => {
    const totalDevices = Object.keys(devices).length;
    const activeDevices = Object.values(devices).filter(device => device.state).length;
    const percentage = totalDevices > 0 ? (activeDevices / totalDevices) * 100 : 0;

    return [
      {
        name: 'Active',
        value: percentage,
        fill: theme === 'dark' ? '#10b981' : '#059669'
      }
    ];
  };

  const barData = prepareBarData();
  const pieData = preparePieData();
  const deviceTypeData = prepareDeviceTypeData();
  const radialData = prepareRadialData();

  const colors = {
    primary: theme === 'dark' ? '#3b82f6' : '#2563eb',
    secondary: theme === 'dark' ? '#10b981' : '#059669',
    danger: theme === 'dark' ? '#ef4444' : '#dc2626',
    text: theme === 'dark' ? '#e5e7eb' : '#374151',
    grid: theme === 'dark' ? '#374151' : '#e5e7eb'
  };

  if (type === 'pie') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="chart-container"
      >
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-2 sm:mb-0">
            Device Status Overview
          </h3>
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 rounded-full bg-green-500"></div>
              <span className="text-sm text-gray-600 dark:text-gray-300">Active</span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 rounded-full bg-red-500"></div>
              <span className="text-sm text-gray-600 dark:text-gray-300">Inactive</span>
            </div>
          </div>
        </div>
        
        <div className="flex flex-col lg:flex-row lg:items-center gap-6">
          {/* Chart Section */}
          <div className="w-full lg:w-2/3">
            <div className="h-64 sm:h-80 lg:h-96">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={"25%"}
                    outerRadius={"75%"}
                    paddingAngle={2}
                    dataKey="value"
                    label={({ percentage }) => `${percentage}%`}
                    labelLine={false}
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{
                      backgroundColor: theme === 'dark' ? '#1f2937' : '#ffffff',
                      border: `1px solid ${colors.grid}`,
                      borderRadius: '12px',
                      color: colors.text,
                      boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
                    }}
                    formatter={(value, name) => [`${value} devices`, name]}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
          
          {/* Legend/Stats Section */}
          <div className="w-full lg:w-1/3">
            <div className="space-y-3">
              {pieData.map((item, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <div 
                      className="w-4 h-4 rounded-full flex-shrink-0" 
                      style={{ backgroundColor: item.color }}
                    ></div>
                    <span className="font-medium text-gray-700 dark:text-gray-300 text-sm">{item.name}</span>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-gray-900 dark:text-white">{item.value}</div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">{item.percentage}%</div>
                  </div>
                </div>
              ))}
            </div>
            
            {/* Summary Stats */}
            <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
              <div className="text-center">
                <div className="text-2xl font-bold text-gray-900 dark:text-white">
                  {pieData.reduce((sum, item) => sum + item.value, 0)}
                </div>
                <div className="text-sm text-gray-500 dark:text-gray-400">Total Devices</div>
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    );
  }

  if (type === 'radial') {
    const totalDevices = Object.keys(devices).length;
    const activeDevices = Object.values(devices).filter(device => device.state).length;
    const percentage = totalDevices > 0 ? (activeDevices / totalDevices) * 100 : 0;
    
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="chart-container"
      >
        <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-white">
          System Activity Level
        </h3>
        <ResponsiveContainer width="100%" height="100%">
          <RadialBarChart cx="50%" cy="50%" innerRadius="20%" outerRadius="80%" data={radialData}>
            <RadialBar
              dataKey="value"
              cornerRadius={10}
              fill={theme === 'dark' ? '#10b981' : '#059669'}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: theme === 'dark' ? '#1f2937' : '#ffffff',
                border: `1px solid ${colors.grid}`,
                borderRadius: '8px',
                color: colors.text
              }}
              formatter={(value) => [`${value.toFixed(1)}%`, 'Active Devices']}
            />
          </RadialBarChart>
        </ResponsiveContainer>
        <div className="text-center mt-4">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">{percentage.toFixed(1)}%</div>
          <div className="text-sm text-gray-500 dark:text-gray-400">Devices Active</div>
        </div>
      </motion.div>
    );
  }

  if (type === 'deviceTypes') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="chart-container"
      >
        <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-white">
          Device Categories
        </h3>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={deviceTypeData}>
            <CartesianGrid strokeDasharray="3 3" stroke={colors.grid} />
            <XAxis 
              dataKey="name" 
              stroke={colors.text}
              fontSize={12}
            />
            <YAxis 
              stroke={colors.text}
              fontSize={12}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: theme === 'dark' ? '#1f2937' : '#ffffff',
                border: `1px solid ${colors.grid}`,
                borderRadius: '8px',
                color: colors.text
              }}
            />
            <Legend />
            <Bar 
              dataKey="active" 
              fill={colors.secondary}
              name="Active"
              radius={[2, 2, 0, 0]}
            />
            <Bar 
              dataKey="inactive" 
              fill={colors.danger}
              name="Inactive"
              radius={[2, 2, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </motion.div>
    );
  }

  if (type === 'line') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="chart-container"
      >
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-6">
          <div className="flex items-center space-x-2 mb-4 sm:mb-0">
            <TrendingUp className="h-5 w-5 text-blue-600 dark:text-blue-400" />
            <h3 className="text-lg font-semibold text-gray-800 dark:text-white">
              Device Activity Over Time
            </h3>
          </div>
          
          {/* Time Range Selector */}
          <div className="flex items-center space-x-2">
            <Clock className="h-4 w-4 text-gray-500" />
            <select 
              value={timeRange} 
              onChange={(e) => setTimeRange(e.target.value)}
              className="bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="1h">Last Hour</option>
              <option value="6h">Last 6 Hours</option>
              <option value="24h">Last 24 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
            </select>
          </div>
        </div>
        
        {/* Loading State */}
        {activityLoading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
            <span className="ml-2 text-gray-500">Loading activity data...</span>
          </div>
        ) : (
          <div className="h-64 sm:h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={activityData}>
                <defs>
                  <linearGradient id="activeGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={colors.secondary} stopOpacity={0.8}/>
                    <stop offset="95%" stopColor={colors.secondary} stopOpacity={0.1}/>
                  </linearGradient>
                  <linearGradient id="inactiveGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={colors.danger} stopOpacity={0.8}/>
                    <stop offset="95%" stopColor={colors.danger} stopOpacity={0.1}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={colors.grid} />
                <XAxis 
                  dataKey="time" 
                  stroke={colors.text}
                  fontSize={12}
                  tick={{ fill: colors.text }}
                />
                <YAxis 
                  stroke={colors.text}
                  fontSize={12}
                  tick={{ fill: colors.text }}
                />
                <Tooltip 
                  contentStyle={{
                    backgroundColor: theme === 'dark' ? '#1f2937' : '#ffffff',
                    border: `1px solid ${colors.grid}`,
                    borderRadius: '8px',
                    color: colors.text,
                    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
                  }}
                  formatter={(value, name) => {
                    const label = name === 'active' ? 'Active Devices' : 
                                 name === 'inactive' ? 'Inactive Devices' : 'Total Activity';
                    return [`${value}`, label];
                  }}
                  labelFormatter={(label) => `Time: ${label}`}
                />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="active"
                  stackId="1"
                  stroke={colors.secondary}
                  fill="url(#activeGradient)"
                  name="Active Devices"
                  strokeWidth={2}
                />
                <Area
                  type="monotone"
                  dataKey="inactive"
                  stackId="1"
                  stroke={colors.danger}
                  fill="url(#inactiveGradient)"
                  name="Inactive Devices"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}
        
        {/* Activity Summary */}
        <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="text-center p-2 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div className="flex items-center justify-center space-x-2">
                <Activity className="h-4 w-4 text-green-500" />
                <span className="text-sm text-gray-500 dark:text-gray-400">Peak Activity</span>
              </div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">
                {activityData.length > 0 ? Math.max(...activityData.map(d => d.active)) : 0}
              </div>
            </div>
            
            <div className="text-center p-2 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div className="flex items-center justify-center space-x-2">
                <TrendingUp className="h-4 w-4 text-blue-500" />
                <span className="text-sm text-gray-500 dark:text-gray-400">Average Active</span>
              </div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">
                {activityData.length > 0 ? 
                  Math.round(activityData.reduce((sum, d) => sum + d.active, 0) / activityData.length) : 0}
              </div>
            </div>
            
            <div className="text-center p-2 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div className="flex items-center justify-center space-x-2">
                <Clock className="h-4 w-4 text-purple-500" />
                <span className="text-sm text-gray-500 dark:text-gray-400">Data Points</span>
              </div>
              <div className="text-lg font-bold text-gray-900 dark:text-white">
                {activityData.length}
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    );
  }

  // Default bar chart
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="chart-container"
    >
      <h3 className="text-lg font-semibold mb-4 text-gray-800 dark:text-white">
        Device Status by Room
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={barData}>
          <CartesianGrid strokeDasharray="3 3" stroke={colors.grid} />
          <XAxis 
            dataKey="name" 
            stroke={colors.text}
            fontSize={12}
          />
          <YAxis 
            stroke={colors.text}
            fontSize={12}
          />
          <Tooltip 
            contentStyle={{
              backgroundColor: theme === 'dark' ? '#1f2937' : '#ffffff',
              border: `1px solid ${colors.grid}`,
              borderRadius: '8px',
              color: colors.text
            }}
          />
          <Legend />
          <Bar 
            dataKey="active" 
            fill={colors.secondary}
            name="Active Devices"
            radius={[4, 4, 0, 0]}
          />
          <Bar 
            dataKey="inactive" 
            fill={colors.danger}
            name="Inactive Devices"
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </motion.div>
  );
}
