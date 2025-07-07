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
  Clock
} from 'lucide-react';
import { useFirebaseData } from '../hooks/useFirebaseData';
import EnvironmentSelector from '../components/EnvironmentSelector';
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
    <div className="min-h-screen p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between mb-8">
          <div className="mb-4 md:mb-0">
            <h1 className="text-3xl font-bold gradient-text mb-2">
              Smart Home Dashboard
            </h1>
            <p className="text-gray-400">
              Monitor and control your smart home devices in real-time
            </p>
          </div>
          
          <EnvironmentSelector
            environments={environments}
            currentEnvironment={selectedEnvironment}
            onEnvironmentChange={setSelectedEnvironment}
          />
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatsCard
            title="Total Devices"
            value={totalDevices}
            subtitle={`${activeDevices} active`}
            icon={Zap}
            color="primary"
          />
          <StatsCard
            title="Active Devices"
            value={activeDevices}
            subtitle={`${((activeDevices / totalDevices) * 100).toFixed(1)}% usage`}
            icon={Activity}
            color="green"
          />
          <StatsCard
            title="Rooms"
            value={totalRooms}
            subtitle="Total rooms"
            icon={Home}
            color="blue"
          />
          <StatsCard
            title="Users"
            value={totalUsers}
            subtitle="Environment users"
            icon={Users}
            color="yellow"
          />
        </div>

        {/* Additional Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatsCard
            title="Available Symbols"
            value={availableSymbols}
            subtitle="Ready for assignment"
            icon={Shield}
            color="green"
          />
          <StatsCard
            title="System Status"
            value="Online"
            subtitle="All systems operational"
            icon={Wifi}
            color="green"
          />
          <StatsCard
            title="Last Updated"
            value="Live"
            subtitle="Real-time monitoring"
            icon={Clock}
            color="primary"
          />
        </div>

        {/* Environment Info */}
        {environment && (
          <div className="glass-card rounded-xl p-6 mb-8">
            <h2 className="text-xl font-bold mb-4">Environment: {environment.name}</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-gray-400">Admin</p>
                <p className="font-semibold">
                  {environment.users?.[environment.adminId]?.name || 'Unknown'}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-400">Created</p>
                <p className="font-semibold">
                  {environment.createdAt 
                    ? new Date(environment.createdAt).toLocaleDateString()
                    : 'N/A'
                  }
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-400">Device Usage</p>
                <p className="font-semibold">
                  {totalDevices > 0 ? `${((activeDevices / totalDevices) * 100).toFixed(1)}%` : '0%'}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Rooms */}
        <div className="space-y-8">
          <h2 className="text-2xl font-bold">Rooms</h2>
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
          <div className="glass-card rounded-xl p-12 text-center">
            <Settings className="mx-auto h-16 w-16 text-gray-400 mb-4" />
            <h3 className="text-xl font-semibold mb-2">No Rooms Found</h3>
            <p className="text-gray-400">
              This environment doesn't have any rooms configured yet.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
