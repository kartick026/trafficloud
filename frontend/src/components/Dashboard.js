import React from 'react';
import { useTraffic } from '../context/TrafficContext';
import TrafficMetrics from './TrafficMetrics';
import RecentAnalyses from './RecentAnalyses';
import AlertsOverview from './AlertsOverview';
import TrafficChart from './TrafficChart';

const Dashboard = () => {
  const { trafficData, alerts, loading } = useTraffic();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Traffic Dashboard</h1>
        <div className="text-sm text-gray-500">
          Last updated: {new Date().toLocaleString()}
        </div>
      </div>

      {/* Key Metrics */}
      <TrafficMetrics data={trafficData} />

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <TrafficChart data={trafficData} />
        <AlertsOverview alerts={alerts} />
      </div>

      {/* Recent Analyses */}
      <RecentAnalyses data={trafficData} />
    </div>
  );
};

export default Dashboard;
