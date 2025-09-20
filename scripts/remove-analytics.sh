#!/bin/bash
# Remove analytics dependencies for minimal install

PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>"
    exit 1
fi

cd "$PROJECT_DIR"

echo "📝 Removing analytics dependencies..."

# Comment out analytics service
sed -i.bak '/^  analytics:/,/^[^ ]/s/^/#/' docker-compose.yml

# Remove analytics dependencies from other services
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/analytics:/,+1d' docker-compose.yml
else
    sed -i '/analytics:/,+1d' docker-compose.yml
fi

echo "✅ Analytics dependencies removed"