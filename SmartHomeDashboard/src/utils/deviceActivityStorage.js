// Device Activity Storage Utility
// Stores device activation/deactivation events locally with timestamps

const STORAGE_KEY = 'smart_home_device_activity';
const USER_ACTIVITY_KEY = 'smart_home_user_activity';
const MAX_ACTIVITY_RECORDS = 10000; // Limit to prevent storage overflow

export class DeviceActivityStorage {
  // Store device activation/deactivation event
  static logDeviceActivity(deviceId, deviceName, roomId, roomName, state, userId, userName, environmentId) {
    const activity = {
      id: Date.now() + Math.random().toString(36).substr(2, 9),
      deviceId,
      deviceName,
      roomId,
      roomName,
      state, // true for active, false for inactive
      userId,
      userName,
      environmentId,
      timestamp: Date.now(),
      date: new Date().toISOString()
    };

    // Get existing activities
    const activities = this.getActivities();
    
    // Add new activity
    activities.push(activity);
    
    // Keep only recent activities (prevent storage overflow)
    const recentActivities = activities
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, MAX_ACTIVITY_RECORDS);
    
    // Store back to localStorage
    localStorage.setItem(STORAGE_KEY, JSON.stringify(recentActivities));
    
    // Update user activity statistics
    this.updateUserActivityStats(userId, userName, deviceId, deviceName, state, environmentId);
    
