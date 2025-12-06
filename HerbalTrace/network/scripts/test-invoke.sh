#!/bin/bash

# Test invoke - Create Collection Event
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  --peerAddresses peer0.labs.herbaltrace.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt \
  -c '{"function":"CreateCollectionEvent","Args":["COL001","Ashwagandha","100.5","Rajasthan Farm 1","2025-11-17T10:00:00Z","FarmersCoopMSP"]}'

echo ""
echo "Waiting for chaincode container to initialize..."
sleep 5

# Test query - Get Collection Event
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetCollectionEvent","Args":["COL001"]}'
