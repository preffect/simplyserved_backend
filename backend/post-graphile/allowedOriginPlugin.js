/**
 * This server plugin injects CORS headers to allow requests only from a specific origin.
 */

function makeAllowedOriginTweak(origin) {
  console.log("CORS headers set!!!!!!!!!!!!!!!!!!!!", origin);
  return {
    ["postgraphile:http:handler"](req, { res }) {
      console.log("RETURN!!!!!!!!!!!!!!!!!!!!!!!1", origin);
      res.setHeader("Access-Control-Allow-Origin", origin);
      res.setHeader("Access-Control-Allow-Methods", "HEAD, GET, POST");
      res.setHeader(
        "Access-Control-Allow-Headers",
        [
          "Origin",
          "X-Requested-With",
          // Used by `express-graphql` to determine whether to expose the GraphiQL
          // interface (`text/html`) or not.
          "Accept",
          // Used by PostGraphile for auth purposes.
          "Authorization",
          // Used by GraphQL Playground and other Apollo-enabled servers
          "X-Apollo-Tracing",
          // The `Content-*` headers are used when making requests with a body,
          // like in a POST request.
          "Content-Type",
          "Content-Length",
          // For our 'Explain' feature
          "X-PostGraphile-Explain",
        ].join(", ")
      );
      res.setHeader(
        "Access-Control-Expose-Headers",
        ["X-GraphQL-Event-Stream"].join(", ")
      );
      return req;
    },
  };
}
// module.exports("http://conan-devbox3.westus3.cloudapp.azure.com");
// module.exports("http://conan-devbox3.westus3.cloudapp.azure.com:5000");
// module.exports("http://conan-devbox3.westus3.cloudapp.azure.com:80");
const allowedOriginPlugin = function() {
  makeAllowedOriginTweak("http://conan-devbox3.westus3.cloudapp.azure.com");
};
module.exports = allowedOriginPlugin;