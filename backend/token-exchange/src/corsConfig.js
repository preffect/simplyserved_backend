const cors = require('cors');

// Configure CORS for specific origin
const corsOptions = {
  origin: [
    'https://simplyserved.app',
    'http://localhost:3000',
    'http://localhost:5000',
    'https://simplyserved.app:5001',
    'http://conan-devbox3.westus3.cloudapp.azure.com:3000',
    'http://conan-devbox3.westus3.cloudapp.azure.com',
  ],
  methods: ['GET', 'POST', 'HEAD', 'OPTIONS'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Accept',
    'Authorization',
    'Content-Type',
    'Content-Length',
  ],
  credentials: true,
  exposedHeaders: ['']
};

// Create middleware function
const corsMiddleware = cors(corsOptions);

module.exports = {
  corsMiddleware,
  corsOptions
};
