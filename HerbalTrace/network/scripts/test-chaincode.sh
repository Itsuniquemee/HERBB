#!/bin/bash

echo "=== Testing Chaincode with Proper JSON Format ==="

# Create collection event with proper JSON
COLLECTION_EVENT_JSON='{"id":"COL001","type":"CollectionEvent","species":"Ashwagandha","quantity":100.5,"unit":"kg","collectorId":"FARMER001","collectorName":"Rajesh Kumar","collectionDate":"2025-11-17","location":"Rajasthan Farm District 1","latitude":26.9124,"longitude":75.7873,"weather":"Sunny","temperature":28.5,"humidity":45.0,"soilPH":7.2,"harvestMethod":"Hand-picked","organicCertified":true,"timestamp":"2025-11-17T10:00:00Z","status":"pending","organizationId":"FarmersCoopMSP"}'

echo "Creating collection event..."
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -c "{\"function\":\"CreateCollectionEvent\",\"Args\":[\"$COLLECTION_EVENT_JSON\"]}"

echo ""
echo "Waiting for transaction to commit..."
sleep 3

echo ""
echo "=== Querying Collection Event ==="
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetCollectionEvent","Args":["COL001"]}'

echo ""
echo "=== Done ==="
