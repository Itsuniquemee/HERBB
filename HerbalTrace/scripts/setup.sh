#!/bin/bash
#
# HerbalTrace - One-Command Complete Setup Script
# Installs prerequisites, sets up Fabric network, deploys chaincode, starts backend API
#

set -e

# Set script directory and project root at the very beginning
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "Starting from project directory: $PROJECT_ROOT"
echo

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function infoln() {
  echo -e "${GREEN}===== $1 =====${NC}"
}

function errorln() {
  echo -e "${RED}ERROR: $1${NC}"
}

function warnln() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

function println() {
  echo -e "${BLUE}$1${NC}"
}

# Check if running on Ubuntu
if [[ ! -f /etc/os-release ]]; then
  errorln "Cannot determine OS. This script is designed for Ubuntu."
  exit 1
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
  warnln "This script is optimized for Ubuntu. Detected: $ID $VERSION_ID"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

infoln "HerbalTrace Complete Setup Starting..."
println "This script will install all prerequisites and set up the complete system."
println "Estimated time: 15-30 minutes depending on your internet connection."
echo

# Ask for sudo password upfront
sudo -v

# Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

##############################################
# Step 1: Install Prerequisites
##############################################
infoln "Step 1/8: Installing Prerequisites"

println "Updating package lists..."
sudo apt update -qq

println "Installing essential packages..."
sudo apt install -y curl jq git apt-transport-https ca-certificates gnupg lsb-release \
  build-essential software-properties-common

# Install Docker
if command -v docker &> /dev/null; then
  println "Docker already installed: $(docker --version)"
else
  println "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -qq
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  
  sudo usermod -aG docker $USER
  println "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Install Go
if command -v go &> /dev/null; then
  println "Go already installed: $(go version)"
else
  println "Installing Go 1.21..."
  GO_VERSION="1.21.5"
  curl -LO "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
  rm "go${GO_VERSION}.linux-amd64.tar.gz"
  
  # Add to PATH if not already there
  if ! grep -q "/usr/local/go/bin" ~/.profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.profile
  fi
  export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
  
  println "Go installed: $(go version)"
fi

# Install Node.js
if command -v node &> /dev/null; then
  println "Node.js already installed: $(node --version)"
else
  println "Installing Node.js 20.x..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  println "Node.js installed: $(node --version)"
  println "npm installed: $(npm --version)"
fi

# Install Python (for some tools)
if command -v python3 &> /dev/null; then
  println "Python already installed: $(python3 --version)"
else
  sudo apt install -y python3 python3-pip
fi

infoln "Prerequisites installed successfully!"
echo

##############################################
# Step 2: Download Hyperledger Fabric
##############################################
infoln "Step 2/8: Downloading Hyperledger Fabric"

FABRIC_VERSION="2.5.5"
CA_VERSION="1.5.7"

# Create fabric binaries directory
mkdir -p ~/fabric-bin
cd ~/fabric-bin

if [ -f "bin/peer" ]; then
  println "Fabric binaries already downloaded"
else
  println "Downloading Fabric $FABRIC_VERSION binaries and Docker images..."
  curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary docker -f $FABRIC_VERSION -c $CA_VERSION
fi

# Add fabric binaries to PATH
export PATH=$PATH:~/fabric-bin/bin
if ! grep -q "fabric-bin/bin" ~/.profile; then
  echo 'export PATH=$PATH:$HOME/fabric-bin/bin' >> ~/.profile
fi

println "Fabric binaries installed: $(peer version | head -n 1)"
echo

##############################################
# Step 3: Setup HerbalTrace Project
##############################################
infoln "Step 3/8: Setting up HerbalTrace Project"

println "Project directory: $PROJECT_ROOT"

# Set environment variables
export FABRIC_CFG_PATH=${PROJECT_ROOT}/network/configtx
export PATH=${PATH}:${PROJECT_ROOT}/network/scripts

echo

