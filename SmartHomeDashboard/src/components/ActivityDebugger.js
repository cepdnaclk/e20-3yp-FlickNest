import React, { useState, useEffect } from 'react';
import { DeviceActivityStorage } from '../utils/deviceActivityStorage';
import { Bug, RefreshCw, Trash2, Eye } from 'lucide-react';

export default function ActivityDebugger({ environmentId }) {
  const [activities, setActivities] = useState([]);
  const [userStats, setUserStats] = useState({});
  const [showDetails, setShowDetails] = useState(false);

  const refreshData = () => {
    try {
      const allActivities = DeviceActivityStorage.getActivities(environmentId);
      const allUserStats = DeviceActivityStorage.getUserActivityStats(environmentId);
      
      setActivities(allActivities);
      setUserStats(allUserStats);
      
      console.log('Activities:', allActivities);
      console.log('User Stats:', allUserStats);
    } catch (error) {
      console.error('Error refreshing data:', error);
    }
  };

  const clearData = () => {
    if (confirm('Are you sure you want to clear all activity data?')) {
      DeviceActivityStorage.clearEnvironmentActivities(environmentId);
      refreshData();
    }
  };

  useEffect(() => {
    refreshData();

    // Set up real-time activity listener
    const handleActivityLogged = (eventData) => {
      if (eventData.environmentId === environmentId) {
        refreshData();
      }
    };

    DeviceActivityStorage.onActivityLogged(handleActivityLogged);

    return () => {
      DeviceActivityStorage.offActivityLogged(handleActivityLogged);
    };
  }, [environmentId]);

  return (
    <div className="monitor-card p-6 mb-6 border-2 border-orange-200 dark:border-orange-800">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
          <Bug className="h-5 w-5 mr-2 text-orange-600" />
          Activity Debugger
        </h3>
        <div className="flex items-center space-x-2">
          <button
            onClick={refreshData}
            className="flex items-center px-3 py-1 bg-blue-500 text-white rounded-md hover:bg-blue-600 text-sm"
          >
            <RefreshCw className="h-4 w-4 mr-1" />
            Refresh
          </button>
          <button
            onClick={clearData}
            className="flex items-center px-3 py-1 bg-red-500 text-white rounded-md hover:bg-red-600 text-sm"
          >
            <Trash2 className="h-4 w-4 mr-1" />
            Clear
          </button>
          <button
            onClick={() => setShowDetails(!showDetails)}
            className="flex items-center px-3 py-1 bg-gray-500 text-white rounded-md hover:bg-gray-600 text-sm"
          >
            <Eye className="h-4 w-4 mr-1" />
            {showDetails ? 'Hide' : 'Show'} Details
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div className="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
          <h4 className="font-medium text-gray-900 dark:text-white mb-2">Total Activities</h4>
          <p className="text-2xl font-bold text-blue-600">{activities.length}</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
          <h4 className="font-medium text-gray-900 dark:text-white mb-2">Unique Users</h4>
          <p className="text-2xl font-bold text-green-600">{Object.keys(userStats).length}</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
          <h4 className="font-medium text-gray-900 dark:text-white mb-2">Recent Activity</h4>
          <p className="text-2xl font-bold text-purple-600">
            {activities.length > 0 ? 
              new Date(activities[0].timestamp).toLocaleTimeString() : 
              'None'
            }
          </p>
        </div>
      </div>

      {showDetails && (
        <div className="space-y-4">
          <div>
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">Recent Activities</h4>
            <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded-lg max-h-40 overflow-y-auto">
              {activities.length > 0 ? (
                activities.slice(0, 10).map((activity, index) => (
                  <div key={index} className="text-sm mb-2 last:mb-0">
                    <span className="font-medium">{activity.userName}</span> {' '}
                    <span className={activity.state ? 'text-green-600' : 'text-red-600'}>
                      {activity.state ? 'activated' : 'deactivated'}
                    </span> {' '}
                    <span className="text-gray-600">{activity.deviceName}</span> {' '}
                    <span className="text-gray-400">
                      ({new Date(activity.timestamp).toLocaleString()})
                    </span>
                  </div>
                ))
              ) : (
                <p className="text-gray-500 text-sm">No activities recorded</p>
              )}
            </div>
          </div>

          <div>
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">User Statistics</h4>
            <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded-lg">
              {Object.keys(userStats).length > 0 ? (
                Object.entries(userStats).map(([userId, stats]) => (
                  <div key={userId} className="text-sm mb-2 last:mb-0">
                    <span className="font-medium">{stats.userName}</span> - {' '}
                    <span className="text-green-600">{stats.totalActivations} activations</span>, {' '}
                    <span className="text-red-600">{stats.totalDeactivations} deactivations</span>
                  </div>
                ))
              ) : (
                <p className="text-gray-500 text-sm">No user statistics available</p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
