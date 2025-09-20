#!/bin/bash

# Supabase Easy - Official Regression Test
# This script performs a complete zero-shot deployment test from scratch
# 
# Usage: ./tests/regression-test.sh [options]
# Options:
#   --no-cleanup    Skip cleanup prompt at the end
#   --help          Show this help message

set -e

# Parse command line arguments
NO_CLEANUP=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --help)
            echo "Supabase Easy - Official Regression Test"
            echo ""
            echo "Usage: ./tests/regression-test.sh [options]"
            echo ""
            echo "Options:"
            echo "  --no-cleanup    Skip cleanup prompt at the end"
            echo "  --help          Show this help message"
            echo ""
            echo "This test validates:"
            echo "  - Zero-shot deployment (no manual intervention)"
            echo "  - All 13 services start successfully"
            echo "  - Key endpoints respond correctly"
            echo "  - 100% success rate achievement"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🧪 SUPABASE EASY - OFFICIAL REGRESSION TEST"
echo "============================================"
echo ""

# Step 1: Clean any existing Docker resources
echo "Step 1: Cleaning Docker resources..."
docker ps -aq | xargs -r docker stop 2>/dev/null || true
docker ps -aq | xargs -r docker rm 2>/dev/null || true
docker volume prune -f > /dev/null 2>&1
docker network prune -f > /dev/null 2>&1
echo "✅ Docker cleaned"
echo ""

# Step 2: Create test directory
echo "Step 2: Creating fresh test environment..."
TEST_DIR="/tmp/supabase-easy-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "📂 Test directory: $TEST_DIR"
echo ""

# Step 3: Clone repository
echo "Step 3: Cloning repository..."
git clone https://github.com/garywu/supabase-easy.git . > /dev/null 2>&1
echo "✅ Repository cloned"
echo ""

# Step 4: Run setup
echo "Step 4: Running setup.sh..."
chmod +x setup.sh
./setup.sh
echo ""

# Step 5: Wait for stabilization
echo "Step 5: Waiting for services to stabilize..."
sleep 30
echo ""

# Step 6: Check service status
echo "Step 6: Checking service status..."
echo "========================================="
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
echo "========================================="
echo ""

# Step 7: Count working services
echo "Step 7: Counting services..."
TOTAL_SERVICES=$(docker-compose ps -q | wc -l | tr -d ' ')
RUNNING_SERVICES=$(docker-compose ps --format "{{.Status}}" | grep -c "Up" || true)
HEALTHY_SERVICES=$(docker-compose ps --format "{{.Status}}" | grep -c "healthy" || true)

echo "📊 Service Statistics:"
echo "  Total Services: $TOTAL_SERVICES"
echo "  Running Services: $RUNNING_SERVICES"
echo "  Healthy Services: $HEALTHY_SERVICES"
echo ""

# Step 8: Test key endpoints
echo "Step 8: Testing key endpoints..."
echo -n "  Analytics Health: "
if curl -s http://localhost:4000/health 2>/dev/null | grep -q "ok"; then
    echo "✅ OK"
    ANALYTICS_OK=true
else
    echo "❌ Failed"
    ANALYTICS_OK=false
fi

echo -n "  Kong Gateway: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null | grep -q "200"; then
    echo "✅ OK"
    KONG_OK=true
else
    echo "❌ Failed"
    KONG_OK=false
fi

echo -n "  Dashboard Access: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null | grep -q "200"; then
    echo "✅ OK"
    DASHBOARD_OK=true
else
    echo "❌ Failed"
    DASHBOARD_OK=false
fi
echo ""

# Step 9: Calculate success rate
echo "Step 9: Final Results"
echo "========================================="

# Success criteria: All services running AND key endpoints working
if [ "$TOTAL_SERVICES" -eq 13 ] && [ "$RUNNING_SERVICES" -eq 13 ] && [ "$ANALYTICS_OK" = true ] && [ "$KONG_OK" = true ]; then
    echo "🎯 SUCCESS RATE: 13/13 = 100%"
    echo "✅ REGRESSION TEST PASSED!"
    echo ""
    echo "🎉 Zero-shot deployment successful!"
    echo "   - All 13 services are running"
    echo "   - Analytics endpoint responding"  
    echo "   - Kong gateway accessible"
    echo "   - Dashboard available at http://localhost:8000"
    EXIT_CODE=0
else
    echo "❌ SUCCESS RATE: $RUNNING_SERVICES/$TOTAL_SERVICES"
    echo "❌ REGRESSION TEST FAILED"
    echo ""
    echo "Issues detected:"
    if [ "$TOTAL_SERVICES" -ne 13 ]; then
        echo "   - Expected 13 services, found $TOTAL_SERVICES"
    fi
    if [ "$RUNNING_SERVICES" -ne 13 ]; then
        echo "   - Not all services running ($RUNNING_SERVICES/13)"
    fi
    if [ "$ANALYTICS_OK" = false ]; then
        echo "   - Analytics endpoint not responding"
    fi
    if [ "$KONG_OK" = false ]; then
        echo "   - Kong gateway not accessible"
    fi
    EXIT_CODE=1
fi
echo "========================================="

# Step 10: Cleanup (optional)
if [ "$NO_CLEANUP" = false ]; then
    echo ""
    read -p "Do you want to clean up the test environment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleaning up..."
        docker-compose down -v > /dev/null 2>&1
        cd /
        rm -rf "$TEST_DIR"
        echo "✅ Cleanup complete"
    else
        echo "Test environment preserved at: $TEST_DIR"
        echo "To clean up later: cd '$TEST_DIR' && docker-compose down -v && cd / && rm -rf '$TEST_DIR'"
    fi
else
    echo ""
    echo "Test environment preserved at: $TEST_DIR"
    echo "To clean up: cd '$TEST_DIR' && docker-compose down -v && cd / && rm -rf '$TEST_DIR'"
fi

exit $EXIT_CODE