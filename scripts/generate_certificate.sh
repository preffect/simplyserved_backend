#!/bin/bash

# Script to generate Let's Encrypt SSL certificate for simplyserved.app
# Certificates will be stored in /home/azureuser/source/local/certs/

set -e

DOMAIN="simplyserved.app"
EMAIL="admin@simplyserved.app"  # Replace with your email
CERT_DIR="/home/azureuser/source/local/certs"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
  echo "Certbot not found. Installing..."
  apt-get update
  apt-get install -y software-properties-common
  add-apt-repository -y universe
  add-apt-repository -y ppa:certbot/certbot
  apt-get update
  apt-get install -y certbot
fi

# Create certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if certificates already exist
if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
  echo "Certificates already exist in $CERT_DIR"
  read -p "Do you want to renew them? (y/n): " RENEW
  if [ "$RENEW" != "y" ]; then
    echo "Exiting without changes."
    exit 0
  fi
fi

# Generate certificates using standalone mode
# This requires port 80 to be available
echo "Generating certificates for $DOMAIN..."
certbot certonly --standalone \
  --agree-tos \
  --non-interactive \
  --domain "$DOMAIN" \
  --email "$EMAIL" \
  --cert-path "$CERT_DIR/cert.pem" \
  --fullchain-path "$CERT_DIR/fullchain.pem" \
  --chain-path "$CERT_DIR/chain.pem" \
  --key-path "$CERT_DIR/privkey.pem"

# Set proper permissions
chmod 600 "$CERT_DIR/privkey.pem"
chmod 644 "$CERT_DIR/fullchain.pem"
chmod 644 "$CERT_DIR/chain.pem"
chmod 644 "$CERT_DIR/cert.pem"

echo "Certificate generation complete!"
echo "Certificates stored in: $CERT_DIR"
echo ""
echo "To use these certificates with your application:"
echo "1. Make sure your application loads them from $CERT_DIR"
echo "2. Set up a cron job to renew certificates before they expire:"
echo "   0 0 1 * * root certbot renew --quiet --cert-path $CERT_DIR/cert.pem --fullchain-path $CERT_DIR/fullchain.pem --chain-path $CERT_DIR/chain.pem --key-path $CERT_DIR/privkey.pem"

exit 0
