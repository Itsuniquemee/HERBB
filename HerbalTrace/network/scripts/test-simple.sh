#!/bin/bash

echo "=== Testing Chaincode Initialization ==="

# Simple query to test if chaincode is responsive
echo "Testing basic query..."
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"Args":["GetAllCollectionEvents"]}'

echo ""
echo "=== If above works, trying invoke ==="

# Try a simpler CreateCollectionEvent
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -c '{"Args":["CreateCollectionEvent","TEST001","Turmeric","50.0","TestFarm","2025-11-17","FarmersCoopMSP"]}'
