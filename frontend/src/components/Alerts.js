import React from 'react';
import { useTraffic } from '../context/TrafficContext';
import { AlertTriangle, Ambulance, Clock, MapPin, X } from 'lucide-react';

const Alerts = () => {
  const { alerts, dismissAlert } = useTraffic();

  const getAlertIcon = (type) => {
    switch (type) {
      case 'HIGH_PRIORITY':
        return <Ambulance className="h-6 w-6 text-red-600" />;
      case 'TRAFFIC_CONGESTION':
        return <AlertTriangle className="h-6 w-6 text-yellow-600" />;
      default:
        return <AlertTriangle className="h-6 w-6 text-gray-600" />;
    }
  };

  const getAlertColor = (type) => {
    switch (type) {
      case 'HIGH_PRIORITY':
        return 'border-red-300 bg-red-50';
      case 'TRAFFIC_CONGESTION':
        return 'border-yellow-300 bg-yellow-50';
      default:
        return 'border-gray-300 bg-gray-50';
    }
  };

  const getSeverityBadge = (type) => {
    switch (type) {
      case 'HIGH_PRIORITY':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            High Priority
          </span>
        );
      case 'TRAFFIC_CONGESTION':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
            Traffic Alert
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
            Info
          </span>
        );
    }
  };

  const formatTimestamp = (timestamp) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffInMinutes = Math.floor((now - date) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes} minute${diffInMinutes > 1 ? 's' : ''} ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)} hour${Math.floor(diffInMinutes / 60) > 1 ? 's' : ''} ago`;
    return date.toLocaleString();
  };

  const sortedAlerts = [...alerts].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Traffic Alerts</h1>
        <div className="text-sm text-gray-500">
          {alerts.length} active alert{alerts.length !== 1 ? 's' : ''}
        </div>
      </div>

      {alerts.length === 0 ? (
        <div className="text-center py-12">
          <div className="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-4">
            <AlertTriangle className="h-12 w-12 text-green-600" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">All Clear!</h3>
          <p className="text-gray-500">No active traffic alerts at this time.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {sortedAlerts.map((alert) => (
            <div
              key={alert.id}
              className={`border rounded-lg p-6 ${getAlertColor(alert.type)} transition-all hover:shadow-md`}
            >
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  {getAlertIcon(alert.type)}
                </div>
                <div className="ml-4 flex-1">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center space-x-3 mb-2">
                        {getSeverityBadge(alert.type)}
                        <div className="flex items-center text-sm text-gray-500">
                          <Clock className="h-4 w-4 mr-1" />
                          {formatTimestamp(alert.timestamp)}
                        </div>
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 mb-2">
                        {alert.type === 'HIGH_PRIORITY' ? 'High Priority Alert' : 'Traffic Alert'}
                      </h3>
                      <p className="text-gray-700 mb-3">
                        {alert.message}
                      </p>
                      <div className="flex items-center text-sm text-gray-600">
                        <MapPin className="h-4 w-4 mr-1" />
                        {alert.location}
                      </div>
                    </div>
                    <button
                      onClick={() => dismissAlert(alert.id)}
                      className="flex-shrink-0 ml-4 p-1 text-gray-400 hover:text-gray-600 transition-colors"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Alert Statistics */}
      {alerts.length > 0 && (
        <div className="traffic-card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Alert Statistics</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 bg-red-50 rounded-lg">
              <p className="text-2xl font-bold text-red-600">
                {alerts.filter(alert => alert.type === 'HIGH_PRIORITY').length}
              </p>
              <p className="text-sm text-gray-600">High Priority</p>
            </div>
            <div className="text-center p-4 bg-yellow-50 rounded-lg">
              <p className="text-2xl font-bold text-yellow-600">
                {alerts.filter(alert => alert.type === 'TRAFFIC_CONGESTION').length}
              </p>
              <p className="text-sm text-gray-600">Traffic Congestion</p>
            </div>
            <div className="text-center p-4 bg-blue-50 rounded-lg">
              <p className="text-2xl font-bold text-blue-600">
                {alerts.length}
              </p>
              <p className="text-sm text-gray-600">Total Alerts</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Alerts;
