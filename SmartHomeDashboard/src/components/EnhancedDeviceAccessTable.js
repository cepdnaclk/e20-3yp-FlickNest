import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
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
  Laptop,
  Search,
  Filter,
  X,
  Eye,
  EyeOff,
  Settings,
  Calendar,
  Clock,
  AlertCircle,
  CheckCircle,
  Users,
  Activity
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
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300 border-yellow-200 dark:border-yellow-800';
    case 'co-admin':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300 border-blue-200 dark:border-blue-800';
    case 'user':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300 border-green-200 dark:border-green-800';
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300 border-gray-200 dark:border-gray-800';
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

const DeviceAccessStats = ({ devices }) => {
  const stats = useMemo(() => {
    const totalDevices = devices.length;
    const activeDevices = devices.filter(d => d.state).length;
    const restrictedDevices = devices.filter(d => d.allowedUsers.length > 0).length;
    const publicDevices = totalDevices - restrictedDevices;
    
    return {
      totalDevices,
      activeDevices,
      restrictedDevices,
      publicDevices
    };
  }, [devices]);

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-4 text-white"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-blue-100 text-sm">Total Devices</p>
            <p className="text-2xl font-bold">{stats.totalDevices}</p>
          </div>
          <Device className="h-8 w-8 text-blue-200" />
        </div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-gradient-to-br from-green-500 to-green-600 rounded-lg p-4 text-white"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-green-100 text-sm">Active</p>
            <p className="text-2xl font-bold">{stats.activeDevices}</p>
          </div>
          <CheckCircle className="h-8 w-8 text-green-200" />
        </div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg p-4 text-white"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-orange-100 text-sm">Restricted</p>
            <p className="text-2xl font-bold">{stats.restrictedDevices}</p>
          </div>
          <Lock className="h-8 w-8 text-orange-200" />
        </div>
      </motion.div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg p-4 text-white"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-purple-100 text-sm">Public</p>
            <p className="text-2xl font-bold">{stats.publicDevices}</p>
          </div>
          <Users className="h-8 w-8 text-purple-200" />
        </div>
      </motion.div>
    </div>
  );
};

