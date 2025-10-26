import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';

const TrafficChart = ({ data }) => {
  // Process data for charts
  const chartData = data.slice(0, 10).map((item, index) => ({
    time: new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    vehicles: item.vehicle_counts.total,
    congestion: (item.congestion_score * 100).toFixed(1),
    clearance: item.clearance_time_minutes
  })).reverse();

  const vehicleTypeData = data.length > 0 ? [
    { name: 'Cars', value: data[0].vehicle_counts.cars },
    { name: 'Trucks', value: data[0].vehicle_counts.trucks },
    { name: 'Buses', value: data[0].vehicle_counts.buses },
    { name: 'Bikes', value: data[0].vehicle_counts.bikes },
    { name: 'Ambulances', value: data[0].vehicle_counts.ambulances }
  ] : [];

  return (
    <div className="traffic-card">
      <h2 className="text-xl font-semibold text-gray-900 mb-4">Traffic Trends</h2>
      
      {data.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <p>No data available for charting</p>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Vehicle Count Over Time */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2">Vehicle Count Over Time</h3>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis />
                <Tooltip />
                <Line 
                  type="monotone" 
                  dataKey="vehicles" 
                  stroke="#3B82F6" 
                  strokeWidth={2}
                  dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Congestion Score Over Time */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2">Congestion Score Over Time</h3>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis domain={[0, 100]} />
                <Tooltip formatter={(value) => [`${value}%`, 'Congestion']} />
                <Line 
                  type="monotone" 
                  dataKey="congestion" 
                  stroke="#F59E0B" 
                  strokeWidth={2}
                  dot={{ fill: '#F59E0B', strokeWidth: 2, r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Vehicle Type Distribution */}
          {vehicleTypeData.some(item => item.value > 0) && (
            <div>
              <h3 className="text-sm font-medium text-gray-700 mb-2">Vehicle Type Distribution</h3>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={vehicleTypeData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="value" fill="#10B981" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default TrafficChart;
