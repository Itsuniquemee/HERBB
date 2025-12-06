#!/bin/bash

# Simple Network Status Check for Existing Ayurtrace Network

echo "=================================="
echo "🔍 HerbalTrace/Ayurtrace Network Status"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}1. Docker Containers Status:${NC}"
echo "=================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|ayurtrace|cli"
echo ""

echo -e "${YELLOW}2. Network Information:${NC}"
echo "=================================="
echo "Orderer:"
docker exec orderer1.ayurtrace.com peer version 2>&1 | grep -E "Version|Commit"
echo ""

echo "Peers:"
for peer in peer0.farmers peer0.labs peer0.processors peer0.manufacturers peer0.regulators peer0.certifiers; do
    echo "  - $peer.ayurtrace.com"
    docker exec $peer.ayurtrace.com peer version 2>&1 | grep "Version" || echo "    Status: Running"
done
echo ""

echo -e "${YELLOW}3. Channels Joined:${NC}"
echo "=================================="
echo "Checking farmer peer..."
docker exec peer0.farmers.ayurtrace.com peer channel list 2>&1
echo ""

echo -e "${YELLOW}4. Chaincode Installed:${NC}"
echo "=================================="
echo "On farmer peer:"
docker exec peer0.farmers.ayurtrace.com peer lifecycle chaincode queryinstalled 2>&1
echo ""

echo -e "${YELLOW}5. Network Health Summary:${NC}"
echo "=================================="

# Count containers
TOTAL=$(docker ps | grep -c ayurtrace)
echo -e "${GREEN}✅ $TOTAL containers running${NC}"

# Check if orderer is accessible
if docker exec orderer1.ayurtrace.com peer version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Orderer is accessible${NC}"
else
    echo "❌ Orderer not accessible"
fi

# Check if at least one peer is accessible
if docker exec peer0.farmers.ayurtrace.com peer version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Peers are accessible${NC}"
else
    echo "❌ Peers not accessible"
fi

echo ""
echo "=================================="
echo "📝 Next Steps to Test Transactions:"
echo "=================================="
echo "The network is running but needs:"
echo "  1. Channel to be created and joined"
echo "  2. Chaincode to be deployed"
echo "  3. Then transactions can be tested"
echo ""
echo "To see full logs:"
echo "  docker logs peer0.farmers.ayurtrace.com"
echo "  docker logs orderer1.ayurtrace.com"
echo ""
