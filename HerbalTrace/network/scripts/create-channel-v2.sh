#!/bin/bash
# Create Application Channel for Fabric 2.5+

set -e

CHANNEL_NAME="herbaltrace-channel"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NETWORK_DIR="$(dirname "$SCRIPT_DIR")"

cd "$NETWORK_DIR"

echo "Generating application channel genesis block..."
docker run --rm \
  -v "$NETWORK_DIR":/config \
  -w /config \
  hyperledger/fabric-tools:2.5 \
  configtxgen -profile HerbalTraceChannel \
  -outputBlock /config/channel-artifacts/${CHANNEL_NAME}-genesis.block \
  -channelID ${CHANNEL_NAME} \
  -configPath /config/configtx

echo "Joining orderers to channel using osnadmin..."

# Join orderer1
docker exec cli osnadmin channel join \
  --channelID ${CHANNEL_NAME} \
  --config-block ./channel-artifacts/${CHANNEL_NAME}-genesis.block \
  -o orderer.herbaltrace.com:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/tls/server.key

# Join orderer2
docker exec cli osnadmin channel join \
  --channelID ${CHANNEL_NAME} \
  --config-block ./channel-artifacts/${CHANNEL_NAME}-genesis.block \
  -o orderer2.herbaltrace.com:8053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer2.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer2.herbaltrace.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer2.herbaltrace.com/tls/server.key

# Join orderer3
docker exec cli osnadmin channel join \
  --channelID ${CHANNEL_NAME} \
  --config-block ./channel-artifacts/${CHANNEL_NAME}-genesis.block \
  -o orderer3.herbaltrace.com:9053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer3.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer3.herbaltrace.com/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer3.herbaltrace.com/tls/server.key

echo "Channel joined on all orderers!"
echo "Now joining peers..."

# Join FarmersCoop peers
echo "Joining FarmersCoop peers..."
docker exec -e CORE_PEER_LOCALMSPID=FarmersCoopMSP \
  -e CORE_PEER_ADDRESS=peer0.farmers.herbaltrace.com:7051 \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp \
  cli peer channel fetch 0 ./channel-artifacts/${CHANNEL_NAME}.block -o orderer.herbaltrace.com:7050 -c ${CHANNEL_NAME} --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

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
echo "Joining TestingLabs peers..."
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
echo "Joining Processors peers..."
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
echo "Joining Manufacturers peers..."
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

echo ""
echo "==================================="
echo "Channel creation completed!"
echo "Channel: ${CHANNEL_NAME}"
echo "All orderers joined: 3"
echo "All peers joined: 8"
echo "==================================="
