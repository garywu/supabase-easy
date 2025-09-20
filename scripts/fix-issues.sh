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

echo "✅ All fixes applied"