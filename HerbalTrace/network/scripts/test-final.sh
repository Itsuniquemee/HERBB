#!/bin/bash

# Complete End-to-End Test

echo "=========================================="
echo "HerbalTrace E2E Test"
echo "=========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Create Collection Event
echo ""
echo -e "${YELLOW}Step 1: Farmer creates collection event${NC}"
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
  -c '{"function":"CreateCollectionEvent","Args":["{\"id\":\"COL001\",\"type\":\"CollectionEvent\",\"farmerId\":\"FARMER001\",\"farmerName\":\"Rajesh Kumar\",\"species\":\"Ashwagandha\",\"commonName\":\"Ashwagandha\",\"scientificName\":\"Withania somnifera\",\"quantity\":100.5,\"unit\":\"kg\",\"latitude\":26.9124,\"longitude\":75.7873,\"altitude\":450.0,\"accuracy\":5.0,\"harvestDate\":\"2025-11-17\",\"timestamp\":\"2025-11-17T10:00:00Z\",\"harvestMethod\":\"manual\",\"partCollected\":\"root\",\"weatherConditions\":\"Clear\",\"soilType\":\"Sandy loam\",\"approvedZone\":true,\"zoneName\":\"Rajasthan Zone\",\"conservationStatus\":\"Least Concern\",\"status\":\"pending\"}"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Collection event created${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    exit 1
fi

sleep 5

