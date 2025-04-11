const express = require('express');
const { googleAuthMiddleware } = require('./googleAuth.js');
const { corsMiddleware } = require('./corsConfig.js');
const { handleTokenExchange } = require('./tokenExchange.js');
const { configureTLS } = require('./tlsConfig.js');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Apply CORS middleware
app.use(corsMiddleware);

// Token exchange endpoint with Google Auth middleware
app.post('/token-exchange', googleAuthMiddleware, express.json(), handleTokenExchange);

// Start the server with TLS if certificates are available
configureTLS(app, PORT);
