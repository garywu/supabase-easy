#!/bin/bash

echo "🚀 Starting Supabase Installation..."

# Step 1: Setup environment
if [ ! -f .env ]; then
    echo "Creating .env from template..."
    cp .env.example .env
    
    # Generate real tokens
    LOGFLARE_PUBLIC=$(openssl rand -hex 32)
    LOGFLARE_PRIVATE=$(openssl rand -hex 32)
    
    # Update tokens based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/your-super-secret-and-long-logflare-key-public/$LOGFLARE_PUBLIC/g" .env
        sed -i '' "s/your-super-secret-and-long-logflare-key-private/$LOGFLARE_PRIVATE/g" .env
    else
        # Linux
        sed -i "s/your-super-secret-and-long-logflare-key-public/$LOGFLARE_PUBLIC/g" .env
        sed -i "s/your-super-secret-and-long-logflare-key-private/$LOGFLARE_PRIVATE/g" .env
    fi
    
    # Add missing POSTGRES_USER
    echo "" >> .env
    echo "POSTGRES_USER=postgres" >> .env
fi

# Step 2: Create required directories
echo "Creating directory structure..."
mkdir -p volumes/storage
mkdir -p volumes/db/data

# Step 3: Start core services
echo "Starting database..."
docker-compose up -d db imgproxy

# Step 4: Wait for database and initialization
echo "Waiting for database to be ready..."
sleep 30
until docker exec supabase-db pg_isready -U postgres; do
    echo "Waiting for database..."
    sleep 5
done

# Give database time to fully initialize
echo "Waiting for database initialization..."
sleep 10

# Step 5: Create required databases and schemas
echo "Setting up databases and schemas..."

# First, create the required roles that should exist but don't
echo "Creating required roles..."
docker exec supabase-db psql -U postgres << 'EOF'
-- Create roles if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin LOGIN SUPERUSER CREATEDB CREATEROLE REPLICATION BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator LOGIN NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin LOGIN CREATEROLE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
    CREATE ROLE supabase_functions_admin LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dashboard_user') THEN
    CREATE ROLE dashboard_user LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pgbouncer') THEN
    CREATE ROLE pgbouncer LOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END
$$;

-- Grant necessary permissions
GRANT anon TO authenticator;
GRANT service_role TO authenticator;
GRANT authenticated TO authenticator;
GRANT dashboard_user TO postgres;
EOF

# Now create databases and schemas
docker exec supabase-db psql -U postgres -c "CREATE DATABASE _supabase;" 2>/dev/null || true

# Create schemas in main database
docker exec supabase-db psql -U postgres << 'EOF'
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS _realtime;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA _realtime TO postgres;
EOF

# Create schemas in _supabase database
docker exec supabase-db psql -U postgres -d _supabase << 'EOF'
CREATE SCHEMA IF NOT EXISTS _analytics;
CREATE SCHEMA IF NOT EXISTS _supavisor;
GRANT ALL ON SCHEMA _analytics TO supabase_admin;
GRANT ALL ON SCHEMA _supavisor TO supabase_admin;
EOF

# Step 6: Fix user passwords
echo "Configuring authentication..."
POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d '=' -f2)
docker exec supabase-db psql -U postgres -c "ALTER USER authenticator WITH PASSWORD '$POSTGRES_PASSWORD';"
docker exec supabase-db psql -U postgres -c "ALTER USER supabase_auth_admin WITH PASSWORD '$POSTGRES_PASSWORD';"
docker exec supabase-db psql -U postgres -c "ALTER USER supabase_storage_admin WITH PASSWORD '$POSTGRES_PASSWORD';"
docker exec supabase-db psql -U postgres -c "ALTER USER supabase_auth_admin SET search_path = auth, public;"

# Step 7: Start analytics
echo "Starting analytics service..."
docker-compose up -d analytics

# Step 8: Wait for analytics
echo "Waiting for analytics to be ready..."
sleep 20
until curl -s http://localhost:4000/health | grep -q "ok"; do
    echo "Waiting for analytics..."
    sleep 5
done

# Step 9: Start all services
echo "Starting all services..."
docker-compose up -d

# Step 10: Final wait
echo "Waiting for all services to initialize..."
sleep 30

# Step 11: Verify installation
echo ""
echo "✅ Installation complete!"
echo ""
echo "🎯 Service Status:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""
echo "📊 Supabase is ready!"
echo "🌐 Dashboard: http://localhost:8000"
echo "🔍 Analytics: http://localhost:4000/health"
echo ""
echo "To stop: docker-compose down"
echo "To restart: docker-compose restart"
echo "To view logs: docker-compose logs [service-name]"