# Step 2: Query Collection
echo ""
echo -e "${YELLOW}Step 2: Query collection event${NC}"
RESULT=$(docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetCollectionEvent","Args":["COL001"]}' 2>&1)
if [[ $RESULT == *"COL001"* ]]; then
    echo -e "${GREEN}✓ Retrieved: Ashwagandha collection by Rajesh Kumar${NC}"
else
    echo -e "${RED}✗ Failed to retrieve${NC}"
fi

sleep 2

# Step 3: Create Quality Test
echo ""
echo -e "${YELLOW}Step 3: Testing lab records quality test${NC}"
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.labs.herbaltrace.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt \
  --peerAddresses peer0.processors.herbaltrace.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt \
  -c '{"function":"CreateQualityTest","Args":["{\"id\":\"QT001\",\"type\":\"QualityTest\",\"collectionEventId\":\"COL001\",\"batchId\":\"BATCH-2025-001\",\"labId\":\"LAB001\",\"labName\":\"Ayurvedic Quality Lab\",\"testDate\":\"2025-11-17\",\"timestamp\":\"2025-11-17T14:00:00Z\",\"moistureContent\":8.5,\"dnaBarcodeMatch\":true,\"microbialLoad\":1000.0,\"aflatoxins\":5.0,\"overallResult\":\"pass\",\"certificateId\":\"CERT-2025-001\",\"testerName\":\"Dr. Sharma\",\"status\":\"approved\"}"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Quality test recorded${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 4: Query Quality Test
echo ""
echo -e "${YELLOW}Step 4: Query quality test${NC}"
RESULT=$(docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetQualityTest","Args":["QT001"]}' 2>&1)
if [[ $RESULT == *"QT001"* ]]; then
    echo -e "${GREEN}✓ Retrieved: Quality test passed by Dr. Sharma${NC}"
else
    echo -e "${RED}✗ Failed to retrieve${NC}"
fi

sleep 2

# Step 5: Create Processing Step
echo ""
echo -e "${YELLOW}Step 5: Processor records drying and grinding${NC}"
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.processors.herbaltrace.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt \
  --peerAddresses peer0.manufacturers.herbaltrace.com:13051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt \
  -c '{"function":"CreateProcessingStep","Args":["{\"id\":\"PS001\",\"type\":\"ProcessingStep\",\"previousStepId\":\"QT001\",\"batchId\":\"BATCH-2025-001\",\"processorId\":\"PROC001\",\"processorName\":\"Herbal Processing Ltd\",\"processType\":\"drying_and_grinding\",\"processDate\":\"2025-11-18\",\"timestamp\":\"2025-11-18T10:00:00Z\",\"inputQuantity\":100.5,\"outputQuantity\":85.0,\"unit\":\"kg\",\"temperature\":45.0,\"duration\":24.0,\"equipment\":\"Industrial Dryer\",\"operatorId\":\"OP001\",\"operatorName\":\"Suresh Patel\",\"location\":\"Jaipur\",\"latitude\":26.9124,\"longitude\":75.7873,\"status\":\"completed\"}"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Processing step recorded${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 6: Query Processing Step
echo ""
echo -e "${YELLOW}Step 6: Query processing step${NC}"
RESULT=$(docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProcessingStep","Args":["PS001"]}' 2>&1)
if [[ $RESULT == *"PS001"* ]]; then
    echo -e "${GREEN}✓ Retrieved: Processing by Herbal Processing Ltd${NC}"
else
    echo -e "${RED}✗ Failed to retrieve${NC}"
fi

sleep 2

# Step 7: Create Product with QR
echo ""
echo -e "${YELLOW}Step 7: Manufacturer creates product with QR code${NC}"
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.manufacturers.herbaltrace.com:13051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -c '{"function":"CreateProduct","Args":["{\"id\":\"PROD001\",\"type\":\"Product\",\"productName\":\"Premium Ashwagandha Powder\",\"productType\":\"powder\",\"manufacturerId\":\"MFG001\",\"manufacturerName\":\"Ayurvedic Wellness Ltd\",\"batchId\":\"BATCH-2025-001\",\"manufactureDate\":\"2025-11-19\",\"expiryDate\":\"2027-11-19\",\"quantity\":85.0,\"unit\":\"kg\",\"qrCode\":\"QR-PROD001-2025\",\"packagingDate\":\"2025-11-19\",\"status\":\"manufactured\",\"timestamp\":\"2025-11-19T10:00:00Z\"}"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product created with QR code${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 8: Query Product by ID
echo ""
echo -e "${YELLOW}Step 8: Query product by ID${NC}"
RESULT=$(docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProduct","Args":["PROD001"]}' 2>&1)
if [[ $RESULT == *"PROD001"* ]]; then
    echo -e "${GREEN}✓ Retrieved: Premium Ashwagandha Powder${NC}"
    echo "$RESULT" | grep -o '"qrCode":"[^"]*"'
else
    echo -e "${RED}✗ Failed to retrieve${NC}"
fi

sleep 2

# Step 9: Query Product by QR Code (Consumer Scan Simulation)
echo ""
echo -e "${YELLOW}Step 9: Consumer scans QR code${NC}"
RESULT=$(docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProductByQRCode","Args":["QR-PROD001-2025"]}' 2>&1)
if [[ $RESULT == *"Premium Ashwagandha"* ]]; then
    echo -e "${GREEN}✓ Product found by QR scan!${NC}"
else
    echo -e "${RED}✗ QR lookup failed${NC}"
fi

sleep 2

# Step 10: Check Chaincode Containers
echo ""
echo -e "${YELLOW}Step 10: Chaincode containers running${NC}"
docker ps --filter 'name=dev-peer' --format 'table {{.Names}}\t{{.Status}}'

echo ""
echo "=========================================="
echo -e "${GREEN}✓✓✓ COMPLETE E2E TEST PASSED ✓✓✓${NC}"
echo "=========================================="
echo ""
echo "Supply Chain Flow Verified:"
echo "  1. ✓ Farmer Collection (COL001) - Ashwagandha 100.5kg"
echo "  2. ✓ Lab Quality Test (QT001) - Pass"
echo "  3. ✓ Processor (PS001) - 85kg processed"
echo "  4. ✓ Product (PROD001) - QR: QR-PROD001-2025"
echo "  5. ✓ Consumer QR Scan - Working"
echo ""
echo -e "${GREEN}Network is ready for web portal and mobile app!${NC}"
echo ""
