const cors = require('cors');

// Configure CORS for specific origin
const corsOptions = {
  origin: 'http://conan-devbox3.westus3.cloudapp.azure.com',
  methods: ['GET', 'POST', 'HEAD'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Accept',
    'Authorization',
    'Content-Type',
    'Content-Length',
  ],
  exposedHeaders: ['']
};

// Create middleware function
const corsMiddleware = cors(corsOptions);

module.exports = {
  corsMiddleware,
  corsOptions
};
