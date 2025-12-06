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
