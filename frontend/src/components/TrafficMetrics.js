import React from 'react';
import { Car, Truck, Bus, Bike, Ambulance, Clock, AlertTriangle } from 'lucide-react';

const TrafficMetrics = ({ data }) => {
  // Calculate aggregate metrics
  const totalVehicles = data.reduce((sum, item) => sum + item.vehicle_counts.total, 0);
  const avgCongestion = data.length > 0 
    ? data.reduce((sum, item) => sum + item.congestion_score, 0) / data.length 
    : 0;
  const avgClearanceTime = data.length > 0
    ? data.reduce((sum, item) => sum + item.clearance_time_minutes, 0) / data.length
    : 0;
  const ambulanceCount = data.filter(item => item.ambulance_detected).length;
  const highCongestionCount = data.filter(item => item.congestion_score > 0.7).length;

  const metrics = [
    {
      label: 'Total Vehicles',
      value: totalVehicles,
      icon: Car,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100'
    },
    {
      label: 'Avg Congestion',
      value: `${(avgCongestion * 100).toFixed(1)}%`,
      icon: AlertTriangle,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100'
    },
    {
      label: 'Avg Clearance Time',
      value: `${avgClearanceTime.toFixed(0)} min`,
      icon: Clock,
      color: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    {
      label: 'Ambulance Alerts',
      value: ambulanceCount,
      icon: Ambulance,
      color: 'text-red-600',
      bgColor: 'bg-red-100'
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {metrics.map((metric, index) => {
        const Icon = metric.icon;
        return (
          <div key={index} className="traffic-card">
            <div className="flex items-center">
              <div className={`p-3 rounded-full ${metric.bgColor}`}>
                <Icon className={`h-6 w-6 ${metric.color}`} />
              </div>
              <div className="ml-4">
                <p className="traffic-label">{metric.label}</p>
                <p className="traffic-metric">{metric.value}</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default TrafficMetrics;
