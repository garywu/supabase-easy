#!/bin/bash

# Download required SQL init scripts from Supabase repository
echo "📥 Downloading required SQL scripts..."

BASE_URL="https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db"

mkdir -p volumes/db

# Download SQL files
files=(
    "realtime.sql"
    "webhooks.sql"
    "roles.sql"
    "jwt.sql"
    "_supabase.sql"
    "logs.sql"
    "pooler.sql"
)

for file in "${files[@]}"; do
    if [ ! -f "volumes/db/$file" ]; then
        echo "Downloading $file..."
        curl -sL "$BASE_URL/$file" -o "volumes/db/$file"
    fi
done

echo "✅ SQL scripts downloaded"

# Now run the installer
./install.sh