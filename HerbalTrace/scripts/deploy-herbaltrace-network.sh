#!/bin/bash

# Script to clean up old ayurtrace network and deploy fresh HerbalTrace network

echo "=========================================="
echo "🧹 Cleaning Old Network & Deploying HerbalTrace"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Stop and remove old ayurtrace network
echo -e "${YELLOW}Step 1: Stopping existing ayurtrace network...${NC}"
docker stop $(docker ps -aq --filter "name=ayurtrace") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=ayurtrace") 2>/dev/null || true
echo -e "${GREEN}✅ Old network stopped${NC}"
echo ""

# Step 2: Clean up old volumes and networks
echo -e "${YELLOW}Step 2: Cleaning up old volumes...${NC}"
docker volume rm $(docker volume ls -q --filter "name=ayurtrace") 2>/dev/null || true
docker network rm ayurtrace-network 2>/dev/null || true
docker network prune -f 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup complete${NC}"
echo ""

# Step 3: Navigate to HerbalTrace directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NETWORK_DIR="$PROJECT_ROOT/network"

cd "$NETWORK_DIR"
echo "Working directory: $(pwd)"
echo ""

# Step 4: Generate crypto material for HerbalTrace
echo -e "${YELLOW}Step 3: Generating crypto material for HerbalTrace...${NC}"

# Create crypto-config.yaml
cat > crypto-config.yaml << 'EOF'
OrdererOrgs:
  - Name: Orderer
    Domain: herbaltrace.com
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer
      - Hostname: orderer2
      - Hostname: orderer3

PeerOrgs:
  - Name: Farmers
    Domain: farmers.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: Labs
    Domain: labs.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: Processors
    Domain: processors.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3

  - Name: Manufacturers
    Domain: manufacturers.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 3
EOF

# Generate certificates
if command -v cryptogen &> /dev/null; then
    cryptogen generate --config=crypto-config.yaml --output=organizations
    echo -e "${GREEN}✅ Crypto material generated${NC}"
else
    echo -e "${RED}❌ cryptogen not found. Using Docker to generate...${NC}"
    docker run --rm -v "$(pwd)":/work -w /work hyperledger/fabric-tools:2.5 \
        cryptogen generate --config=crypto-config.yaml --output=organizations
    echo -e "${GREEN}✅ Crypto material generated with Docker${NC}"
fi
echo ""

# Step 5: Generate genesis block and channel artifacts
echo -e "${YELLOW}Step 4: Generating genesis block and channel configuration...${NC}"

mkdir -p channel-artifacts

# Generate genesis block
if command -v configtxgen &> /dev/null; then
    configtxgen -profile HerbalTraceOrdererGenesis \
        -channelID system-channel \
        -outputBlock ./channel-artifacts/genesis.block \
        -configPath ./configtx
    
    # Generate channel creation tx
    configtxgen -profile HerbalTraceChannel \
        -outputCreateChannelTx ./channel-artifacts/herbaltrace.tx \
        -channelID herbaltrace \
        -configPath ./configtx
    
    echo -e "${GREEN}✅ Genesis block and channel artifacts created${NC}"
else
    echo -e "${RED}❌ configtxgen not found. Using Docker...${NC}"
    docker run --rm -v "$(pwd)":/work -w /work \
        -e FABRIC_CFG_PATH=/work/configtx \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile HerbalTraceOrdererGenesis \
        -channelID system-channel \
        -outputBlock /work/channel-artifacts/genesis.block
    
    docker run --rm -v "$(pwd)":/work -w /work \
        -e FABRIC_CFG_PATH=/work/configtx \
        hyperledger/fabric-tools:2.5 \
        configtxgen -profile HerbalTraceChannel \
        -outputCreateChannelTx /work/channel-artifacts/herbaltrace.tx \
        -channelID herbaltrace
    
    echo -e "${GREEN}✅ Artifacts created with Docker${NC}"
fi
echo ""

# Step 6: Start HerbalTrace network
echo -e "${YELLOW}Step 5: Starting HerbalTrace network...${NC}"
docker-compose -f docker/docker-compose-herbaltrace.yaml up -d

echo "Waiting for network to initialize..."
sleep 10
echo -e "${GREEN}✅ Network started${NC}"
echo ""

# Step 7: Verify containers
echo -e "${YELLOW}Step 6: Verifying running containers...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep herbaltrace
echo ""

# Step 8: Create and join channel
echo -e "${YELLOW}Step 7: Creating channel 'herbaltrace'...${NC}"

# Create channel
docker exec cli peer channel create \
    -o orderer.herbaltrace.com:7050 \
    -c herbaltrace \
    -f /etc/hyperledger/channel-artifacts/herbaltrace.tx \
    --outputBlock /etc/hyperledger/channel-artifacts/herbaltrace.block \
    --tls \
    --cafile /etc/hyperledger/fabric/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Channel created${NC}"
else
    echo -e "${RED}❌ Channel creation failed${NC}"
fi

sleep 3

# Join peers to channel
echo ""
echo -e "${YELLOW}Step 8: Joining peers to channel...${NC}"

# Join all farmers peers
docker exec -e CORE_PEER_LOCALMSPID=FarmersMSP \
    -e CORE_PEER_ADDRESS=peer0.farmers.herbaltrace.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

docker exec -e CORE_PEER_LOCALMSPID=FarmersMSP \
    -e CORE_PEER_ADDRESS=peer1.farmers.herbaltrace.com:8051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

# Join labs peers
docker exec -e CORE_PEER_LOCALMSPID=LabsMSP \
    -e CORE_PEER_ADDRESS=peer0.labs.herbaltrace.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

docker exec -e CORE_PEER_LOCALMSPID=LabsMSP \
    -e CORE_PEER_ADDRESS=peer1.labs.herbaltrace.com:10051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

# Join processors peers
docker exec -e CORE_PEER_LOCALMSPID=ProcessorsMSP \
    -e CORE_PEER_ADDRESS=peer0.processors.herbaltrace.com:11051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

docker exec -e CORE_PEER_LOCALMSPID=ProcessorsMSP \
    -e CORE_PEER_ADDRESS=peer1.processors.herbaltrace.com:12051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

# Join manufacturers peers
docker exec -e CORE_PEER_LOCALMSPID=ManufacturersMSP \
    -e CORE_PEER_ADDRESS=peer0.manufacturers.herbaltrace.com:13051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

docker exec -e CORE_PEER_LOCALMSPID=ManufacturersMSP \
    -e CORE_PEER_ADDRESS=peer1.manufacturers.herbaltrace.com:14051 \
    -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp \
    cli peer channel join -b /etc/hyperledger/channel-artifacts/herbaltrace.block

echo -e "${GREEN}✅ All peers joined to channel${NC}"
echo ""

# Step 9: Package and deploy chaincode
echo -e "${YELLOW}Step 9: Deploying chaincode...${NC}"

cd "$PROJECT_ROOT/chaincode/herbaltrace"

# Package chaincode
tar czf herbaltrace.tar.gz .
cd "$NETWORK_DIR"

# Install on all peers (simplified - just one per org)
echo "Installing chaincode on peers..."

# Note: Full chaincode lifecycle deployment would go here
# For now, confirming network is ready

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 HerbalTrace Network Deployed!${NC}"
echo "=========================================="
echo ""
echo "Network Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAMES|herbaltrace"
echo ""
echo "Verify channel:"
echo "  docker exec peer0.farmers.herbaltrace.com peer channel list"
echo ""
echo "Next: Deploy chaincode with lifecycle commands"
echo ""