    return activity;
  }

  // Get all device activities
  static getActivities(environmentId = null) {
    try {
      const activities = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
      
      if (environmentId) {
        return activities.filter(activity => activity.environmentId === environmentId);
      }
      
      return activities;
    } catch (error) {
      console.error('Error getting activities:', error);
      return [];
    }
  }

  // Get activities for a specific device
  static getDeviceActivities(deviceId, environmentId = null) {
    const activities = this.getActivities(environmentId);
    return activities.filter(activity => activity.deviceId === deviceId);
  }

  // Get activities for a specific user
  static getUserActivities(userId, environmentId = null) {
    const activities = this.getActivities(environmentId);
    return activities.filter(activity => activity.userId === userId);
  }

  // Get activities within a time range
  static getActivitiesInRange(startTime, endTime, environmentId = null) {
    const activities = this.getActivities(environmentId);
    return activities.filter(activity => 
      activity.timestamp >= startTime && activity.timestamp <= endTime
    );
  }

  // Update user activity statistics
  static updateUserActivityStats(userId, userName, deviceId, deviceName, state, environmentId) {
    const userStats = this.getUserActivityStats();
    
    const key = `${environmentId}_${userId}`;
    
    if (!userStats[key]) {
      userStats[key] = {
        userId,
        userName,
        environmentId,
        totalActivations: 0,
        totalDeactivations: 0,
        devices: {},
        lastActivity: Date.now(),
        firstActivity: Date.now()
      };
    }

    const userStat = userStats[key];
    
    // Update counters
    if (state) {
      userStat.totalActivations++;
    } else {
      userStat.totalDeactivations++;
    }
    
    // Update device-specific stats
    if (!userStat.devices[deviceId]) {
      userStat.devices[deviceId] = {
        deviceName,
        activations: 0,
        deactivations: 0,
        lastAccess: Date.now()
      };
    }
    
    const deviceStat = userStat.devices[deviceId];
    if (state) {
      deviceStat.activations++;
    } else {
      deviceStat.deactivations++;
    }
    deviceStat.lastAccess = Date.now();
    
    userStat.lastActivity = Date.now();
    
    // Store updated stats
    localStorage.setItem(USER_ACTIVITY_KEY, JSON.stringify(userStats));
  }

  // Get user activity statistics
  static getUserActivityStats(environmentId = null) {
    try {
      const allStats = JSON.parse(localStorage.getItem(USER_ACTIVITY_KEY) || '{}');
      
      if (environmentId) {
        const filteredStats = {};
        Object.keys(allStats).forEach(key => {
          if (key.startsWith(`${environmentId}_`)) {
            filteredStats[key] = allStats[key];
          }
        });
        return filteredStats;
      }
      
      return allStats;
    } catch (error) {
      console.error('Error getting user activity stats:', error);
      return {};
    }
  }

  // Get device usage statistics
  static getDeviceUsageStats(deviceId, environmentId = null) {
    const activities = this.getDeviceActivities(deviceId, environmentId);
    const userStats = this.getUserActivityStats(environmentId);
    
    const stats = {
      totalActivations: 0,
      totalDeactivations: 0,
      totalAccesses: activities.length,
      userAccess: {},
      recentActivity: activities.slice(0, 50), // Last 50 activities
      dailyUsage: {},
      hourlyUsage: {}
    };

    // Process activities
    activities.forEach(activity => {
      if (activity.state) {
        stats.totalActivations++;
      } else {
        stats.totalDeactivations++;
      }

      // User access tracking
      if (!stats.userAccess[activity.userId]) {
        stats.userAccess[activity.userId] = {
          userName: activity.userName,
          activations: 0,
          deactivations: 0,
          lastAccess: activity.timestamp
        };
      }

      const userAccess = stats.userAccess[activity.userId];
      if (activity.state) {
        userAccess.activations++;
      } else {
        userAccess.deactivations++;
      }
      userAccess.lastAccess = Math.max(userAccess.lastAccess, activity.timestamp);

      // Daily usage
      const day = new Date(activity.timestamp).toDateString();
      if (!stats.dailyUsage[day]) {
        stats.dailyUsage[day] = { activations: 0, deactivations: 0 };
      }
      if (activity.state) {
        stats.dailyUsage[day].activations++;
      } else {
        stats.dailyUsage[day].deactivations++;
      }

      // Hourly usage
      const hour = new Date(activity.timestamp).getHours();
      if (!stats.hourlyUsage[hour]) {
        stats.hourlyUsage[hour] = { activations: 0, deactivations: 0 };
      }
      if (activity.state) {
        stats.hourlyUsage[hour].activations++;
      } else {
        stats.hourlyUsage[hour].deactivations++;
      }
    });

    return stats;
  }

  // Process activities for chart data
  static processActivitiesForChart(environmentId, timeRange = '24h') {
    const activities = this.getActivities(environmentId);
    const now = Date.now();
    
    let startTime;
    let intervalMs;
    
    switch (timeRange) {
      case '1h':
        startTime = now - (60 * 60 * 1000);
        intervalMs = 5 * 60 * 1000; // 5 minutes
        break;
      case '6h':
        startTime = now - (6 * 60 * 60 * 1000);
        intervalMs = 30 * 60 * 1000; // 30 minutes
        break;
      case '24h':
        startTime = now - (24 * 60 * 60 * 1000);
        intervalMs = 60 * 60 * 1000; // 1 hour
        break;
      case '7d':
        startTime = now - (7 * 24 * 60 * 60 * 1000);
        intervalMs = 6 * 60 * 60 * 1000; // 6 hours
        break;
      case '30d':
        startTime = now - (30 * 24 * 60 * 60 * 1000);
        intervalMs = 24 * 60 * 60 * 1000; // 24 hours
        break;
      default:
        startTime = now - (24 * 60 * 60 * 1000);
        intervalMs = 60 * 60 * 1000;
    }

    // Filter activities within time range
    const relevantActivities = activities.filter(activity => 
      activity.timestamp >= startTime && activity.timestamp <= now
    );

    // Create time intervals
    const intervals = [];
    for (let time = startTime; time < now; time += intervalMs) {
      intervals.push({
        start: time,
        end: time + intervalMs,
        label: this.formatTimeLabel(new Date(time), timeRange)
      });
    }

    // Process activities into intervals
    const chartData = intervals.map(interval => {
      const intervalActivities = relevantActivities.filter(activity =>
        activity.timestamp >= interval.start && activity.timestamp < interval.end
      );

      const activations = intervalActivities.filter(a => a.state).length;
      const deactivations = intervalActivities.filter(a => !a.state).length;

      return {
        time: interval.label,
        active: activations,
        inactive: deactivations,
        total: activations + deactivations
      };
    });

    return chartData;
  }

  // Format time label based on range
  static formatTimeLabel(date, timeRange) {
    switch (timeRange) {
      case '1h':
      case '6h':
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      case '24h':
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      case '7d':
        return date.toLocaleDateString([], { weekday: 'short', hour: '2-digit' });
      case '30d':
        return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
      default:
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
  }

  // Clear all activity data
  static clearAllActivities() {
    localStorage.removeItem(STORAGE_KEY);
    localStorage.removeItem(USER_ACTIVITY_KEY);
  }

  // Clear activities for specific environment
  static clearEnvironmentActivities(environmentId) {
    const activities = this.getActivities();
    const filteredActivities = activities.filter(activity => 
      activity.environmentId !== environmentId
    );
    localStorage.setItem(STORAGE_KEY, JSON.stringify(filteredActivities));

    // Clear user stats for this environment
    const userStats = this.getUserActivityStats();
    const filteredUserStats = {};
    Object.keys(userStats).forEach(key => {
      if (!key.startsWith(`${environmentId}_`)) {
        filteredUserStats[key] = userStats[key];
      }
    });
    localStorage.setItem(USER_ACTIVITY_KEY, JSON.stringify(filteredUserStats));
  }

  // Export activities to JSON
  static exportActivities(environmentId = null) {
    const activities = this.getActivities(environmentId);
    const userStats = this.getUserActivityStats(environmentId);
    
    return {
      activities,
      userStats,
      exportDate: new Date().toISOString(),
      environmentId
    };
  }

  // Import activities from JSON
  static importActivities(data) {
    if (data.activities) {
      const existingActivities = this.getActivities();
      const allActivities = [...existingActivities, ...data.activities];
      
      // Remove duplicates and sort
      const uniqueActivities = allActivities
        .filter((activity, index, self) => 
          index === self.findIndex(a => a.id === activity.id)
        )
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, MAX_ACTIVITY_RECORDS);
      
      localStorage.setItem(STORAGE_KEY, JSON.stringify(uniqueActivities));
    }

    if (data.userStats) {
      const existingUserStats = this.getUserActivityStats();
      const mergedStats = { ...existingUserStats, ...data.userStats };
      localStorage.setItem(USER_ACTIVITY_KEY, JSON.stringify(mergedStats));
    }
  }
}
