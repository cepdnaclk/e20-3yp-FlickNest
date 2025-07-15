import React, { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Activity, 
  AlertTriangle,
  Battery,
  BatteryLow,
  CheckCircle,
  ChevronDown,
  ChevronUp,
  Clock,
  Database,
  Device,
  Eye,
  Filter,
  Globe,
  Heart,
  Home,
  Lightbulb,
  Lock,
  Monitor,
  Network,
  Power,
  RefreshCw,
  Search,
  Server,
  Settings,
  Shield,
  Signal,
  Thermometer,
  TrendingDown,
  TrendingUp,
  User,
  Users,
  Wifi,
  WifiOff,
  Zap,
  ZapOff
} from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip, Legend, RadialBarChart, RadialBar } from 'recharts';

// Custom hook for real-time monitoring
function useRealTimeMonitoring(environmentId) {
  const [metrics, setMetrics] = useState({
    uptime: 0,
    responseTime: 0,
    errorRate: 0,
    networkLatency: 0,
    cpuUsage: 0,
    memoryUsage: 0,
    diskUsage: 0,
    activeConnections: 0,
    alerts: []
  });

  const [isOnline, setIsOnline] = useState(true);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  useEffect(() => {
    const interval = setInterval(() => {
      // Simulate real-time metrics
      setMetrics(prev => ({
        ...prev,
        uptime: prev.uptime + 1,
        responseTime: Math.random() * 100 + 50,
        errorRate: Math.random() * 5,
        networkLatency: Math.random() * 50 + 10,
        cpuUsage: Math.random() * 80 + 10,
        memoryUsage: Math.random() * 70 + 20,
        diskUsage: Math.random() * 60 + 30,
        activeConnections: Math.floor(Math.random() * 50) + 10,
        alerts: prev.alerts.slice(-10) // Keep last 10 alerts
      }));
      setLastUpdate(new Date());
    }, 2000);

    return () => clearInterval(interval);
  }, [environmentId]);

  return { metrics, isOnline, lastUpdate };
}

// Performance Metrics Component
const PerformanceMetrics = ({ metrics }) => {
  const performanceData = [
    { name: 'CPU', value: metrics.cpuUsage, color: '#8884d8', unit: '%' },
    { name: 'Memory', value: metrics.memoryUsage, color: '#82ca9d', unit: '%' },
    { name: 'Disk', value: metrics.diskUsage, color: '#ffc658', unit: '%' },
    { name: 'Network', value: metrics.networkLatency, color: '#ff7300', unit: 'ms' }
  ];

  return (
    <div className="glass-card rounded-xl p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
        <Activity className="h-5 w-5 mr-2 text-blue-600" />
        System Performance
      </h3>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {performanceData.map((metric, index) => (
          <motion.div
            key={metric.name}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.1 }}
            className="text-center"
          >
            <div className="relative w-20 h-20 mx-auto mb-2">
              <svg className="w-20 h-20 transform -rotate-90" viewBox="0 0 36 36">
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  className="text-gray-200 dark:text-gray-700"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke={metric.color}
                  strokeWidth="2"
                  strokeDasharray={`${metric.value}, 100`}
                  strokeLinecap="round"
                  className="transition-all duration-500"
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="text-sm font-bold text-gray-900 dark:text-white">
                  {metric.value.toFixed(0)}{metric.unit}
                </span>
              </div>
            </div>
            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">{metric.name}</p>
          </motion.div>
        ))}
      </div>
    </div>
  );
};

