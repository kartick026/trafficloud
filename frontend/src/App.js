import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import Header from './components/Header';
import Dashboard from './components/Dashboard';
import ImageUpload from './components/ImageUpload';
import Analytics from './components/Analytics';
import Alerts from './components/Alerts';
import { TrafficProvider } from './context/TrafficContext';
import './App.css';

function App() {
  return (
    <TrafficProvider>
      <Router>
        <div className="min-h-screen bg-gray-50">
          <Header />
          <main className="container mx-auto px-4 py-8">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/upload" element={<ImageUpload />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/alerts" element={<Alerts />} />
            </Routes>
          </main>
          <Toaster position="top-right" />
        </div>
      </Router>
    </TrafficProvider>
  );
}

export default App;
