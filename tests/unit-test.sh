#!/bin/bash

# Supabase Easy - Unit Test
# Tests individual components and configurations
# 
# Usage: ./tests/unit-test.sh [component]
# Components: config, vault-key, env-vars, docker-compose

set -e

# Function to test configuration files
test_config() {
    echo "🔧 Testing configuration files..."
    
    # Test .env.example exists and has required variables
    if [ ! -f ".env.example" ]; then
        echo "❌ .env.example not found"
        return 1
    fi
    
    # Required environment variables
    REQUIRED_VARS=(
        "POSTGRES_PASSWORD"
        "JWT_SECRET" 
        "ANON_KEY"
        "SERVICE_ROLE_KEY"
        "VAULT_ENC_KEY"
        "SECRET_KEY_BASE"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if ! grep -q "^$var=" .env.example; then
            echo "❌ Required variable $var not found in .env.example"
            return 1
        fi
    done
    
    echo "✅ Configuration files valid"
    return 0
}

# Function to test vault key
test_vault_key() {
    echo "🔑 Testing vault key..."
    
    VAULT_KEY=$(grep "^VAULT_ENC_KEY=" .env.example | cut -d'=' -f2)
    KEY_LENGTH=${#VAULT_KEY}
    
    if [ "$KEY_LENGTH" -ne 32 ]; then
        echo "❌ VAULT_ENC_KEY must be exactly 32 characters, found $KEY_LENGTH"
        return 1
    fi
    
    # Check it's alphanumeric (no special chars that could break encryption)
    if [[ ! "$VAULT_KEY" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "❌ VAULT_ENC_KEY should contain only alphanumeric characters"
        return 1
    fi
    
    echo "✅ Vault key valid (32 characters, alphanumeric)"
    return 0
}

# Function to test environment variable consistency
test_env_vars() {
    echo "🌍 Testing environment variables..."
    
    # Check if all JWT keys have proper length (should be long)
    JWT_SECRET=$(grep "^JWT_SECRET=" .env.example | cut -d'=' -f2)
    if [ ${#JWT_SECRET} -lt 32 ]; then
        echo "❌ JWT_SECRET should be at least 32 characters"
        return 1
    fi
    
    # Check if keys look like proper JWT tokens or base64
    ANON_KEY=$(grep "^ANON_KEY=" .env.example | cut -d'=' -f2)
    if [[ ! "$ANON_KEY" =~ ^eyJ ]]; then
        echo "❌ ANON_KEY should start with 'eyJ' (JWT token)"
        return 1
    fi
    
    SERVICE_ROLE_KEY=$(grep "^SERVICE_ROLE_KEY=" .env.example | cut -d'=' -f2)
    if [[ ! "$SERVICE_ROLE_KEY" =~ ^eyJ ]]; then
        echo "❌ SERVICE_ROLE_KEY should start with 'eyJ' (JWT token)" 
        return 1
    fi
    
    echo "✅ Environment variables valid"
    return 0
}

# Function to test docker-compose configuration
test_docker_compose() {
    echo "🐳 Testing docker-compose configuration..."
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "❌ docker-compose.yml not found"
        return 1
    fi
    
    # Test docker-compose syntax (create temporary .env to avoid variable warnings)
    cp .env.example .env.tmp
    if ! COMPOSE_FILE=docker-compose.yml docker-compose --env-file .env.tmp config > /dev/null 2>&1; then
        echo "❌ docker-compose.yml has syntax errors"
        rm -f .env.tmp
        return 1
    fi
    rm -f .env.tmp
    
    # Count expected main services (excluding init containers)
    cp .env.example .env.tmp
    MAIN_SERVICE_COUNT=$(docker-compose --env-file .env.tmp config --services | grep -v "\-init$" | wc -l | tr -d ' ')
    if [ "$MAIN_SERVICE_COUNT" -ne 13 ]; then
        echo "❌ Expected 13 main services, found $MAIN_SERVICE_COUNT"
        rm -f .env.tmp
        return 1
    fi
    
    # Check required services exist
    REQUIRED_SERVICES=(
        "db" "analytics" "auth" "storage" "realtime" 
        "rest" "kong" "functions" "vector" "supavisor"
        "meta" "studio" "imgproxy"
    )
    
    for service in "${REQUIRED_SERVICES[@]}"; do
        if ! docker-compose --env-file .env.tmp config --services | grep -q "^$service$"; then
            echo "❌ Required service '$service' not found"
            rm -f .env.tmp
            return 1
        fi
    done
    rm -f .env.tmp
    
    echo "✅ Docker Compose configuration valid (13 services)"
    return 0
}

# Main function
main() {
    local component="${1:-all}"
    
    echo "🧪 SUPABASE EASY - UNIT TEST"
    echo "============================="
    echo ""
    
    case "$component" in
        "config")
            test_config
            ;;
        "vault-key")
            test_vault_key
            ;;
        "env-vars")
            test_env_vars
            ;;
        "docker-compose")
            test_docker_compose
            ;;
        "all")
            echo "Running all unit tests..."
            echo ""
            
            TESTS_PASSED=0
            TESTS_TOTAL=4
            
            if test_config; then ((TESTS_PASSED++)); fi
            echo ""
            
            if test_vault_key; then ((TESTS_PASSED++)); fi
            echo ""
            
            if test_env_vars; then ((TESTS_PASSED++)); fi
            echo ""
            
            if test_docker_compose; then ((TESTS_PASSED++)); fi
            echo ""
            
            echo "📊 Test Results:"
            echo "  Passed: $TESTS_PASSED/$TESTS_TOTAL"
            
            if [ "$TESTS_PASSED" -eq "$TESTS_TOTAL" ]; then
                echo "✅ ALL UNIT TESTS PASSED!"
                exit 0
            else
                echo "❌ SOME UNIT TESTS FAILED!"
                exit 1
            fi
            ;;
        "--help")
            echo "Supabase Easy - Unit Test"
            echo ""
            echo "Usage: ./tests/unit-test.sh [component]"
            echo ""
            echo "Components:"
            echo "  config           Test configuration files"
            echo "  vault-key        Test vault key format"
            echo "  env-vars         Test environment variables"
            echo "  docker-compose   Test Docker Compose config"
            echo "  all              Run all tests (default)"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown component: $component"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"