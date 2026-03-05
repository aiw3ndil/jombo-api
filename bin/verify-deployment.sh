#!/bin/bash
# Verification script for deployment

set -e

echo "🔍 Jombo API Deployment Verification"
echo "===================================="
echo ""

# Configuration
API_URL="${API_URL:-http://localhost:3000}"
TIMEOUT=5

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
check_endpoint() {
    local endpoint=$1
    local expected_status=${2:-200}
    
    echo -n "Checking $endpoint... "
    
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$API_URL$endpoint" || echo "000")
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓ OK${NC} (HTTP $status)"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $status, expected $expected_status)"
        return 1
    fi
}

check_json_response() {
    local endpoint=$1
    local key=$2
    local expected_value=$3
    
    echo -n "Checking $endpoint for $key=$expected_value... "
    
    response=$(curl -s --max-time $TIMEOUT "$API_URL$endpoint" || echo "{}")
    value=$(echo "$response" | grep -o "\"$key\":\"$expected_value\"" || echo "")
    
    if [ -n "$value" ]; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Start checks
echo "Target: $API_URL"
echo ""

# Basic health checks
echo "📊 Health Checks:"
check_endpoint "/health" 200
check_endpoint "/health/database" 200
echo ""

# API endpoints
echo "🔐 API Endpoints:"
check_endpoint "/api/v1/trips" 200
echo ""

# JSON validation
echo "📝 Response Validation:"
check_json_response "/health" "status" "ok"
echo ""

# Summary
echo ""
echo "===================================="
echo -e "${GREEN}✓ Deployment verification completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Test user registration: POST $API_URL/api/v1/register"
echo "2. Test login: POST $API_URL/api/v1/login"
echo "3. Create a trip: POST $API_URL/api/v1/trips"
echo ""
echo "Documentation: https://github.com/yourusername/jombo-api"
