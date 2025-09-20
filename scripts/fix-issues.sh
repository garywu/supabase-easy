#!/bin/bash
# Apply all critical fixes to Supabase setup

set -e

PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🔧 Applying critical fixes..."

# Fix 1: Create vector.yml as FILE not directory
echo "  Fix 1: Vector configuration"
# Remove any existing directory that Docker might have created
if [ -d "volumes/logs/vector.yml" ]; then
    echo "    Removing incorrectly created vector.yml directory..."
    rm -rf volumes/logs/vector.yml
fi
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

# Fix 2: Generate real Logflare tokens
echo "  Fix 2: Generating secure tokens"
LOGFLARE_PUBLIC=$(openssl rand -hex 32)
LOGFLARE_PRIVATE=$(openssl rand -hex 32)

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/your-super-secret-and-long-logflare-key-public/$LOGFLARE_PUBLIC/g" .env
    sed -i '' "s/your-super-secret-and-long-logflare-key-private/$LOGFLARE_PRIVATE/g" .env
else
    sed -i "s/your-super-secret-and-long-logflare-key-public/$LOGFLARE_PUBLIC/g" .env
    sed -i "s/your-super-secret-and-long-logflare-key-private/$LOGFLARE_PRIVATE/g" .env
fi

# Fix 3: Add missing POSTGRES_USER
echo "  Fix 3: Database configuration"
if ! grep -q "POSTGRES_USER=" .env; then
    echo "POSTGRES_USER=postgres" >> .env
fi

# Fix 4: Ensure _supabase.sql is executable
echo "  Fix 4: Database initialization"
chmod +x volumes/db/*.sql 2>/dev/null || true

# Fix 5: Create required directories
echo "  Fix 5: Directory structure"
mkdir -p volumes/storage
mkdir -p volumes/db/data
mkdir -p volumes/functions

# Fix 6: Remove vector dependency from db service to avoid startup issues
echo "  Fix 6: Service dependencies"
# Remove the vector dependency from db service
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Use perl for more complex multi-line sed on macOS
    perl -i -0pe 's/(db:\s+[^}]*?)depends_on:\s+vector:\s+condition:\s+service_healthy/$1/gs' docker-compose.yml
else
    # Use sed with pattern range on Linux
    sed -i '/^  db:/,/^  [^ ]/{/depends_on:/,/condition: service_healthy/d}' docker-compose.yml
fi

# Fix 7: Ensure analytics can run migrations
echo "  Fix 7: Analytics configuration"
# Add RUN_MIGRATIONS environment variable for analytics
if ! grep -q "RUN_MIGRATIONS:" docker-compose.yml; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/LOGFLARE_MIN_CLUSTER_SIZE:/a\
      RUN_MIGRATIONS: true' docker-compose.yml
    else
        sed -i '/LOGFLARE_MIN_CLUSTER_SIZE:/a\      RUN_MIGRATIONS: true' docker-compose.yml
    fi
fi

# Fix 8: Fix vector mount issue - use a different path
echo "  Fix 8: Vector mount workaround"
# Change vector mount to use config.yml instead of vector.yml to avoid docker directory issue
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's|./volumes/logs/vector.yml:/etc/vector/vector.yml:ro,z|./volumes/logs/config.yml:/etc/vector/vector.yml:ro,z|' docker-compose.yml
else
    sed -i 's|./volumes/logs/vector.yml:/etc/vector/vector.yml:ro,z|./volumes/logs/config.yml:/etc/vector/vector.yml:ro,z|' docker-compose.yml
fi
# Copy vector.yml to config.yml
cp volumes/logs/vector.yml volumes/logs/config.yml

echo "✅ All fixes applied"