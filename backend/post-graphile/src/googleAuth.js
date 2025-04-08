const {OAuth2Client} = require('google-auth-library');

/**
 * Verifies a Google ID token
 * @param {string} token - The ID token to verify
 * @returns {Promise<Object>} - The decoded token payload
 */
async function verifyGoogleToken(token) {
  const client = new OAuth2Client();
  const ticket = await client.verifyIdToken({
    idToken: token,
    audience: "413215377675-cc4qoe522uf7ge33ss1rfp9mkni1lihs.apps.googleusercontent.com",
    // Or, if multiple clients access the backend:
    //[WEB_CLIENT_ID_1, WEB_CLIENT_ID_2, WEB_CLIENT_ID_3]
  });
  
  const payload = ticket.getPayload();
  return payload;
}

/**
 * Express middleware for Google JWT authentication
 */
function googleAuthMiddleware(req, res, next) {
  const authHeader = req.headers["authorization"];
  if (!authHeader) return next(); // No token provided

  const token = authHeader.split(" ")[1]; // Extract Bearer token
  
  verifyGoogleToken(token)
    .then(decoded => {
      console.log("Decoded JWT:", decoded);
      req.jwtClaims = decoded; // Attach decoded claims to request object
      next();
    })
    .catch(err => {
      console.error("Invalid JWT:", err);
      res.status(401).send("Unauthorized");
    });
}

module.exports = {
  verifyGoogleToken,
  googleAuthMiddleware
};
