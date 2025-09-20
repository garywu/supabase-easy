#!/bin/bash

# Download required SQL init scripts from Supabase repository FIRST
echo "📥 Downloading required SQL scripts..."

# We need ALL the initialization files, not just some
BASE_URL="https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes"

mkdir -p volumes/db
mkdir -p volumes/storage
mkdir -p volumes/functions

# Download database init files
echo "Downloading database initialization files..."
files=(
    "db/realtime.sql"
    "db/webhooks.sql" 
    "db/roles.sql"
    "db/jwt.sql"
    "db/_supabase.sql"
    "db/logs.sql"
    "db/pooler.sql"
)

for file in "${files[@]}"; do
    if [ ! -f "volumes/$file" ]; then
        echo "  Downloading $file..."
        curl -sL "$BASE_URL/$file" -o "volumes/$file" 2>/dev/null || echo "  Warning: Could not download $file"
    fi
done

# Also need to get the complete init schema files
echo "Downloading complete database schemas..."
INIT_URL="https://raw.githubusercontent.com/supabase/postgres/develop/migrations/db/init-scripts"
curl -sL "$INIT_URL/00-initial-schema.sql" -o "volumes/db/00-initial-schema.sql" 2>/dev/null || true
curl -sL "$INIT_URL/01-auth-schema.sql" -o "volumes/db/01-auth-schema.sql" 2>/dev/null || true

echo "✅ SQL scripts downloaded"

# Now run the installer
./install.sh