#!/bin/bash
set -e

# Make sure scripts are executable
chmod +x /app/scripts/*.sh

# Execute the command passed to docker run
exec "$@"
