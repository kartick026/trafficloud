import React, { useState, useEffect } from 'react';
import { useTraffic } from '../context/TrafficContext';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from 'recharts';
import { Calendar, MapPin, TrendingUp } from 'lucide-react';

const Analytics = () => {
  const { trafficData, getTrafficHistory, loading } = useTraffic();
  const [selectedLocation, setSelectedLocation] = useState('all');
  const [timeRange, setTimeRange] = useState('24');
  const [analyticsData, setAnalyticsData] = useState([]);

  const locations = ['all', ...new Set(trafficData.map(item => item.location))];

  useEffect(() => {
    loadAnalyticsData();
  }, [selectedLocation, timeRange]);

  const loadAnalyticsData = async () => {
    if (selectedLocation === 'all') {
      setAnalyticsData(trafficData);
    } else {
      const data = await getTrafficHistory(selectedLocation, parseInt(timeRange));
      setAnalyticsData(data);
    }
  };

  // Process data for different chart types
  const hourlyData = processHourlyData(analyticsData);
  const congestionData = processCongestionData(analyticsData);
  const vehicleTypeData = processVehicleTypeData(analyticsData);

  const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <div className="flex items-center space-x-4">
          <select
            value={selectedLocation}
            onChange={(e) => setSelectedLocation(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="all">All Locations</option>
            {locations.slice(1).map(location => (
              <option key={location} value={location}>{location}</option>
            ))}
          </select>
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="1">Last Hour</option>
            <option value="24">Last 24 Hours</option>
            <option value="168">Last Week</option>
          </select>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Hourly Traffic Pattern */}
          <div className="traffic-card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <TrendingUp className="h-5 w-5 mr-2" />
              Hourly Traffic Pattern
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={hourlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="hour" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="vehicles" fill="#3B82F6" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Congestion Trends */}
          <div className="traffic-card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <AlertTriangle className="h-5 w-5 mr-2" />
              Congestion Trends
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={congestionData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis domain={[0, 100]} />
                <Tooltip formatter={(value) => [`${value}%`, 'Congestion']} />
                <Line type="monotone" dataKey="congestion" stroke="#F59E0B" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Vehicle Type Distribution */}
          <div className="traffic-card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <Car className="h-5 w-5 mr-2" />
              Vehicle Type Distribution
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={vehicleTypeData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {vehicleTypeData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>

          {/* Summary Statistics */}
          <div className="traffic-card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Summary Statistics</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-4 bg-blue-50 rounded-lg">
                  <p className="text-2xl font-bold text-blue-600">
                    {analyticsData.reduce((sum, item) => sum + item.vehicle_counts.total, 0)}
                  </p>
                  <p className="text-sm text-gray-600">Total Vehicles</p>
                </div>
                <div className="text-center p-4 bg-yellow-50 rounded-lg">
                  <p className="text-2xl font-bold text-yellow-600">
                    {analyticsData.length > 0 
                      ? (analyticsData.reduce((sum, item) => sum + item.congestion_score, 0) / analyticsData.length * 100).toFixed(1)
                      : 0}%
                  </p>
                  <p className="text-sm text-gray-600">Avg Congestion</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-4 bg-green-50 rounded-lg">
                  <p className="text-2xl font-bold text-green-600">
                    {analyticsData.length > 0
                      ? (analyticsData.reduce((sum, item) => sum + item.clearance_time_minutes, 0) / analyticsData.length).toFixed(0)
                      : 0}
                  </p>
                  <p className="text-sm text-gray-600">Avg Clearance (min)</p>
                </div>
                <div className="text-center p-4 bg-red-50 rounded-lg">
                  <p className="text-2xl font-bold text-red-600">
                    {analyticsData.filter(item => item.ambulance_detected).length}
                  </p>
                  <p className="text-sm text-gray-600">Ambulance Alerts</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// Helper functions for data processing
const processHourlyData = (data) => {
  const hourly = {};
  data.forEach(item => {
    const hour = new Date(item.timestamp).getHours();
    if (!hourly[hour]) {
      hourly[hour] = { hour: `${hour}:00`, vehicles: 0, count: 0 };
    }
    hourly[hour].vehicles += item.vehicle_counts.total;
    hourly[hour].count += 1;
  });
  
  return Object.values(hourly).map(h => ({
    ...h,
    vehicles: Math.round(h.vehicles / h.count)
  })).sort((a, b) => a.hour.localeCompare(b.hour));
};

const processCongestionData = (data) => {
  return data.slice(0, 20).map(item => ({
    time: new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    congestion: (item.congestion_score * 100).toFixed(1)
  }));
};

const processVehicleTypeData = (data) => {
  if (data.length === 0) return [];
  
  const totals = data.reduce((acc, item) => {
    acc.cars += item.vehicle_counts.cars;
    acc.trucks += item.vehicle_counts.trucks;
    acc.buses += item.vehicle_counts.buses;
    acc.bikes += item.vehicle_counts.bikes;
    acc.ambulances += item.vehicle_counts.ambulances;
    return acc;
  }, { cars: 0, trucks: 0, buses: 0, bikes: 0, ambulances: 0 });

  return Object.entries(totals)
    .filter(([_, value]) => value > 0)
    .map(([name, value]) => ({ name: name.charAt(0).toUpperCase() + name.slice(1), value }));
};

export default Analytics;
