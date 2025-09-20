#!/bin/bash
# Verify Supabase installation is working

PROJECT_DIR=$1

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>"
    exit 1
fi

cd "$PROJECT_DIR"

echo "🔍 Verifying installation..."

# Count services
TOTAL=$(docker-compose ps 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')
HEALTHY=$(docker-compose ps 2>/dev/null | grep -c "(healthy)" || echo 0)

echo "  Services running: $TOTAL"
echo "  Healthy services: $HEALTHY"

# Test API endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "401" ]; then
    echo "  ✅ API Gateway: Working (requires auth)"
elif [ "$HTTP_STATUS" = "000" ]; then
    echo "  ⚠️  API Gateway: Not responding"
    echo "     Services may still be starting. Wait a minute and try again."
else
    echo "  ✅ API Gateway: HTTP $HTTP_STATUS"
fi

# Check critical services
echo ""
echo "Critical services status:"
docker-compose ps --format "table {{.Service}}\t{{.Status}}" 2>/dev/null | grep -E "db|kong|auth|rest" || echo "  Unable to check"