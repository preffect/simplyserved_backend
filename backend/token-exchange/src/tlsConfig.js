const fs = require('fs');
const path = require('path');
const https = require('https');

/**
 * Configure TLS/SSL for the Express application
 * @param {Object} app - Express application instance
 * @param {number} port - Port to listen on
 * @returns {Object} HTTPS server instance
 */
function configureTLS(app, port) {
  // Default certificate paths
  const certPath = process.env.CERT_PATH || './local/certs/fullchain.pem';
  const keyPath = process.env.KEY_PATH || './local/certs/privkey.pem';
  
  // Check if certificates exist
  try {
    if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
      console.warn('SSL certificates not found. Server will run in HTTP mode.');
      console.warn(`Expected certificates at: ${certPath} and ${keyPath}`);
      console.warn('Run ./scripts/generate_certificate.sh to create certificates.');
      
      // Start server without TLS
      return app.listen(port, '0.0.0.0', () => {
        console.log(`Express with PostGraphile server running on HTTP port ${port}`);
      });
    }
    
    // SSL options
    const options = {
      cert: fs.readFileSync(certPath),
      key: fs.readFileSync(keyPath),
    };
    
    // Create HTTPS server
    const server = https.createServer(options, app);
    
    // Start server with TLS
    server.listen(port, '0.0.0.0', () => {
      console.log(`Express with PostGraphile server running on HTTPS port ${port}`);
    });
    
    return server;
  } catch (error) {
    console.error('Error setting up TLS:', error);
    console.warn('Falling back to HTTP mode');
    
    // Start server without TLS as fallback
    return app.listen(port, '0.0.0.0', () => {
      console.log(`Express with PostGraphile server running on HTTP port ${port} (TLS setup failed)`);
    });
  }
}

module.exports = {
  configureTLS
};
