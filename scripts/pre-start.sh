#!/bin/bash
# Ensure vector.yml exists as a file before Docker starts
# This prevents Docker from creating it as a directory

PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>"
    exit 1
fi

cd "$PROJECT_DIR"

# If vector.yml exists as a directory, remove it
if [ -d "volumes/logs/vector.yml" ]; then
    echo "  Removing incorrectly created vector.yml directory..."
    rm -rf volumes/logs/vector.yml
fi

# Ensure vector.yml exists as a file
if [ ! -f "volumes/logs/vector.yml" ]; then
    echo "  Creating vector.yml file..."
    mkdir -p volumes/logs
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
fi

# Also create config.yml as a workaround for Docker mount issue
cp volumes/logs/vector.yml volumes/logs/config.yml

echo "  Vector configuration ready"