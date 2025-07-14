import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  Activity, 
  Home, 
  Zap, 
  Users, 
  Settings, 
  Wifi,
  Shield,
  Clock,
  Monitor,
  Server,
  Gauge,
  TrendingUp
} from 'lucide-react';
import { useFirebaseData } from '../hooks/useFirebaseData';
import EnvironmentSelector from '../components/EnvironmentSelector';
import ThemeToggle from '../components/ThemeToggle';
import DeviceChart from '../components/DeviceChart';
import UsersTable from '../components/UsersTable';
import DeviceAccessTable from '../components/DeviceAccessTable';
import RoomCard from '../components/RoomCard';
import StatsCard from '../components/StatsCard';

export default function Dashboard() {
  const [selectedEnvironment, setSelectedEnvironment] = useState('env_12345');
  
  const { data: environments, loading: envLoading } = useFirebaseData('environments');
  const { data: symbols, loading: symbolsLoading } = useFirebaseData('symbols');
  const { data: users, loading: usersLoading } = useFirebaseData('users');
  
  const environment = environments?.[selectedEnvironment];
  const rooms = environment?.rooms || {};
  const devices = environment?.devices || {};
  
  // Calculate statistics
  const totalDevices = Object.keys(devices).length;
  const activeDevices = Object.values(devices).filter(device => device.state).length;
  const totalRooms = Object.keys(rooms).length;
  const totalUsers = environment?.users ? Object.keys(environment.users).length : 0;
  const availableSymbols = symbols ? Object.values(symbols).filter(symbol => symbol.available).length : 0;
  
  if (envLoading || symbolsLoading || usersLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="glass-card rounded-xl p-8 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500 mx-auto mb-4"></div>
          <p className="text-gray-400">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="dashboard-header sticky top-0 z-10">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between">
          <div className="flex items-center space-x-4 mb-4 md:mb-0">
            <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-lg">
              <Monitor className="h-8 w-8 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                Smart Home Dashboard
              </h1>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Monitor and control your smart home devices in real-time
              </p>
            </div>
          </div>
          
          <div className="flex items-center space-x-4">
            <EnvironmentSelector
              environments={environments}
              currentEnvironment={selectedEnvironment}
              onEnvironmentChange={setSelectedEnvironment}
            />
            <ThemeToggle />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          {/* Key Metrics Overview */}
          <section>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <Gauge className="h-5 w-5 mr-2 text-blue-600" />
              System Overview
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="metric-card metric-primary">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Total Devices</p>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">{totalDevices}</p>
                    <p className="text-xs text-gray-500">{activeDevices} active</p>
                  </div>
                  <Server className="h-8 w-8 text-blue-500" />
                </div>
              </div>
              
              <div className="metric-card metric-success">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Active Rate</p>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">
                      {totalDevices > 0 ? `${((activeDevices / totalDevices) * 100).toFixed(1)}%` : '0%'}
                    </p>
                    <p className="text-xs text-gray-500">{activeDevices}/{totalDevices} devices</p>
                  </div>
                  <Activity className="h-8 w-8 text-green-500" />
                </div>
              </div>
              
              <div className="metric-card metric-warning">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Rooms</p>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">{totalRooms}</p>
                    <p className="text-xs text-gray-500">Total rooms</p>
                  </div>
                  <Home className="h-8 w-8 text-yellow-500" />
                </div>
              </div>
              
              <div className="metric-card metric-primary">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Users</p>
                    <p className="text-2xl font-bold text-gray-900 dark:text-white">{totalUsers}</p>
                    <p className="text-xs text-gray-500">Environment users</p>
                  </div>
                  <Users className="h-8 w-8 text-blue-500" />
                </div>
              </div>
            </div>
          </section>

          {/* Charts Section */}
          <section>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
              Analytics & Monitoring
            </h2>
            
            {/* Primary Charts Row */}
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
              <div className="order-1">
                <DeviceChart devices={devices} rooms={rooms} type='pie' environmentId={selectedEnvironment} />
              </div>
              <div className="order-2">
                <DeviceChart devices={devices} rooms={rooms} type='radial' environmentId={selectedEnvironment} />
              </div>
            </div>
            
            {/* Secondary Charts Row */}
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
              <div className="order-1">
                <DeviceChart devices={devices} rooms={rooms} type='deviceTypes' environmentId={selectedEnvironment} />
              </div>
              <div className="order-2">
                <DeviceChart devices={devices} rooms={rooms} type='bar' environmentId={selectedEnvironment} />
              </div>
            </div>
            
            {/* Full Width Time Series Chart */}
            <div className="mb-6">
              <DeviceChart devices={devices} rooms={rooms} type='line' environmentId={selectedEnvironment} />
            </div>
          </section>

          {/* System Status */}
          <section>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <Monitor className="h-5 w-5 mr-2 text-blue-600" />
              System Status
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="monitor-card p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">System Health</p>
                    <div className="flex items-center mt-1">
                      <div className="h-2 w-2 bg-green-500 rounded-full mr-2"></div>
                      <span className="text-sm font-medium text-green-600 dark:text-green-400">Operational</span>
                    </div>
                  </div>
                  <Wifi className="h-6 w-6 text-green-500" />
                </div>
              </div>
              
              <div className="monitor-card p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Available Symbols</p>
                    <p className="text-lg font-bold text-gray-900 dark:text-white">{availableSymbols}</p>
                  </div>
                  <Shield className="h-6 w-6 text-blue-500" />
                </div>
              </div>
              
              <div className="monitor-card p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Last Updated</p>
                    <div className="flex items-center mt-1">
                      <div className="h-2 w-2 bg-blue-500 rounded-full mr-2 animate-pulse"></div>
                      <span className="text-sm font-medium text-blue-600 dark:text-blue-400">Live</span>
                    </div>
                  </div>
                  <Clock className="h-6 w-6 text-blue-500" />
                </div>
              </div>
            </div>
          </section>

          {/* Users Table */}
          {environment && environment.users && (
            <section>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <Users className="h-5 w-5 mr-2 text-blue-600" />
                User Access and Roles
              </h2>
              <UsersTable users={environment.users} devices={devices} globalUsers={users} />
            </section>
          )}

          {/* Device Access Table */}
          {environment && environment.users && (
            <section>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <Shield className="h-5 w-5 mr-2 text-blue-600" />
                Device Access Control
              </h2>
              <DeviceAccessTable devices={devices} users={environment.users} rooms={rooms} globalUsers={users} />
            </section>
          )}

          {/* Environment Info */}
          {environment && (
            <section>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <Settings className="h-5 w-5 mr-2 text-blue-600" />
                Environment: {environment.name}
              </h2>
              <div className="monitor-card p-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Admin</p>
                    <p className="font-semibold text-gray-900 dark:text-white">
                      {environment.users?.[environment.adminId]?.name || 'Unknown'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Created</p>
                    <p className="font-semibold text-gray-900 dark:text-white">
                      {environment.createdAt 
                        ? new Date(environment.createdAt).toLocaleDateString()
                        : 'N/A'
                      }
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Device Usage</p>
                    <p className="font-semibold text-gray-900 dark:text-white">
                      {totalDevices > 0 ? `${((activeDevices / totalDevices) * 100).toFixed(1)}%` : '0%'}
                    </p>
                  </div>
                </div>
              </div>
            </section>
          )}

          {/* Rooms */}
          <section>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <Home className="h-5 w-5 mr-2 text-blue-600" />
              Rooms
            </h2>
            <div className="space-y-4">
              {Object.entries(rooms).map(([roomId, room]) => (
                <RoomCard
                  key={roomId}
                  room={room}
                  roomId={roomId}
                  devices={devices}
                  symbols={symbols}
                  environmentId={selectedEnvironment}
                />
              ))}
            </div>

            {/* No rooms message */}
            {Object.keys(rooms).length === 0 && (
              <div className="monitor-card p-12 text-center">
                <Settings className="mx-auto h-16 w-16 text-gray-400 mb-4" />
                <h3 className="text-xl font-semibold mb-2 text-gray-900 dark:text-white">No Rooms Found</h3>
                <p className="text-gray-500 dark:text-gray-400">
                  This environment doesn't have any rooms configured yet.
                </p>
              </div>
            )}
          </section>
        </div>
      </main>
    </div>
  );
}
