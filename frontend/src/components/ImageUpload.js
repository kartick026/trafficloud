import React, { useState } from 'react';
import { useDropzone } from 'react-dropzone';
import { useTraffic } from '../context/TrafficContext';
import { Upload, MapPin, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const ImageUpload = () => {
  const { uploadImage, loading } = useTraffic();
  const [location, setLocation] = useState('');
  const [uploadedFile, setUploadedFile] = useState(null);
  const [preview, setPreview] = useState(null);

  const onDrop = (acceptedFiles) => {
    const file = acceptedFiles[0];
    if (file) {
      setUploadedFile(file);
      const reader = new FileReader();
      reader.onload = () => setPreview(reader.result);
      reader.readAsDataURL(file);
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.gif', '.bmp']
    },
    maxFiles: 1
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!uploadedFile) {
      toast.error('Please select an image file');
      return;
    }
    
    if (!location.trim()) {
      toast.error('Please enter a location');
      return;
    }

    try {
      await uploadImage(uploadedFile, location.trim());
      toast.success('Image uploaded and analysis started!');
      setUploadedFile(null);
      setPreview(null);
      setLocation('');
    } catch (error) {
      toast.error('Upload failed: ' + error.message);
    }
  };

  const clearUpload = () => {
    setUploadedFile(null);
    setPreview(null);
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Upload Traffic Image</h1>
        <p className="text-gray-600">
          Upload a traffic image for real-time analysis and congestion prediction
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Location Input */}
        <div>
          <label htmlFor="location" className="block text-sm font-medium text-gray-700 mb-2">
            <MapPin className="inline h-4 w-4 mr-1" />
            Location
          </label>
          <input
            type="text"
            id="location"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="e.g., Main Street Junction, Highway 101"
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            required
          />
        </div>

        {/* Image Upload Area */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Traffic Image
          </label>
          <div
            {...getRootProps()}
            className={`upload-zone ${isDragActive ? 'active' : ''} ${
              uploadedFile ? 'border-green-400 bg-green-50' : ''
            }`}
          >
            <input {...getInputProps()} />
            {preview ? (
              <div className="space-y-4">
                <img
                  src={preview}
                  alt="Preview"
                  className="max-h-64 mx-auto rounded-lg shadow-md"
                />
                <div className="flex items-center justify-center space-x-4">
                  <button
                    type="button"
                    onClick={clearUpload}
                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                  >
                    Remove
                  </button>
                </div>
              </div>
            ) : (
              <div className="text-center">
                <Upload className="mx-auto h-12 w-12 text-gray-400" />
                <p className="mt-2 text-sm text-gray-600">
                  {isDragActive
                    ? 'Drop the image here...'
                    : 'Drag & drop an image here, or click to select'}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  Supports: JPG, PNG, GIF, BMP
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Upload Button */}
        <div className="flex items-center justify-between">
          <div className="flex items-center text-sm text-gray-500">
            <AlertCircle className="h-4 w-4 mr-1" />
            <span>Analysis typically takes 10-30 seconds</span>
          </div>
          <button
            type="submit"
            disabled={!uploadedFile || !location.trim() || loading}
            className="px-6 py-2 bg-blue-600 text-white font-medium rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
          >
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Analyzing...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload & Analyze
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ImageUpload;
