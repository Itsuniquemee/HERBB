#!/bin/bash

# Set environment for peer0.farmers
export CORE_PEER_LOCALMSPID=FarmersCoopMSP
export CORE_PEER_ADDRESS=peer0.farmers.herbaltrace.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp

echo "Testing CreateBatch..."
peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"CreateBatch","Args":["{\"id\":\"BATCH001\",\"species\":\"Ashwagandha\",\"totalQuantity\":100,\"unit\":\"kg\",\"collectionEventIds\":[\"EVT001\",\"EVT002\"],\"status\":\"collected\",\"createdBy\":\"FARMER001\"}"]}'

sleep 5

sleep 3

echo -e "\n\n=== Testing GetBatch ==="
peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetBatch","Args":["BATCH001"]}'

echo -e "\n\n=== Testing QueryBatchesByStatus (Rich Query) ==="
peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"QueryBatchesByStatus","Args":["collected"]}'

echo -e "\n\nTesting GetActiveAlerts..."
peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetActiveAlerts","Args":[]}'
