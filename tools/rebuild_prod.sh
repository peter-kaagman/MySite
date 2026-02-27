#!/bin/bash
# Rebuild alleen de MySite-container, of met --all alle containers, met de production compose file

set -e

cd "$(dirname "$0")/.."  # Ga naar project root

if [ ! -f docker-compose.prod.yml ]; then
  echo "docker-compose.prod.yml not found in project root."
  exit 1
fi

if [ "$1" == "--all" ]; then
  echo "Rebuilding ALL containers..."
  docker compose -f docker-compose.prod.yml down
  docker compose -f docker-compose.prod.yml build
  docker compose -f docker-compose.prod.yml up -d
  echo "Rebuild complete (alle containers)."
else
  echo "Building MySite image..."
  docker compose -f docker-compose.prod.yml build mysite
  echo "Restarting MySite container..."
  docker compose -f docker-compose.prod.yml up -d mysite
  echo "Rebuild complete (alleen MySite)."
fi
