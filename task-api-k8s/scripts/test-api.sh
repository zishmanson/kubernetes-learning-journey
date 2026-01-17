#!/bin/bash

# API Test Script
# Tests all endpoints of the Task API

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default API URL
API_URL=${1:-http://localhost:30000}

echo "🧪 Testing Task API"
echo "===================="
echo "API URL: $API_URL"
echo ""

# Test 1: Health Check
echo "Test 1: Health Check"
RESPONSE=$(curl -s -w "\n%{http_code}" $API_URL/health)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Health check returned 200"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Health check returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 2: Create Task
echo "Test 2: Create Task"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST $API_URL/tasks \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Task","description":"This is a test task","status":"pending"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)
TASK_ID=$(echo "$BODY" | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ "$HTTP_CODE" == "201" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Task created successfully"
    echo "  Task ID: $TASK_ID"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Create task returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 3: Get All Tasks
echo "Test 3: Get All Tasks"
RESPONSE=$(curl -s -w "\n%{http_code}" $API_URL/tasks)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    TASK_COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l)
    echo -e "${GREEN}✓ PASS${NC} - Retrieved all tasks"
    echo "  Total tasks: $TASK_COUNT"
else
    echo -e "${RED}✗ FAIL${NC} - Get all tasks returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 4: Get Specific Task
echo "Test 4: Get Specific Task"
RESPONSE=$(curl -s -w "\n%{http_code}" $API_URL/tasks/$TASK_ID)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Retrieved specific task"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Get specific task returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 5: Update Task
echo "Test 5: Update Task"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT $API_URL/tasks/$TASK_ID \
    -H "Content-Type: application/json" \
    -d '{"title":"Updated Task","status":"completed"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Task updated successfully"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Update task returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 6: Delete Task
echo "Test 6: Delete Task"
RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE $API_URL/tasks/$TASK_ID)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Task deleted successfully"
    echo "  Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} - Delete task returned $HTTP_CODE"
    exit 1
fi
echo ""

# Test 7: Verify Deletion
echo "Test 7: Verify Task is Deleted"
RESPONSE=$(curl -s -w "\n%{http_code}" $API_URL/tasks/$TASK_ID)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" == "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Task correctly returns 404 after deletion"
else
    echo -e "${RED}✗ FAIL${NC} - Expected 404, got $HTTP_CODE"
    exit 1
fi
echo ""

# Test 8: Metrics Endpoint
echo "Test 8: Prometheus Metrics"
RESPONSE=$(curl -s -w "\n%{http_code}" $API_URL/metrics)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "flask_http_request"; then
    echo -e "${GREEN}✓ PASS${NC} - Metrics endpoint working"
    echo "  Found Prometheus metrics"
else
    echo -e "${RED}✗ FAIL${NC} - Metrics endpoint returned $HTTP_CODE"
    exit 1
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}🎉 All Tests Passed!${NC}"
echo "=========================================="
echo ""
echo "Your API is working correctly!"
echo ""
echo "Next steps:"
echo "  1. Check Prometheus: http://localhost:30001"
echo "  2. Check Grafana: http://localhost:30002"
echo "  3. View pods: kubectl get pods"
echo "  4. View logs: kubectl logs -f deployment/task-api"
echo "  5. View HPA: kubectl get hpa"
