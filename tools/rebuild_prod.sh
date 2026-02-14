#!/bin/bash
# Rebuild all Docker containers using the production compose file

set -e

cd "$(dirname "$0")/.."  # Go to project root

if [ ! -f docker-compose.prod.yml ]; then
  echo "docker-compose.prod.yml not found in project root."
  exit 1
fi

echo "Stopping running containers..."
docker-compose -f docker-compose.prod.yml down

echo "Building images..."
docker-compose -f docker-compose.prod.yml build

echo "Starting containers in detached mode..."
docker-compose -f docker-compose.prod.yml up -d

echo "Rebuild complete."