// Real-time Activity Feed
const ActivityFeed = ({ devices, isOnline }) => {
  const [activities, setActivities] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const interval = setInterval(() => {
      const deviceIds = Object.keys(devices);
      if (deviceIds.length > 0) {
        const randomDevice = devices[deviceIds[Math.floor(Math.random() * deviceIds.length)]];
        const activities_types = ['state_change', 'user_action', 'automation', 'maintenance'];
        const activity = {
          id: Date.now(),
          type: activities_types[Math.floor(Math.random() * activities_types.length)],
          device: randomDevice.name,
          timestamp: new Date(),
          message: `${randomDevice.name} ${Math.random() > 0.5 ? 'activated' : 'deactivated'}`,
          severity: Math.random() > 0.8 ? 'high' : Math.random() > 0.5 ? 'medium' : 'low'
        };
        setActivities(prev => [activity, ...prev.slice(0, 19)]);
      }
    }, 3000);

    return () => clearInterval(interval);
  }, [devices]);

  const filteredActivities = activities.filter(activity => 
    filter === 'all' || activity.type === filter
  );

  const getActivityIcon = (type) => {
    switch (type) {
      case 'state_change': return <Power className="h-4 w-4" />;
      case 'user_action': return <User className="h-4 w-4" />;
      case 'automation': return <Zap className="h-4 w-4" />;
      case 'maintenance': return <Settings className="h-4 w-4" />;
      default: return <Activity className="h-4 w-4" />;
    }
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return 'text-red-500 bg-red-100 dark:bg-red-900';
      case 'medium': return 'text-yellow-500 bg-yellow-100 dark:bg-yellow-900';
      default: return 'text-green-500 bg-green-100 dark:bg-green-900';
    }
  };

  return (
    <div className="glass-card rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <Activity className="h-5 w-5 mr-2 text-blue-600" />
          Live Activity Feed
          <div className={`ml-2 h-2 w-2 rounded-full ${isOnline ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
        </h3>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
        >
          <option value="all">All Activities</option>
          <option value="state_change">State Changes</option>
          <option value="user_action">User Actions</option>
          <option value="automation">Automations</option>
          <option value="maintenance">Maintenance</option>
        </select>
      </div>

      <div className="space-y-3 max-h-96 overflow-y-auto">
        <AnimatePresence>
          {filteredActivities.map((activity) => (
            <motion.div
              key={activity.id}
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              className="flex items-center p-3 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <div className={`p-2 rounded-lg ${getSeverityColor(activity.severity)} mr-3`}>
                {getActivityIcon(activity.type)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {activity.message}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {activity.timestamp.toLocaleTimeString()}
                </p>
              </div>
              <span className={`px-2 py-1 text-xs rounded-full ${getSeverityColor(activity.severity)}`}>
                {activity.severity}
              </span>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
};

// Network Topology Visualization
const NetworkTopology = ({ devices, rooms }) => {
  const [selectedDevice, setSelectedDevice] = useState(null);
  
  const networkData = useMemo(() => {
    const nodes = [];
    const links = [];
    
    // Add hub/router as central node
    nodes.push({ 
      id: 'hub', 
      name: 'Smart Hub', 
      type: 'hub', 
      x: 300, 
      y: 200, 
      status: 'online',
      connections: Object.keys(devices).length
    });
    
    // Add device nodes
    Object.entries(devices).forEach(([deviceId, device], index) => {
      const angle = (index * 2 * Math.PI) / Object.keys(devices).length;
      const radius = 150;
      nodes.push({
        id: deviceId,
        name: device.name,
        type: 'device',
        x: 300 + Math.cos(angle) * radius,
        y: 200 + Math.sin(angle) * radius,
        status: device.state ? 'online' : 'offline',
        room: rooms[device.roomId]?.name || 'Unknown'
      });
      
      links.push({
        source: 'hub',
        target: deviceId,
        strength: Math.random() * 100,
        latency: Math.random() * 50 + 10
      });
    });
    
    return { nodes, links };
  }, [devices, rooms]);

  const getNodeColor = (node) => {
    if (node.type === 'hub') return '#3b82f6';
    return node.status === 'online' ? '#10b981' : '#ef4444';
  };

  return (
    <div className="glass-card rounded-xl p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
        <Network className="h-5 w-5 mr-2 text-blue-600" />
        Network Topology
      </h3>
      
      <div className="relative bg-gray-50 dark:bg-gray-800 rounded-lg p-4" style={{ height: '400px' }}>
        <svg width="100%" height="100%" viewBox="0 0 600 400">
          {/* Links */}
          {networkData.links.map((link, index) => {
            const sourceNode = networkData.nodes.find(n => n.id === link.source);
            const targetNode = networkData.nodes.find(n => n.id === link.target);
            return (
              <line
                key={index}
                x1={sourceNode.x}
                y1={sourceNode.y}
                x2={targetNode.x}
                y2={targetNode.y}
                stroke="#6b7280"
                strokeWidth={Math.max(1, link.strength / 50)}
                strokeDasharray={targetNode.status === 'offline' ? '5,5' : 'none'}
                className="transition-all duration-300"
              />
            );
          })}
          
          {/* Nodes */}
          {networkData.nodes.map((node) => (
            <g key={node.id}>
              <circle
                cx={node.x}
                cy={node.y}
                r={node.type === 'hub' ? 20 : 12}
                fill={getNodeColor(node)}
                stroke="#ffffff"
                strokeWidth="2"
                className="cursor-pointer transition-all duration-300 hover:r-16"
                onClick={() => setSelectedDevice(node)}
              />
              <text
                x={node.x}
                y={node.y + 25}
                textAnchor="middle"
                className="text-xs fill-gray-600 dark:fill-gray-300"
              >
                {node.name}
              </text>
            </g>
          ))}
        </svg>
        
        {/* Device Info Panel */}
        <AnimatePresence>
          {selectedDevice && (
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              className="absolute top-4 right-4 bg-white dark:bg-gray-900 rounded-lg p-4 shadow-lg border border-gray-200 dark:border-gray-700"
            >
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold text-gray-900 dark:text-white">
                  {selectedDevice.name}
                </h4>
                <button
                  onClick={() => setSelectedDevice(null)}
                  className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  ×
                </button>
              </div>
              <div className="space-y-1 text-sm">
                <div className="flex items-center">
                  <div className={`h-2 w-2 rounded-full mr-2 ${
                    selectedDevice.status === 'online' ? 'bg-green-500' : 'bg-red-500'
                  }`} />
                  <span className="text-gray-600 dark:text-gray-300">
                    {selectedDevice.status}
                  </span>
                </div>
                {selectedDevice.room && (
                  <p className="text-gray-600 dark:text-gray-300">
                    Room: {selectedDevice.room}
                  </p>
                )}
                {selectedDevice.connections && (
                  <p className="text-gray-600 dark:text-gray-300">
                    Connections: {selectedDevice.connections}
                  </p>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
};

// Alert Management System
const AlertSystem = ({ metrics }) => {
  const [alerts, setAlerts] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const newAlerts = [];
    
    if (metrics.cpuUsage > 80) {
      newAlerts.push({
        id: 'cpu-high',
        type: 'performance',
        severity: 'high',
        title: 'High CPU Usage',
        message: `CPU usage is at ${metrics.cpuUsage.toFixed(1)}%`,
        timestamp: new Date(),
        icon: AlertTriangle
      });
    }
    
    if (metrics.memoryUsage > 85) {
      newAlerts.push({
        id: 'memory-high',
        type: 'performance',
        severity: 'high',
        title: 'High Memory Usage',
        message: `Memory usage is at ${metrics.memoryUsage.toFixed(1)}%`,
        timestamp: new Date(),
        icon: AlertTriangle
      });
    }
    
    if (metrics.networkLatency > 100) {
      newAlerts.push({
        id: 'network-slow',
        type: 'network',
        severity: 'medium',
        title: 'Network Latency',
        message: `Network latency is ${metrics.networkLatency.toFixed(0)}ms`,
        timestamp: new Date(),
        icon: WifiOff
      });
    }
    
    setAlerts(newAlerts);
  }, [metrics]);

  const filteredAlerts = alerts.filter(alert => 
    filter === 'all' || alert.type === filter
  );

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return 'border-red-500 bg-red-50 dark:bg-red-900/20';
      case 'medium': return 'border-yellow-500 bg-yellow-50 dark:bg-yellow-900/20';
      default: return 'border-blue-500 bg-blue-50 dark:bg-blue-900/20';
    }
  };

  return (
    <div className="glass-card rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <AlertTriangle className="h-5 w-5 mr-2 text-red-600" />
          System Alerts
          {alerts.length > 0 && (
            <span className="ml-2 px-2 py-1 text-xs bg-red-500 text-white rounded-full">
              {alerts.length}
            </span>
          )}
        </h3>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
        >
          <option value="all">All Alerts</option>
          <option value="performance">Performance</option>
          <option value="network">Network</option>
          <option value="security">Security</option>
        </select>
      </div>

      <div className="space-y-3">
        {filteredAlerts.length === 0 ? (
          <div className="text-center py-8">
            <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-2" />
            <p className="text-gray-500 dark:text-gray-400">
              No alerts - System is running smoothly
            </p>
          </div>
        ) : (
          filteredAlerts.map((alert) => (
            <motion.div
              key={alert.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className={`p-4 rounded-lg border-l-4 ${getSeverityColor(alert.severity)}`}
            >
              <div className="flex items-start">
                <alert.icon className="h-5 w-5 text-gray-600 dark:text-gray-300 mr-3 mt-0.5" />
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <h4 className="font-semibold text-gray-900 dark:text-white">
                      {alert.title}
                    </h4>
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      alert.severity === 'high' ? 'bg-red-500 text-white' :
                      alert.severity === 'medium' ? 'bg-yellow-500 text-white' :
                      'bg-blue-500 text-white'
                    }`}>
                      {alert.severity}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">
                    {alert.message}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                    {alert.timestamp.toLocaleTimeString()}
                  </p>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
};