const UserCard = ({ user, deviceName }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.9 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ duration: 0.2 }}
    className="group relative flex items-center p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-600 hover:shadow-lg transition-all duration-200"
  >
    <div className="flex-shrink-0 relative">
      {user.photoUrl ? (
        <img
          className="h-12 w-12 rounded-full object-cover ring-2 ring-gray-300 dark:ring-gray-600 group-hover:ring-blue-400 transition-all duration-200"
          src={user.photoUrl}
          alt={user.name}
        />
      ) : (
        <div className="h-12 w-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center ring-2 ring-gray-300 dark:ring-gray-600 group-hover:ring-blue-400 transition-all duration-200">
          <span className="text-white font-medium text-sm">
            {user.name?.charAt(0)?.toUpperCase() || 'U'}
          </span>
        </div>
      )}
      <div className="absolute -top-1 -right-1">
        {getRoleIcon(user.role)}
      </div>
    </div>
    
    <div className="ml-4 flex-1">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors duration-200">
            {user.name || 'Unknown User'}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            {user.email || 'No email'}
          </p>
        </div>
        <div className="flex flex-col items-end">
          <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full border ${getRoleBadgeColor(user.role)}`}>
            {user.role || 'user'}
          </span>
          <div className="flex items-center mt-1 text-xs text-gray-500 dark:text-gray-400">
            <Clock className="h-3 w-3 mr-1" />
            <span>Always</span>
          </div>
        </div>
      </div>
    </div>
  </motion.div>
);

export default function EnhancedDeviceAccessTable({ devices, users, rooms }) {
  const [expandedRows, setExpandedRows] = useState(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all'); // all, active, inactive
  const [filterAccess, setFilterAccess] = useState('all'); // all, restricted, public
  const [viewMode, setViewMode] = useState('table'); // table, grid

  const toggleRow = (deviceId) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(deviceId)) {
      newExpanded.delete(deviceId);
    } else {
      newExpanded.add(deviceId);
    }
    setExpandedRows(newExpanded);
  };

  const toggleAllRows = () => {
    if (expandedRows.size === filteredDevices.length) {
      setExpandedRows(new Set());
    } else {
      setExpandedRows(new Set(filteredDevices.map(d => d.id)));
    }
  };

  // Prepare and filter data
  const deviceAccessData = useMemo(() => {
    return Object.entries(devices).map(([deviceId, device]) => {
      const allowedUserIds = device.allowedUsers ? Object.keys(device.allowedUsers) : [];
      const allowedUsers = allowedUserIds.map(userId => ({
        id: userId,
        ...users[userId]
      })).filter(user => user.name);

      const roomName = rooms[device.roomId]?.name || 'Unknown Room';

      return {
        id: deviceId,
        ...device,
        roomName,
        allowedUsers
      };
    });
  }, [devices, users, rooms]);

  const filteredDevices = useMemo(() => {
    return deviceAccessData.filter(device => {
      const matchesSearch = device.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           device.roomName.toLowerCase().includes(searchTerm.toLowerCase());
      
      const matchesStatus = filterStatus === 'all' || 
                           (filterStatus === 'active' && device.state) ||
                           (filterStatus === 'inactive' && !device.state);
      
      const matchesAccess = filterAccess === 'all' ||
                           (filterAccess === 'restricted' && device.allowedUsers.length > 0) ||
                           (filterAccess === 'public' && device.allowedUsers.length === 0);

      return matchesSearch && matchesStatus && matchesAccess;
    });
  }, [deviceAccessData, searchTerm, filterStatus, filterAccess]);

  return (
    <div className="space-y-6">
      {/* Statistics Cards */}
      <DeviceAccessStats devices={deviceAccessData} />

      {/* Main Table Container */}
      <div className="glass-card rounded-xl overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Device Access Control
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Manage device permissions and user access
              </p>
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={toggleAllRows}
                className="px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200"
              >
                {expandedRows.size === filteredDevices.length ? 'Collapse All' : 'Expand All'}
              </button>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="px-6 py-4 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Search */}
            <div className="relative flex-1 max-w-md">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                placeholder="Search devices or rooms..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              {searchTerm && (
                <button
                  onClick={() => setSearchTerm('')}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                >
                  <X className="h-4 w-4 text-gray-400 hover:text-gray-600" />
                </button>
              )}
            </div>

            {/* Status Filter */}
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-400" />
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>

            {/* Access Filter */}
            <div className="flex items-center gap-2">
              <select
                value={filterAccess}
                onChange={(e) => setFilterAccess(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">All Access</option>
                <option value="restricted">Restricted</option>
                <option value="public">Public</option>
              </select>
            </div>
          </div>
        </div>

        {/* Table */}
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
                  Access Control
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
              <AnimatePresence>
                {filteredDevices.map((device) => {
                  const DeviceIcon = deviceIcons[device.name] || deviceIcons.default;
                  const isExpanded = expandedRows.has(device.id);
                  
                  return (
                    <React.Fragment key={device.id}>
                      <motion.tr
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -20 }}
                        transition={{ duration: 0.3 }}
                        className={`hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors duration-200 ${
                          isExpanded ? 'bg-blue-50 dark:bg-blue-900/20' : ''
                        }`}
                      >
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <div className={`p-2 rounded-lg transition-colors duration-200 ${
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
                          <div className={`inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded-full ${
                            device.state 
                              ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                              : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                          }`}>
                            {device.state ? (
                              <CheckCircle className="h-3 w-3 mr-1" />
                            ) : (
                              <AlertCircle className="h-3 w-3 mr-1" />
                            )}
                            {device.state ? 'Active' : 'Inactive'}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className={`inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded-full ${
                            device.allowedUsers.length > 0
                              ? 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300'
                              : 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
                          }`}>
                            {device.allowedUsers.length > 0 ? (
                              <Lock className="h-3 w-3 mr-1" />
                            ) : (
                              <Users className="h-3 w-3 mr-1" />
                            )}
                            {device.allowedUsers.length > 0 ? 'Restricted' : 'Public'}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <span className="text-sm font-medium text-gray-900 dark:text-white">
                              {device.allowedUsers.length} user{device.allowedUsers.length !== 1 ? 's' : ''}
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
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => toggleRow(device.id)}
                              className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200 p-1 rounded-full hover:bg-blue-100 dark:hover:bg-blue-900/20"
                              title={isExpanded ? 'Collapse details' : 'View details'}
                            >
                              {isExpanded ? (
                                <ChevronUp className="h-4 w-4" />
                              ) : (
                                <ChevronDown className="h-4 w-4" />
                              )}
                            </button>
                          </div>
                        </td>
                      </motion.tr>
                      
                      <AnimatePresence>
                        {isExpanded && (
                          <motion.tr
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            exit={{ opacity: 0, height: 0 }}
                            transition={{ duration: 0.3 }}
                            className="bg-gray-50 dark:bg-gray-800/50"
                          >
                            <td colSpan="6" className="px-6 py-6">
                              <div className="space-y-6">
                                <div className="flex items-center justify-between">
                                  <h4 className="text-lg font-medium text-gray-900 dark:text-white flex items-center">
                                    <Users className="h-5 w-5 mr-2" />
                                    Authorized Users ({device.allowedUsers.length})
                                  </h4>
                                  <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                                    <Activity className="h-4 w-4" />
                                    <span>Last updated: Just now</span>
                                  </div>
                                </div>
                                
                                {device.allowedUsers.length > 0 ? (
                                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                    {device.allowedUsers.map((user) => (
                                      <UserCard key={user.id} user={user} deviceName={device.name} />
                                    ))}
                                  </div>
                                ) : (
                                  <motion.div 
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    className="text-center py-8"
                                  >
                                    <div className="mx-auto h-16 w-16 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center mb-4">
                                      <Users className="h-8 w-8 text-gray-400" />
                                    </div>
                                    <p className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                                      Public Device
                                    </p>
                                    <p className="text-sm text-gray-500 dark:text-gray-400 max-w-md mx-auto">
                                      This device has no access restrictions. All users in the system can control this device.
                                    </p>
                                  </motion.div>
                                )}
                              </div>
                            </td>
                          </motion.tr>
                        )}
                      </AnimatePresence>
                    </React.Fragment>
                  );
                })}
              </AnimatePresence>
            </tbody>
          </table>
          
          {filteredDevices.length === 0 && (
            <div className="text-center py-12">
              <Device className="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <p className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                No devices found
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {searchTerm || filterStatus !== 'all' || filterAccess !== 'all'
                  ? 'Try adjusting your search terms or filters'
                  : 'No devices are available'}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
