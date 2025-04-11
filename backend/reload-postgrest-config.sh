#!/bin/bash

# Script to reload PostgREST configuration by sending SIGUSR2 signal
# This avoids having to restart the container

echo "Reloading PostgREST configuration..."
docker exec postgrest-1 killall -SIGUSR2 postgrest
echo "PostgREST configuration reload signal sent."