// Main Monitoring Dashboard Component
export default function MonitoringDashboard({ devices, users, rooms, environmentId }) {
  const { metrics, isOnline, lastUpdate } = useRealTimeMonitoring(environmentId);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [refreshInterval, setRefreshInterval] = useState(5000);
  const [expandedSections, setExpandedSections] = useState(new Set(['overview', 'performance', 'network']));

  const toggleSection = (section) => {
    const newExpanded = new Set(expandedSections);
    if (newExpanded.has(section)) {
      newExpanded.delete(section);
    } else {
      newExpanded.add(section);
    }
    setExpandedSections(newExpanded);
  };

  // Calculate system statistics
  const systemStats = useMemo(() => {
    const totalDevices = Object.keys(devices).length;
    const activeDevices = Object.values(devices).filter(d => d.state).length;
    const offlineDevices = totalDevices - activeDevices;
    const uptimePercentage = ((metrics.uptime / (metrics.uptime + 10)) * 100).toFixed(2);
    
    return {
      totalDevices,
      activeDevices,
      offlineDevices,
      uptimePercentage,
      systemHealth: metrics.errorRate < 1 ? 'Excellent' : metrics.errorRate < 5 ? 'Good' : 'Warning'
    };
  }, [devices, metrics]);

  return (
    <div className="space-y-6">
      {/* Header with Real-time Status */}
      <div className="glass-card rounded-xl p-6">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-blue-100 dark:bg-blue-900 rounded-lg">
              <Monitor className="h-8 w-8 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                System Monitor
              </h1>
              <div className="flex items-center space-x-4 mt-1">
                <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                  <div className={`h-2 w-2 rounded-full mr-2 ${isOnline ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
                  {isOnline ? 'Online' : 'Offline'}
                </div>
                <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                  <Clock className="h-3 w-3 mr-1" />
                  Updated: {lastUpdate.toLocaleTimeString()}
                </div>
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-4 mt-4 lg:mt-0">
            <div className="flex items-center space-x-2">
              <label className="text-sm text-gray-700 dark:text-gray-300">Auto-refresh</label>
              <button
                onClick={() => setAutoRefresh(!autoRefresh)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  autoRefresh ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-600'
                }`}
              >
                <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  autoRefresh ? 'translate-x-6' : 'translate-x-1'
                }`} />
              </button>
            </div>
            <button
              onClick={() => window.location.reload()}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <RefreshCw className="h-4 w-4 mr-2" />
              Refresh
            </button>
          </div>
        </div>
      </div>

      {/* System Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-card rounded-xl p-6 bg-gradient-to-br from-blue-500 to-blue-600 text-white"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm">Total Devices</p>
              <p className="text-3xl font-bold">{systemStats.totalDevices}</p>
              <p className="text-blue-200 text-xs">{systemStats.activeDevices} active</p>
            </div>
            <Device className="h-8 w-8 text-blue-200" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="glass-card rounded-xl p-6 bg-gradient-to-br from-green-500 to-green-600 text-white"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm">System Health</p>
              <p className="text-xl font-bold">{systemStats.systemHealth}</p>
              <p className="text-green-200 text-xs">{systemStats.uptimePercentage}% uptime</p>
            </div>
            <Heart className="h-8 w-8 text-green-200" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass-card rounded-xl p-6 bg-gradient-to-br from-yellow-500 to-yellow-600 text-white"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-yellow-100 text-sm">Response Time</p>
              <p className="text-3xl font-bold">{metrics.responseTime.toFixed(0)}ms</p>
              <p className="text-yellow-200 text-xs">Average latency</p>
            </div>
            <Zap className="h-8 w-8 text-yellow-200" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="glass-card rounded-xl p-6 bg-gradient-to-br from-purple-500 to-purple-600 text-white"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-purple-100 text-sm">Active Connections</p>
              <p className="text-3xl font-bold">{metrics.activeConnections}</p>
              <p className="text-purple-200 text-xs">Current sessions</p>
            </div>
            <Network className="h-8 w-8 text-purple-200" />
          </div>
        </motion.div>
      </div>

      {/* Performance Metrics */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <PerformanceMetrics metrics={metrics} />
        <AlertSystem metrics={metrics} />
      </div>

      {/* Network and Activity */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <NetworkTopology devices={devices} rooms={rooms} />
        <ActivityFeed devices={devices} isOnline={isOnline} />
      </div>

      {/* Detailed Analytics */}
      <div className="glass-card rounded-xl p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
          <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
          Performance Analytics
        </h3>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* CPU Usage Over Time */}
          <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">CPU Usage</h4>
            <div className="h-40">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={[
                  { time: '10:00', cpu: 65 },
                  { time: '10:05', cpu: 70 },
                  { time: '10:10', cpu: 68 },
                  { time: '10:15', cpu: metrics.cpuUsage },
                ]}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="cpu" stroke="#8884d8" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Memory Usage */}
          <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">Memory Usage</h4>
            <div className="h-40">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={[
                  { time: '10:00', memory: 45 },
                  { time: '10:05', memory: 50 },
                  { time: '10:10', memory: 48 },
                  { time: '10:15', memory: metrics.memoryUsage },
                ]}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Area type="monotone" dataKey="memory" stroke="#82ca9d" fill="#82ca9d" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      </div>

      {/* System Information */}
      <div className="glass-card rounded-xl p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
          <Database className="h-5 w-5 mr-2 text-blue-600" />
          System Information
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="space-y-3">
            <h4 className="font-medium text-gray-900 dark:text-white">Environment</h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Environment ID:</span>
                <span className="text-gray-900 dark:text-white font-mono">{environmentId}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Total Rooms:</span>
                <span className="text-gray-900 dark:text-white">{Object.keys(rooms).length}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Total Users:</span>
                <span className="text-gray-900 dark:text-white">{Object.keys(users).length}</span>
              </div>
            </div>
          </div>
          
          <div className="space-y-3">
            <h4 className="font-medium text-gray-900 dark:text-white">Performance</h4>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Uptime:</span>
                <span className="text-gray-900 dark:text-white">
                  {Math.floor(metrics.uptime / 60)}m {metrics.uptime % 60}s
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Error Rate:</span>
                <span className="text-gray-900 dark:text-white">{metrics.errorRate.toFixed(2)}%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Network Latency:</span>
                <span className="text-gray-900 dark:text-white">{metrics.networkLatency.toFixed(0)}ms</span>
              </div>
            </div>
          </div>
          
          <div className="space-y-3">
            <h4 className="font-medium text-gray-900 dark:text-white">Resources</h4>
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">Storage:</span>
                <div className="flex items-center">
                  <div className="w-20 bg-gray-200 dark:bg-gray-700 rounded-full h-2 mr-2">
                    <div 
                      className="bg-blue-600 h-2 rounded-full"
                      style={{ width: `${metrics.diskUsage}%` }}
                    />
                  </div>
                  <span className="text-gray-900 dark:text-white">{metrics.diskUsage.toFixed(0)}%</span>
                </div>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">Bandwidth:</span>
                <div className="flex items-center">
                  <div className="w-20 bg-gray-200 dark:bg-gray-700 rounded-full h-2 mr-2">
                    <div 
                      className="bg-green-600 h-2 rounded-full"
                      style={{ width: `${(metrics.networkLatency / 100) * 100}%` }}
                    />
                  </div>
                  <span className="text-gray-900 dark:text-white">
                    {(100 - metrics.networkLatency).toFixed(0)}%
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
