#!/bin/bash
#
# HerbalTrace Network Deployment Script
# Deploys a 4-organization Hyperledger Fabric network with RAFT orderer
#

set -e

export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function printHelp() {
  echo "Usage: "
  echo "  deploy-network.sh <Mode> [Flags]"
  echo "    Modes:"
  echo "      up - Bring up the network with docker-compose"
  echo "      down - Clear the network with docker-compose down"
  echo "      restart - Restart the network"
  echo "      createChannel - Create and join channel"
  echo "      deployChaincode - Deploy chaincode to channel"
  echo "      all - Execute all steps (up, createChannel, deployChaincode)"
  echo
  echo "    Flags:"
  echo "    -ca - Use Fabric CAs (default: true)"
  echo "    -c <channel name> - Channel name (default: herbaltrace-channel)"
  echo "    -ccn <chaincode name> - Chaincode name (default: herbaltrace)"
  echo "    -ccv <chaincode version> - Chaincode version (default: 1.0)"
  echo "    -ccp <chaincode path> - Chaincode path (default: ../chaincode/herbaltrace)"
  echo "    -ccl <language> - Chaincode language (default: go)"
  echo "    -db <database> - Database type (default: couchdb)"
  echo "    -verbose - Verbose mode"
  echo
  echo "  Example:"
  echo "    ./deploy-network.sh up -ca"
  echo "    ./deploy-network.sh createChannel -c herbaltrace-channel"
  echo "    ./deploy-network.sh deployChaincode -ccn herbaltrace -ccv 1.0"
}

function infoln() {
  echo -e "${GREEN}${1}${NC}"
}

function errorln() {
  echo -e "${RED}${1}${NC}"
}

function warnln() {
  echo -e "${YELLOW}${1}${NC}"
}

# Default values
CHANNEL_NAME="herbaltrace-channel"
CHAINCODE_NAME="herbaltrace"
CHAINCODE_VERSION="1.0"
CHAINCODE_PATH="../chaincode/herbaltrace"
CHAINCODE_LANG="go"
DATABASE="couchdb"
USE_CA="true"

# Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
fi

MODE=$1
shift

# Parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -ca )
    USE_CA="true"
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ccn )
    CHAINCODE_NAME="$2"
    shift
    ;;
  -ccv )
    CHAINCODE_VERSION="$2"
    shift
    ;;
  -ccp )
    CHAINCODE_PATH="$2"
    shift
    ;;
  -ccl )
    CHAINCODE_LANG="$2"
    shift
    ;;
  -db )
    DATABASE="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

function clearContainers() {
  infoln "Removing remaining containers..."
  docker rm -f $(docker ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  docker rm -f $(docker ps -aq --filter name='dev-peer*') 2>/dev/null || true
}

function removeUnwantedImages() {
  infoln "Removing chaincode docker images..."
  docker rmi -f $(docker images -q --filter reference='dev-peer*') 2>/dev/null || true
}

function networkDown() {
  infoln "Stopping HerbalTrace network..."
  
  cd docker
  docker-compose -f docker-compose-herbaltrace.yaml down --volumes --remove-orphans
  cd ..
  
  clearContainers
  removeUnwantedImages
  
  # Remove channel and script artifacts
  rm -rf channel-artifacts/*.block channel-artifacts/*.tx
  rm -rf organizations/peerOrganizations organizations/ordererOrganizations
  rm -rf organizations/fabric-ca/farmerscoop/msp organizations/fabric-ca/farmerscoop/tls-cert.pem
  rm -rf organizations/fabric-ca/farmerscoop/ca-cert.pem organizations/fabric-ca/farmerscoop/IssuerPublicKey
  rm -rf organizations/fabric-ca/farmerscoop/IssuerRevocationPublicKey organizations/fabric-ca/farmerscoop/fabric-ca-server.db
  rm -rf organizations/fabric-ca/testinglabs/msp organizations/fabric-ca/testinglabs/tls-cert.pem
  rm -rf organizations/fabric-ca/testinglabs/ca-cert.pem organizations/fabric-ca/testinglabs/IssuerPublicKey
  rm -rf organizations/fabric-ca/testinglabs/IssuerRevocationPublicKey organizations/fabric-ca/testinglabs/fabric-ca-server.db
  rm -rf organizations/fabric-ca/processors/msp organizations/fabric-ca/processors/tls-cert.pem
  rm -rf organizations/fabric-ca/processors/ca-cert.pem organizations/fabric-ca/processors/IssuerPublicKey
  rm -rf organizations/fabric-ca/processors/IssuerRevocationPublicKey organizations/fabric-ca/processors/fabric-ca-server.db
  rm -rf organizations/fabric-ca/manufacturers/msp organizations/fabric-ca/manufacturers/tls-cert.pem
  rm -rf organizations/fabric-ca/manufacturers/ca-cert.pem organizations/fabric-ca/manufacturers/IssuerPublicKey
  rm -rf organizations/fabric-ca/manufacturers/IssuerRevocationPublicKey organizations/fabric-ca/manufacturers/fabric-ca-server.db
  rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem
  rm -rf organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey
  rm -rf organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db
  
  infoln "Network stopped and cleaned"
}

function networkUp() {
  infoln "Starting HerbalTrace Fabric network..."
  
  # Create channel-artifacts directory
  mkdir -p channel-artifacts
  
  # Generate crypto materials
  if [ "$USE_CA" == "true" ]; then
    infoln "Generating certificates using Fabric CA"
    ./scripts/createCertificates.sh
  else
    infoln "Generating certificates using cryptogen"
    ./scripts/createCryptoMaterials.sh
  fi
  
  # Generate genesis block and channel transaction
  infoln "Generating genesis block and channel transaction..."
  ./scripts/createGenesisBlock.sh
  
  # Start network
  cd docker
  if [ "$DATABASE" == "couchdb" ]; then
    infoln "Starting network with CouchDB..."
    docker-compose -f docker-compose-herbaltrace.yaml -f docker-compose-couch.yaml up -d
  else
    docker-compose -f docker-compose-herbaltrace.yaml up -d
  fi
  cd ..
  
  # Wait for containers to start
  sleep 10
  
  docker ps -a
  if [ $? -ne 0 ]; then
    errorln "Unable to start network"
    exit 1
  fi
  
  infoln "Network started successfully"
}

function createChannel() {
  infoln "Creating channel ${CHANNEL_NAME}..."
  ./scripts/createChannel.sh $CHANNEL_NAME
  
  if [ $? -ne 0 ]; then
    errorln "Failed to create channel"
    exit 1
  fi
  
  infoln "Channel ${CHANNEL_NAME} created successfully"
}

function deployChaincode() {
  infoln "Deploying chaincode ${CHAINCODE_NAME}..."
  ./scripts/deployChaincode.sh $CHANNEL_NAME $CHAINCODE_NAME $CHAINCODE_VERSION $CHAINCODE_PATH $CHAINCODE_LANG
  
  if [ $? -ne 0 ]; then
    errorln "Failed to deploy chaincode"
    exit 1
  fi
  
  infoln "Chaincode ${CHAINCODE_NAME} deployed successfully"
}

# Main execution
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then
  networkDown
elif [ "${MODE}" == "restart" ]; then
  networkDown
  networkUp
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployChaincode" ]; then
  deployChaincode
elif [ "${MODE}" == "all" ]; then
  networkUp
  sleep 5
  createChannel
  sleep 5
  deployChaincode
else
  printHelp
  exit 1
fi
