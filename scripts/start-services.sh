#!/bin/bash
# Start Supabase services in the correct order with proper vector handling

set -e

PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>"
    exit 1
fi

cd "$PROJECT_DIR"

# First, ensure vector.yml file exists
echo "  Ensuring vector.yml exists as file..."
mkdir -p volumes/logs

# If vector.yml exists as directory, remove it
if [ -d "volumes/logs/vector.yml" ]; then
    rm -rf volumes/logs/vector.yml
fi

# Create vector.yml file
cat > volumes/logs/vector.yml << 'EOF'
api:
  enabled: true
  address: 0.0.0.0:9001

sources:
  docker_host:
    type: docker_logs
    exclude_containers:
      - supabase-vector

sinks:
  stdout:
    type: console
    inputs:
      - docker_host
    target: stdout
    encoding:
      codec: json
EOF

# Create override file without vector mount
cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  vector:
    volumes:
      # Temporarily use a different config location
      - ./volumes/logs/vector.yml:/tmp/vector.yml:ro,z
      - ${DOCKER_SOCKET_LOCATION}:/var/run/docker.sock:ro,z
    command: 
      [
        "--config",
        "/tmp/vector.yml"
      ]
EOF

echo "  Starting database and imgproxy..."
docker-compose up -d db imgproxy

echo "  Starting vector with override..."
docker-compose up -d vector

# Now restore normal config
rm -f docker-compose.override.yml

echo "  Services started with vector configured correctly"