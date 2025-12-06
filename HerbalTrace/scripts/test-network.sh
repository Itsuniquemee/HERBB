#!/bin/bash

# HerbalTrace Network Test Script
# Tests blockchain transactions and network health

set -e

echo "=================================="
echo "🧪 HerbalTrace Network Test Suite"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "${YELLOW}Testing:${NC} $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run test with output
run_test_with_output() {
    local test_name=$1
    local test_command=$2
    
    echo ""
    echo -e "${YELLOW}Testing:${NC} $test_name"
    echo "Command: $test_command"
    echo "---"
    
    if output=$(eval "$test_command" 2>&1); then
        echo "$output"
        echo "---"
        echo -e "${GREEN}✅ PASSED${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "$output"
        echo "---"
        echo -e "${RED}❌ FAILED${NC}: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "📊 Test 1: Network Health Check"
echo "================================"

# Check if containers are running
run_test "All Docker containers running" "docker ps | grep -q 'Up'"

# Check orderer
run_test "Orderer is accessible" "docker exec cli peer channel list -o orderer1.ayurtrace.com:7050"

# Check peers
run_test "Farmer peer is running" "docker exec peer0.farmers.ayurtrace.com peer version"
run_test "Lab peer is running" "docker exec peer0.labs.ayurtrace.com peer version"
run_test "Processor peer is running" "docker exec peer0.processors.ayurtrace.com peer version"

echo ""
echo "📝 Test 2: Channel Configuration"
echo "================================"

# List channels
run_test_with_output "List channels on farmer peer" "docker exec peer0.farmers.ayurtrace.com peer channel list"

echo ""
echo "📦 Test 3: Chaincode Deployment"
echo "================================"

# Check chaincode installation
run_test_with_output "List installed chaincode" "docker exec peer0.farmers.ayurtrace.com peer lifecycle chaincode queryinstalled"

# Check committed chaincode
run_test_with_output "List committed chaincode" "docker exec peer0.farmers.ayurtrace.com peer lifecycle chaincode querycommitted -C ayurtrace"

echo ""
echo "🔗 Test 4: Blockchain Transactions"
echo "================================"

# Test 1: Create a collection event
echo ""
echo "Creating test collection event..."
COLLECTION_ID="TEST-$(date +%s)"
FARMER_ID="FARMER-TEST-001"

CREATE_CMD="docker exec cli peer chaincode invoke \
  -o orderer1.ayurtrace.com:7050 \
  -C ayurtrace \
  -n ayurtrace \
  --peerAddresses peer0.farmers.ayurtrace.com:7051 \
  -c '{\"function\":\"CreateCollectionEvent\",\"Args\":[\"$COLLECTION_ID\",\"$FARMER_ID\",\"Test Farmer\",\"Withania somnifera\",\"Ashwagandha\",\"25\",\"kg\",\"2025-11-17T10:00:00Z\",\"{\\\"latitude\\\":12.9716,\\\"longitude\\\":77.5946,\\\"address\\\":\\\"Test Location\\\"}\",\"{\\\"temperature\\\":28,\\\"humidity\\\":65}\",\"[\\\"Organic\\\"]\",\"[\\\"hash123\\\"]\"]}'"

if run_test_with_output "Create collection event transaction" "$CREATE_CMD"; then
    sleep 3
    
    # Test 2: Query the collection event
    echo ""
    echo "Querying created collection event..."
    QUERY_CMD="docker exec cli peer chaincode query \
      -C ayurtrace \
      -n ayurtrace \
      -c '{\"function\":\"GetCollectionEvent\",\"Args\":[\"$COLLECTION_ID\"]}'"
    
    run_test_with_output "Query collection event" "$QUERY_CMD"
    
    # Test 3: Query by farmer
    echo ""
    echo "Querying collections by farmer..."
    QUERY_FARMER_CMD="docker exec cli peer chaincode query \
      -C ayurtrace \
      -n ayurtrace \
      -c '{\"function\":\"GetCollectionEventsByFarmer\",\"Args\":[\"$FARMER_ID\"]}'"
    
    run_test_with_output "Query by farmer ID" "$QUERY_FARMER_CMD"
fi

# Test 4: Create quality test
echo ""
echo "Creating quality test transaction..."
TEST_ID="QT-$(date +%s)"

QUALITY_CMD="docker exec cli peer chaincode invoke \
  -o orderer1.ayurtrace.com:7050 \
  -C ayurtrace \
  -n ayurtrace \
  --peerAddresses peer0.labs.ayurtrace.com:9051 \
  -c '{\"function\":\"CreateQualityTest\",\"Args\":[\"$TEST_ID\",\"$COLLECTION_ID\",\"LAB-001\",\"Test Lab\",\"2025-11-17T11:00:00Z\",\"Standard Test\",\"{\\\"purity\\\":95,\\\"moisture\\\":10,\\\"heavyMetals\\\":5}\",\"PASSED\",\"All parameters within limits\",\"[\\\"cert1\\\"]\",\"[]\"]}'"

if run_test_with_output "Create quality test transaction" "$QUALITY_CMD"; then
    sleep 3
    
    # Query quality test
    echo ""
    echo "Querying quality test..."
    QUERY_TEST_CMD="docker exec cli peer chaincode query \
      -C ayurtrace \
      -n ayurtrace \
      -c '{\"function\":\"GetQualityTest\",\"Args\":[\"$TEST_ID\"]}'"
    
    run_test_with_output "Query quality test" "$QUERY_TEST_CMD"
fi

echo ""
echo "📈 Test 5: Ledger State"
echo "================================"

# Query all collections
echo ""
echo "Querying all collection events..."
run_test_with_output "Get all collection events" "docker exec cli peer chaincode query -C ayurtrace -n ayurtrace -c '{\"function\":\"GetAllCollectionEvents\",\"Args\":[]}'"

# Get block height
echo ""
echo "Checking blockchain height..."
run_test_with_output "Query block height" "docker exec peer0.farmers.ayurtrace.com peer channel getinfo -c ayurtrace"

echo ""
echo "🔍 Test 6: Provenance Generation"
echo "================================"

# Generate provenance
echo ""
echo "Generating provenance bundle..."
PRODUCT_ID="PROD-$(date +%s)"

PROVENANCE_CMD="docker exec cli peer chaincode invoke \
  -o orderer1.ayurtrace.com:7050 \
  -C ayurtrace \
  -n ayurtrace \
  --peerAddresses peer0.farmers.ayurtrace.com:7051 \
  -c '{\"function\":\"GenerateProvenance\",\"Args\":[\"$PRODUCT_ID\",\"$COLLECTION_ID\",\"[]\",\"[]\",\"Final Product\",\"Ashwagandha Powder\",\"Ready for distribution\"]}'"

if run_test_with_output "Generate provenance bundle" "$PROVENANCE_CMD"; then
    sleep 3
    
    # Query provenance
    echo ""
    echo "Querying provenance..."
    QUERY_PROV_CMD="docker exec cli peer chaincode query \
      -C ayurtrace \
      -n ayurtrace \
      -c '{\"function\":\"GetProvenance\",\"Args\":[\"$PRODUCT_ID\"]}'"
    
    run_test_with_output "Query provenance" "$QUERY_PROV_CMD"
fi

echo ""
echo "=================================="
echo "📊 Test Summary"
echo "=================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Network is fully operational.${NC}"
    echo ""
    echo "Your HerbalTrace blockchain network is:"
    echo "  ✅ Running correctly"
    echo "  ✅ Processing transactions"
    echo "  ✅ Storing data on ledger"
    echo "  ✅ Supporting queries"
    echo "  ✅ Generating provenance"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the logs above.${NC}"
    echo ""
    exit 1
fi
