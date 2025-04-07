/**
 * Express middleware to set CORS headers for specific origins
 */
function allowedOriginPlugin() {
  const origin = "http://conan-devbox3.westus3.cloudapp.azure.com";
  
  return function(req, res, next) {
    console.log("Setting CORS headers for:", origin);
    
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Access-Control-Allow-Methods", "HEAD, GET, POST");
    res.setHeader(
      "Access-Control-Allow-Headers",
      [
        "Origin",
        "X-Requested-With",
        "Accept",
        "Authorization",
        "X-Apollo-Tracing",
        "Content-Type",
        "Content-Length",
        "X-PostGraphile-Explain",
      ].join(", ")
    );
    res.setHeader(
      "Access-Control-Expose-Headers",
      ["X-GraphQL-Event-Stream"].join(", ")
    );
    
    next();
  };
}

module.exports = allowedOriginPlugin;
