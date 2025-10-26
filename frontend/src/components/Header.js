import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Car, Upload, BarChart3, Bell } from 'lucide-react';

const Header = () => {
  const location = useLocation();

  const navItems = [
    { path: '/', label: 'Dashboard', icon: Car },
    { path: '/upload', label: 'Upload', icon: Upload },
    { path: '/analytics', label: 'Analytics', icon: BarChart3 },
    { path: '/alerts', label: 'Alerts', icon: Bell }
  ];

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-4">
            <Car className="h-8 w-8 text-blue-600" />
            <h1 className="text-xl font-bold text-gray-900">
              Traffic Prediction System
            </h1>
          </div>
          
          <nav className="flex space-x-8">
            {navItems.map(({ path, label, icon: Icon }) => (
              <Link
                key={path}
                to={path}
                className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  location.pathname === path
                    ? 'bg-blue-100 text-blue-700'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                }`}
              >
                <Icon className="h-4 w-4" />
                <span>{label}</span>
              </Link>
            ))}
          </nav>
        </div>
      </div>
    </header>
  );
};

export default Header;
