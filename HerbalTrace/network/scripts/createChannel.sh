#!/bin/bash

set -e

CHANNEL_NAME="herbaltrace-channel"
CHANNEL_TX="./channel-artifacts/${CHANNEL_NAME}.tx"

export FABRIC_CFG_PATH=${PWD}/configtx
export CORE_PEER_TLS_ENABLED=true

echo "Creating channel: ${CHANNEL_NAME}"

# Use peer0.farmers as primary peer for channel creation
export CORE_PEER_LOCALMSPID="FarmersCoopMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer channel create -o localhost:7050 -c ${CHANNEL_NAME} \
  -f ${CHANNEL_TX} --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
  --tls --cafile ${PWD}/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

echo "Joining peers to channel..."

# Join FarmersCoop peers
echo "Joining FarmersCoop peers..."
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

export CORE_PEER_ADDRESS=localhost:8051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join TestingLabs peers
echo "Joining TestingLabs peers..."
export CORE_PEER_LOCALMSPID="TestingLabsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

export CORE_PEER_ADDRESS=localhost:10051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join Processors peers
echo "Joining Processors peers..."
export CORE_PEER_LOCALMSPID="ProcessorsMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:11051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

export CORE_PEER_ADDRESS=localhost:12051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

# Join Manufacturers peers
echo "Joining Manufacturers peers..."
export CORE_PEER_LOCALMSPID="ManufacturersMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp
export CORE_PEER_ADDRESS=localhost:13051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

export CORE_PEER_ADDRESS=localhost:14051
peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

echo "Channel created and all peers joined successfully!"
