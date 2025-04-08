#!/bin/bash

# Script to generate and manage JWT_SECRET
# Usage: ./manage_jwt_secret.sh [--renew]

SECRET_DIR="local/secrets"
SECRET_FILE="${SECRET_DIR}/jwt_secret"

# Create directory if it doesn't exist
mkdir -p "${SECRET_DIR}"

# Check if renewal is requested
if [[ "$1" == "--renew" ]]; then
    echo "Renewing JWT secret..."
    RENEW=true
else
    RENEW=false
fi

# Check if secret already exists
if [[ -f "${SECRET_FILE}" && "${RENEW}" == "false" ]]; then
    echo "JWT secret already exists at ${SECRET_FILE}"
    echo "Use --renew flag to generate a new secret"
    exit 0
fi

# Generate a new secret (64 random bytes, base64 encoded)
NEW_SECRET=$(openssl rand -base64 64 | tr -d '\n')

# Save the secret to file
echo "${NEW_SECRET}" > "${SECRET_FILE}"
chmod 600 "${SECRET_FILE}"

echo "JWT secret has been generated and stored at ${SECRET_FILE}"
echo "Make sure to update your application configuration to use this secret"
