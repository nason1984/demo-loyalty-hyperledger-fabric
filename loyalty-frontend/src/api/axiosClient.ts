import axios from 'axios';

const axiosClient = axios.create({
  baseURL: '/api/v1', // Use relative URL to go through nginx proxy
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
axiosClient.interceptors.request.use(
  (config) => {
    // Add auth token if available
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Add cache buster for API calls
    if (config.url) {
      const separator = config.url.includes('?') ? '&' : '?';
      config.url += `${separator}_t=${Date.now()}`;
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
axiosClient.interceptors.response.use(
  (response) => {
    return response; // Return full response, not just data
  },
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access - but don't redirect if already on login page
      const currentPath = window.location.pathname;
      if (currentPath !== '/login' && currentPath !== '/') {
        localStorage.removeItem('authToken');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default axiosClient;