import React from 'react';
import { AlertTriangle, Ambulance, Clock, X } from 'lucide-react';

const AlertsOverview = ({ alerts }) => {
  const getAlertIcon = (type) => {
    switch (type) {
      case 'HIGH_PRIORITY':
        return <Ambulance className="h-5 w-5 text-red-600" />;
      case 'TRAFFIC_CONGESTION':
        return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
      default:
        return <AlertTriangle className="h-5 w-5 text-gray-600" />;
    }
  };

  const getAlertColor = (type) => {
    switch (type) {
      case 'HIGH_PRIORITY':
        return 'border-red-200 bg-red-50';
      case 'TRAFFIC_CONGESTION':
        return 'border-yellow-200 bg-yellow-50';
      default:
        return 'border-gray-200 bg-gray-50';
    }
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  return (
    <div className="traffic-card">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold text-gray-900">Recent Alerts</h2>
        <span className="text-sm text-gray-500">
          {alerts.length} alert{alerts.length !== 1 ? 's' : ''}
        </span>
      </div>

      {alerts.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <AlertTriangle className="mx-auto h-12 w-12 text-gray-300 mb-4" />
          <p>No alerts at this time</p>
          <p className="text-sm">System is running normally</p>
        </div>
      ) : (
        <div className="space-y-3">
          {alerts.slice(0, 5).map((alert) => (
            <div
              key={alert.id}
              className={`border rounded-lg p-4 ${getAlertColor(alert.type)}`}
            >
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  {getAlertIcon(alert.type)}
                </div>
                <div className="ml-3 flex-1">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-medium text-gray-900">
                      {alert.type === 'HIGH_PRIORITY' ? 'High Priority Alert' : 'Traffic Alert'}
                    </h3>
                    <span className="text-xs text-gray-500">
                      {formatTimestamp(alert.timestamp)}
                    </span>
                  </div>
                  <p className="mt-1 text-sm text-gray-700">
                    {alert.message}
                  </p>
                  <div className="mt-2 flex items-center text-xs text-gray-500">
                    <Clock className="h-3 w-3 mr-1" />
                    {alert.location}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AlertsOverview;
