import React from 'react';
import { Clock, MapPin, Car, AlertTriangle, Ambulance } from 'lucide-react';

const RecentAnalyses = ({ data }) => {
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const getCongestionColor = (score) => {
    if (score > 0.7) return 'text-red-600 bg-red-100';
    if (score > 0.4) return 'text-yellow-600 bg-yellow-100';
    return 'text-green-600 bg-green-100';
  };

  const getCongestionLabel = (score) => {
    if (score > 0.7) return 'High';
    if (score > 0.4) return 'Medium';
    return 'Low';
  };

  return (
    <div className="traffic-card">
      <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Analyses</h2>
      
      {data.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <Car className="mx-auto h-12 w-12 text-gray-300 mb-4" />
          <p>No traffic analyses yet</p>
          <p className="text-sm">Upload an image to get started</p>
        </div>
      ) : (
        <div className="space-y-4">
          {data.slice(0, 10).map((analysis) => (
            <div
              key={analysis.frame_id}
              className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-2 mb-2">
                    <MapPin className="h-4 w-4 text-gray-400" />
                    <span className="font-medium text-gray-900">{analysis.location}</span>
                    {analysis.ambulance_detected && (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        <Ambulance className="h-3 w-3 mr-1" />
                        Ambulance
                      </span>
                    )}
                  </div>
                  
                  <div className="flex items-center space-x-4 text-sm text-gray-600 mb-3">
                    <div className="flex items-center">
                      <Clock className="h-4 w-4 mr-1" />
                      {formatTimestamp(analysis.timestamp)}
                    </div>
                    <div className="flex items-center">
                      <Car className="h-4 w-4 mr-1" />
                      {analysis.vehicle_counts.total} vehicles
                    </div>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <p className="text-xs text-gray-500 uppercase tracking-wide">Cars</p>
                      <p className="text-lg font-semibold text-gray-900">
                        {analysis.vehicle_counts.cars}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase tracking-wide">Trucks</p>
                      <p className="text-lg font-semibold text-gray-900">
                        {analysis.vehicle_counts.trucks}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase tracking-wide">Buses</p>
                      <p className="text-lg font-semibold text-gray-900">
                        {analysis.vehicle_counts.buses}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase tracking-wide">Bikes</p>
                      <p className="text-lg font-semibold text-gray-900">
                        {analysis.vehicle_counts.bikes}
                      </p>
                    </div>
                  </div>
                </div>

                <div className="ml-4 text-right">
                  <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getCongestionColor(analysis.congestion_score)}`}>
                    <AlertTriangle className="h-4 w-4 mr-1" />
                    {getCongestionLabel(analysis.congestion_score)} Congestion
                  </div>
                  <p className="text-sm text-gray-600 mt-2">
                    Clearance: {analysis.clearance_time_minutes} min
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default RecentAnalyses;
