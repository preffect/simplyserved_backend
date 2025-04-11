const cors = require('cors');

// Configure CORS for specific origin
const corsOptions = {
  origin: ['http://localhost:3000', 'http://localhost:5000', 'http://localhost:5001'],
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
