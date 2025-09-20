#!/bin/bash
# Download only required Supabase files (~100KB instead of 350MB)

set -e

CACHE_DIR=${1:-cache}
GITHUB_RAW="https://raw.githubusercontent.com/supabase/supabase/master/docker"

echo "📥 Downloading Supabase Docker files..."

# Create cache structure
mkdir -p "$CACHE_DIR/docker/volumes/db/init"
mkdir -p "$CACHE_DIR/docker/volumes/api"
mkdir -p "$CACHE_DIR/docker/volumes/logs"
mkdir -p "$CACHE_DIR/docker/volumes/pooler"
mkdir -p "$CACHE_DIR/docker/volumes/functions/main"
mkdir -p "$CACHE_DIR/docker/volumes/functions/hello"

# Core files
echo "  • docker-compose.yml"
curl -sL "$GITHUB_RAW/docker-compose.yml" -o "$CACHE_DIR/docker/docker-compose.yml"

echo "  • .env.example"
curl -sL "$GITHUB_RAW/.env.example" -o "$CACHE_DIR/docker/.env.example"

# Database initialization scripts
echo "  • Database scripts"
curl -sL "$GITHUB_RAW/volumes/db/_supabase.sql" -o "$CACHE_DIR/docker/volumes/db/_supabase.sql"
curl -sL "$GITHUB_RAW/volumes/db/roles.sql" -o "$CACHE_DIR/docker/volumes/db/roles.sql"
curl -sL "$GITHUB_RAW/volumes/db/realtime.sql" -o "$CACHE_DIR/docker/volumes/db/realtime.sql"
curl -sL "$GITHUB_RAW/volumes/db/webhooks.sql" -o "$CACHE_DIR/docker/volumes/db/webhooks.sql"
curl -sL "$GITHUB_RAW/volumes/db/logs.sql" -o "$CACHE_DIR/docker/volumes/db/logs.sql"
curl -sL "$GITHUB_RAW/volumes/db/pooler.sql" -o "$CACHE_DIR/docker/volumes/db/pooler.sql"
curl -sL "$GITHUB_RAW/volumes/db/jwt.sql" -o "$CACHE_DIR/docker/volumes/db/jwt.sql"
curl -sL "$GITHUB_RAW/volumes/db/init/data.sql" -o "$CACHE_DIR/docker/volumes/db/init/data.sql"

# Service configurations
echo "  • Service configs"
curl -sL "$GITHUB_RAW/volumes/api/kong.yml" -o "$CACHE_DIR/docker/volumes/api/kong.yml"
curl -sL "$GITHUB_RAW/volumes/pooler/pooler.exs" -o "$CACHE_DIR/docker/volumes/pooler/pooler.exs"

# Function examples (optional but expected)
echo "  • Function templates"
curl -sL "$GITHUB_RAW/volumes/functions/main/index.ts" -o "$CACHE_DIR/docker/volumes/functions/main/index.ts" 2>/dev/null || echo "// Main function" > "$CACHE_DIR/docker/volumes/functions/main/index.ts"
curl -sL "$GITHUB_RAW/volumes/functions/hello/index.ts" -o "$CACHE_DIR/docker/volumes/functions/hello/index.ts" 2>/dev/null || echo "// Hello function" > "$CACHE_DIR/docker/volumes/functions/hello/index.ts"

# Create timestamp
date > "$CACHE_DIR/.downloaded"

echo "✅ Downloaded $(find $CACHE_DIR -type f | wc -l | tr -d ' ') files"