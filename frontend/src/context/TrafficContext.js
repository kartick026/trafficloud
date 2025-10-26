import React, { createContext, useContext, useState, useEffect } from 'react';
import { API } from 'aws-amplify';

const TrafficContext = createContext();

export const useTraffic = () => {
  const context = useContext(TrafficContext);
  if (!context) {
    throw new Error('useTraffic must be used within a TrafficProvider');
  }
  return context;
};

export const TrafficProvider = ({ children }) => {
  const [trafficData, setTrafficData] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Mock data for development
  const mockTrafficData = [
    {
      frame_id: 'junction_1_1703123456',
      timestamp: new Date().toISOString(),
      location: 'Main Street Junction',
      vehicle_counts: {
        cars: 15,
        trucks: 3,
        buses: 2,
        bikes: 8,
        ambulances: 0,
        total: 28
      },
      congestion_score: 0.65,
      clearance_time_minutes: 12,
      ambulance_detected: false
    },
    {
      frame_id: 'junction_2_1703123457',
      timestamp: new Date(Date.now() - 300000).toISOString(),
      location: 'Highway Intersection',
      vehicle_counts: {
        cars: 25,
        trucks: 5,
        buses: 1,
        bikes: 3,
        ambulances: 1,
        total: 35
      },
      congestion_score: 0.85,
      clearance_time_minutes: 18,
      ambulance_detected: true
    }
  ];

  const mockAlerts = [
    {
      id: 1,
      type: 'HIGH_PRIORITY',
      message: 'Ambulance detected at Highway Intersection',
      timestamp: new Date().toISOString(),
      location: 'Highway Intersection',
      severity: 'high'
    },
    {
      id: 2,
      type: 'TRAFFIC_CONGESTION',
      message: 'High traffic congestion detected at Main Street Junction',
      timestamp: new Date(Date.now() - 600000).toISOString(),
      location: 'Main Street Junction',
      severity: 'medium'
    }
  ];

  useEffect(() => {
    // Load initial data
    setTrafficData(mockTrafficData);
    setAlerts(mockAlerts);
  }, []);

  const uploadImage = async (imageFile, location) => {
    setLoading(true);
    setError(null);
    
    try {
      // In production, this would upload to S3 and trigger Lambda
      const formData = new FormData();
      formData.append('image', imageFile);
      formData.append('location', location);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Mock response
      const newTrafficData = {
        frame_id: `${location}_${Date.now()}`,
        timestamp: new Date().toISOString(),
        location: location,
        vehicle_counts: {
          cars: Math.floor(Math.random() * 20) + 5,
          trucks: Math.floor(Math.random() * 5),
          buses: Math.floor(Math.random() * 3),
          bikes: Math.floor(Math.random() * 10),
          ambulances: Math.random() > 0.8 ? 1 : 0,
          total: 0
        },
        congestion_score: Math.random() * 0.8 + 0.2,
        clearance_time_minutes: Math.floor(Math.random() * 20) + 5,
        ambulance_detected: Math.random() > 0.8
      };
      
      newTrafficData.vehicle_counts.total = Object.values(newTrafficData.vehicle_counts).reduce((sum, count) => sum + count, 0);
      
      setTrafficData(prev => [newTrafficData, ...prev]);
      
      // Check for alerts
      if (newTrafficData.ambulance_detected) {
        const newAlert = {
          id: Date.now(),
          type: 'HIGH_PRIORITY',
          message: `Ambulance detected at ${location}`,
          timestamp: newTrafficData.timestamp,
          location: location,
          severity: 'high'
        };
        setAlerts(prev => [newAlert, ...prev]);
      } else if (newTrafficData.congestion_score > 0.7) {
        const newAlert = {
          id: Date.now(),
          type: 'TRAFFIC_CONGESTION',
          message: `High traffic congestion detected at ${location}`,
          timestamp: newTrafficData.timestamp,
          location: location,
          severity: 'medium'
        };
        setAlerts(prev => [newAlert, ...prev]);
      }
      
      return newTrafficData;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getTrafficHistory = async (location, hours = 24) => {
    setLoading(true);
    try {
      // In production, this would query DynamoDB
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Return mock historical data
      return trafficData.filter(item => 
        item.location === location && 
        new Date(item.timestamp) > new Date(Date.now() - hours * 60 * 60 * 1000)
      );
    } catch (err) {
      setError(err.message);
      return [];
    } finally {
      setLoading(false);
    }
  };

  const dismissAlert = (alertId) => {
    setAlerts(prev => prev.filter(alert => alert.id !== alertId));
  };

  const value = {
    trafficData,
    alerts,
    loading,
    error,
    uploadImage,
    getTrafficHistory,
    dismissAlert
  };

  return (
    <TrafficContext.Provider value={value}>
      {children}
    </TrafficContext.Provider>
  );
};