##############################################
# Step 4: Generate Network Artifacts
##############################################
infoln "Step 4/8: Generating Network Artifacts"

cd "${PROJECT_ROOT}/network"
mkdir -p scripts

# Generate crypto materials using cryptogen
println "Generating crypto materials..."
if [ ! -f "${PROJECT_ROOT}/network/scripts/createCryptoMaterials.sh" ]; then
  # Create the cryptogen script if it doesn't exist
  cat > ${PROJECT_ROOT}/network/scripts/createCryptoMaterials.sh << 'CRYPTOSCRIPT'
#!/bin/bash

set -e

CRYPTO_CONFIG_DIR="../organizations"
mkdir -p ${CRYPTO_CONFIG_DIR}

# Generate crypto materials using cryptogen
echo "Generating crypto materials with cryptogen..."

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
  - Name: FarmersCoop
    Domain: farmers.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 2

  - Name: TestingLabs
    Domain: labs.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 2

  - Name: Processors
    Domain: processors.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 2

  - Name: Manufacturers
    Domain: manufacturers.herbaltrace.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 2
EOF

cryptogen generate --config=./crypto-config.yaml --output="${CRYPTO_CONFIG_DIR}"

# Rename directories to match expected structure
mv ${CRYPTO_CONFIG_DIR}/ordererOrganizations ${CRYPTO_CONFIG_DIR}/ordererOrganizations-temp 2>/dev/null || true
mv ${CRYPTO_CONFIG_DIR}/peerOrganizations ${CRYPTO_CONFIG_DIR}/peerOrganizations-temp 2>/dev/null || true

mkdir -p ${CRYPTO_CONFIG_DIR}/ordererOrganizations/herbaltrace.com
mkdir -p ${CRYPTO_CONFIG_DIR}/peerOrganizations

