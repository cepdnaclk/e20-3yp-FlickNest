import { useState, useEffect } from 'react';
import { DeviceActivityStorage } from '../utils/deviceActivityStorage';

export function useDeviceActivity(environmentId, timeRange = '24h') {
  const [activityData, setActivityData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!environmentId) {
      setLoading(false);
      return;
    }

    try {
      // Get activity data from local storage
      const chartData = DeviceActivityStorage.processActivitiesForChart(environmentId, timeRange);
      setActivityData(chartData);
      setLoading(false);
      setError(null);
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
    
    // Set up an interval to refresh data periodically
    const interval = setInterval(() => {
      try {
        const chartData = DeviceActivityStorage.processActivitiesForChart(environmentId, timeRange);
        setActivityData(chartData);
      } catch (err) {
        setError(err.message);
      }
    }, 30000); // Update every 30 seconds

    return () => {
      clearInterval(interval);
    };
  }, [environmentId, timeRange]);

  return { activityData, loading, error };
}

function processActivityData(activities, timeRange) {
  const now = new Date();
  const startTime = getStartTime(now, timeRange);
  
  // Create time intervals based on range
  const intervals = createTimeIntervals(startTime, now, timeRange);
  
  // Process activities into time-based buckets
  const activityMap = new Map();
  
  Object.entries(activities).forEach(([timestamp, activity]) => {
    const activityTime = new Date(parseInt(timestamp));
    if (activityTime >= startTime) {
      const interval = findInterval(activityTime, intervals);
      if (interval) {
        if (!activityMap.has(interval)) {
          activityMap.set(interval, { active: 0, inactive: 0, total: 0 });
        }
        const stats = activityMap.get(interval);
        if (activity.state) {
          stats.active++;
        } else {
          stats.inactive++;
        }
        stats.total++;
      }
    }
  });
  
  // Convert to chart data format
  return intervals.map(interval => ({
    time: formatTimeLabel(interval, timeRange),
    active: activityMap.get(interval)?.active || 0,
    inactive: activityMap.get(interval)?.inactive || 0,
    total: activityMap.get(interval)?.total || 0
  }));
}

function generateSimulatedActivityData(devices, timeRange) {
  const now = new Date();
  const startTime = getStartTime(now, timeRange);
  const intervals = createTimeIntervals(startTime, now, timeRange);
  
  const totalDevices = Object.keys(devices).length;
  const activeDevices = Object.values(devices).filter(device => device.state).length;
  
  return intervals.map(interval => {
    // Add some realistic variation to the data
    const variation = Math.random() * 0.3 - 0.15; // ±15% variation
    const baseActive = activeDevices;
    const simulatedActive = Math.max(0, Math.min(totalDevices, 
      Math.floor(baseActive + (baseActive * variation))
    ));
    
    return {
      time: formatTimeLabel(interval, timeRange),
      active: simulatedActive,
      inactive: totalDevices - simulatedActive,
      total: totalDevices
    };
  });
}

function getStartTime(now, timeRange) {
  const startTime = new Date(now);
  switch (timeRange) {
    case '1h':
      startTime.setHours(now.getHours() - 1);
      break;
    case '6h':
      startTime.setHours(now.getHours() - 6);
      break;
    case '24h':
      startTime.setHours(now.getHours() - 24);
      break;
    case '7d':
      startTime.setDate(now.getDate() - 7);
      break;
    case '30d':
      startTime.setDate(now.getDate() - 30);
      break;
    default:
      startTime.setHours(now.getHours() - 24);
  }
  return startTime;
}

function createTimeIntervals(startTime, endTime, timeRange) {
  const intervals = [];
  let current = new Date(startTime);
  
  // Determine interval size based on time range
  let intervalMinutes;
  switch (timeRange) {
    case '1h':
      intervalMinutes = 5; // 5-minute intervals
      break;
    case '6h':
      intervalMinutes = 30; // 30-minute intervals
      break;
    case '24h':
      intervalMinutes = 60; // 1-hour intervals
      break;
    case '7d':
      intervalMinutes = 360; // 6-hour intervals
      break;
    case '30d':
      intervalMinutes = 1440; // 24-hour intervals
      break;
    default:
      intervalMinutes = 60;
  }
  
  while (current < endTime) {
    intervals.push(new Date(current));
    current.setMinutes(current.getMinutes() + intervalMinutes);
  }
  
  return intervals;
}

function findInterval(activityTime, intervals) {
  for (let i = 0; i < intervals.length - 1; i++) {
    if (activityTime >= intervals[i] && activityTime < intervals[i + 1]) {
      return intervals[i];
    }
  }
  return intervals[intervals.length - 1];
}

function formatTimeLabel(date, timeRange) {
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