# Move orderer org
if [ -d "${CRYPTO_CONFIG_DIR}/ordererOrganizations-temp/herbaltrace.com" ]; then
  cp -r ${CRYPTO_CONFIG_DIR}/ordererOrganizations-temp/herbaltrace.com/* ${CRYPTO_CONFIG_DIR}/ordererOrganizations/herbaltrace.com/
  rm -rf ${CRYPTO_CONFIG_DIR}/ordererOrganizations-temp
fi

# Move peer orgs
for org in farmers.herbaltrace.com labs.herbaltrace.com processors.herbaltrace.com manufacturers.herbaltrace.com; do
  if [ -d "${CRYPTO_CONFIG_DIR}/peerOrganizations-temp/${org}" ]; then
    cp -r ${CRYPTO_CONFIG_DIR}/peerOrganizations-temp/${org} ${CRYPTO_CONFIG_DIR}/peerOrganizations/
  fi
done
rm -rf ${CRYPTO_CONFIG_DIR}/peerOrganizations-temp 2>/dev/null || true

echo "Crypto materials generated successfully!"
CRYPTOSCRIPT

  chmod +x ${PROJECT_ROOT}/network/scripts/createCryptoMaterials.sh
fi

./scripts/createCryptoMaterials.sh

# Generate genesis block
println "Generating genesis block and channel transaction..."
if [ ! -f "${PROJECT_ROOT}/network/scripts/createGenesisBlock.sh" ]; then
  cat > ${PROJECT_ROOT}/network/scripts/createGenesisBlock.sh << 'GENESISSCRIPT'
#!/bin/bash

set -e

# Navigate to network directory and set proper paths
cd "$(dirname "$0")/.."
export FABRIC_CFG_PATH=${PWD}/configtx
export CHANNEL_NAME=herbaltrace-channel

mkdir -p channel-artifacts

echo "Generating genesis block..."
configtxgen -profile HerbalTraceOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

echo "Generating channel creation transaction..."
configtxgen -profile HerbalTraceChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}

echo "Generating anchor peer updates..."
configtxgen -profile HerbalTraceChannel -outputAnchorPeersUpdate ./channel-artifacts/FarmersCoopMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg FarmersCoopMSP
configtxgen -profile HerbalTraceChannel -outputAnchorPeersUpdate ./channel-artifacts/TestingLabsMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg TestingLabsMSP
configtxgen -profile HerbalTraceChannel -outputAnchorPeersUpdate ./channel-artifacts/ProcessorsMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg ProcessorsMSP
configtxgen -profile HerbalTraceChannel -outputAnchorPeersUpdate ./channel-artifacts/ManufacturersMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg ManufacturersMSP

echo "Genesis block and channel artifacts generated successfully!"
GENESISSCRIPT

  chmod +x ${PROJECT_ROOT}/network/scripts/createGenesisBlock.sh
fi

./scripts/createGenesisBlock.sh

echo

##############################################
# Step 5: Start Fabric Network
##############################################
infoln "Step 5/8: Starting Hyperledger Fabric Network"

cd ${PROJECT_ROOT}/network/docker

println "Starting Docker containers..."
docker compose -f docker-compose-herbaltrace.yaml up -d

println "Waiting for network to initialize..."
sleep 15

println "Network containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo

##############################################
# Step 6: Create Channel and Join Peers
##############################################
infoln "Step 6/8: Creating Channel and Joining Peers"

cd ${PROJECT_ROOT}/network

CHANNEL_NAME="herbaltrace-channel"

println "Creating channel: ${CHANNEL_NAME}"

# Create channel using CLI container
docker exec cli peer channel create \
  -o orderer.herbaltrace.com:7050 \
  -c ${CHANNEL_NAME} \
  -f ./channel-artifacts/${CHANNEL_NAME}.tx \
  --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

println "Joining peers to channel..."

# Join FarmersCoop peers
println "Joining FarmersCoop peers..."
docker exec -e CORE_PEER_LOCALMSPID=FarmersCoopMSP \
  -e CORE_PEER_ADDRESS=peer0.farmers.herbaltrace.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

docker exec -e CORE_PEER_LOCALMSPID=FarmersCoopMSP \
  -e CORE_PEER_ADDRESS=peer1.farmers.herbaltrace.com:8051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer1.farmers.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join TestingLabs peers
println "Joining TestingLabs peers..."
docker exec -e CORE_PEER_LOCALMSPID=TestingLabsMSP \
  -e CORE_PEER_ADDRESS=peer0.labs.herbaltrace.com:9051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

docker exec -e CORE_PEER_LOCALMSPID=TestingLabsMSP \
  -e CORE_PEER_ADDRESS=peer1.labs.herbaltrace.com:10051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer1.labs.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join Processors peers
println "Joining Processors peers..."
docker exec -e CORE_PEER_LOCALMSPID=ProcessorsMSP \
  -e CORE_PEER_ADDRESS=peer0.processors.herbaltrace.com:11051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

docker exec -e CORE_PEER_LOCALMSPID=ProcessorsMSP \
  -e CORE_PEER_ADDRESS=peer1.processors.herbaltrace.com:12051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer1.processors.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join Manufacturers peers
println "Joining Manufacturers peers..."
docker exec -e CORE_PEER_LOCALMSPID=ManufacturersMSP \
  -e CORE_PEER_ADDRESS=peer0.manufacturers.herbaltrace.com:13051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

docker exec -e CORE_PEER_LOCALMSPID=ManufacturersMSP \
  -e CORE_PEER_ADDRESS=peer1.manufacturers.herbaltrace.com:14051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer1.manufacturers.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp \
  cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

println "Channel created and all peers joined successfully!"

echo

##############################################
# Step 7: Deploy Chaincode
##############################################
infoln "Step 7/8: Deploying HerbalTrace Chaincode"

cd ${PROJECT_ROOT}/chaincode/herbaltrace
println "Installing Go dependencies..."
go mod tidy
go mod vendor

cd ${PROJECT_ROOT}/network

println "Packaging chaincode..."
peer lifecycle chaincode package herbaltrace.tar.gz \
  --path ${PROJECT_ROOT}/chaincode/herbaltrace \
  --lang golang \
  --label herbaltrace_1.0

println "Installing chaincode on all peers..."
# Install on all organizations (simplified - install on peer0 of each org)

# FarmersCoop
export CORE_PEER_LOCALMSPID="FarmersCoopMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode install herbaltrace.tar.gz

# TestingLabs
export CORE_PEER_LOCALMSPID="TestingLabsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode install herbaltrace.tar.gz

# Processors
export CORE_PEER_LOCALMSPID="ProcessorsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:11051
peer lifecycle chaincode install herbaltrace.tar.gz

# Manufacturers
export CORE_PEER_LOCALMSPID="ManufacturersMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:13051
peer lifecycle chaincode install herbaltrace.tar.gz

println "Querying installed chaincode..."
peer lifecycle chaincode queryinstalled > installed.txt
PACKAGE_ID=$(sed -n 's/^Package ID: //; s/, Label:.*$//p' installed.txt | head -n 1)
echo "Package ID: ${PACKAGE_ID}"

println "Approving chaincode for all organizations..."
CHANNEL_NAME="herbaltrace-channel"
ORDERER_CA=${PWD}/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

# Approve for FarmersCoop
export CORE_PEER_LOCALMSPID="FarmersCoopMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name herbaltrace --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1

# Approve for TestingLabs
export CORE_PEER_LOCALMSPID="TestingLabsMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name herbaltrace --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1

# Approve for Processors
export CORE_PEER_LOCALMSPID="ProcessorsMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:11051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name herbaltrace --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1

# Approve for Manufacturers
export CORE_PEER_LOCALMSPID="ManufacturersMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:13051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name herbaltrace --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1

println "Committing chaincode definition..."
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name herbaltrace --version 1.0 --sequence 1 \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt \
  --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt \
  --peerAddresses localhost:13051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt

println "Verifying chaincode deployment..."
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name herbaltrace

echo

##############################################
# Step 8: Initialize and Test
##############################################
infoln "Step 8/8: Initializing Chaincode"

println "Invoking Init function..."
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n herbaltrace \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt \
  -c '{"function":"InitLedger","Args":[]}'

println "Waiting for transaction to complete..."
sleep 5

echo

##############################################
# Complete!
##############################################
infoln "🎉 HerbalTrace Network Setup Complete! 🎉"
echo
println "✅ Hyperledger Fabric network is running"
println "✅ 4 organizations with 8 peers deployed"
println "✅ RAFT orderer cluster (3 nodes) running"
println "✅ HerbalTrace chaincode deployed and initialized"
echo
println "Next Steps:"
println "1. Start the backend API server:"
println "   cd ${PROJECT_ROOT}/backend && npm install && npm start"
echo
println "2. Start the web portal:"
println "   cd ${PROJECT_ROOT}/web-portal && npm install && npm start"
echo
println "3. Build the Flutter mobile app:"
println "   cd ${PROJECT_ROOT}/mobile-app && flutter pub get && flutter run"
echo
println "Network Information:"
println "- Channel: herbaltrace-channel"
println "- Chaincode: herbaltrace v1.0"
println "- Network containers: $(docker ps --filter label=service=hyperledger-fabric --format '{{.Names}}' | wc -l)"
echo
println "Useful Commands:"
println "- View logs: docker logs <container_name>"
println "- Stop network: cd ${PROJECT_ROOT}/network/docker && docker compose -f docker-compose-herbaltrace.yaml down"
println "- Restart network: cd ${PROJECT_ROOT}/network/docker && docker compose -f docker-compose-herbaltrace.yaml restart"
echo
println "📚 For full documentation, see: ${PROJECT_ROOT}/README.md"
echo
infoln "Happy tracing! 🌿"
