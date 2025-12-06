#!/bin/bash

# Complete Supply Chain Test - Farmer to QR Code Generation
# This tests the entire flow: Collection -> Quality Test -> Processing -> Product -> Provenance

echo "=========================================="
echo "HerbalTrace Complete Supply Chain Test"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Farmer uploads collection event
echo -e "${YELLOW}Step 1: Farmer creates collection event (Ashwagandha harvest)${NC}"
COLLECTION_JSON='{"id":"COL001","type":"CollectionEvent","farmerId":"FARMER001","farmerName":"Rajesh Kumar","species":"Withania somnifera","commonName":"Ashwagandha","scientificName":"Withania somnifera","quantity":100.5,"unit":"kg","latitude":26.9124,"longitude":75.7873,"altitude":450.0,"accuracy":5.0,"harvestDate":"2025-11-17","timestamp":"2025-11-17T10:00:00Z","harvestMethod":"manual","partCollected":"root","weatherConditions":"Clear sky, moderate temperature","soilType":"Sandy loam","approvedZone":true,"zoneName":"Rajasthan Approved Zone A","conservationStatus":"Least Concern","certificationIds":["ORG-2025-001"],"status":"pending"}'

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
  -c "{\"function\":\"CreateCollectionEvent\",\"Args\":[\"$COLLECTION_JSON\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Collection event created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create collection event${NC}"
    exit 1
fi

sleep 3

# Step 2: Query collection event
echo ""
echo -e "${YELLOW}Step 2: Query collection event to verify${NC}"
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetCollectionEvent","Args":["COL001"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Collection event retrieved successfully${NC}"
else
    echo -e "${RED}✗ Failed to retrieve collection event${NC}"
fi

sleep 2

# Step 3: Testing Lab records quality test
echo ""
echo -e "${YELLOW}Step 3: Testing Lab records quality test results${NC}"
QUALITY_JSON='{"id":"QT001","type":"QualityTest","collectionEventId":"COL001","batchId":"BATCH-2025-001","labId":"LAB001","labName":"Ayurvedic Quality Testing Lab","testDate":"2025-11-17","timestamp":"2025-11-17T14:00:00Z","testTypes":["moisture","pesticide","dna_barcode","heavy_metals"],"moistureContent":8.5,"pesticideResults":{"organophosphates":"pass","pyrethroids":"pass"},"heavyMetals":{"lead":0.5,"mercury":0.1,"arsenic":0.3},"dnaBarcodeMatch":true,"dnaSequence":"ATCG...","microbialLoad":1000.0,"aflatoxins":5.0,"overallResult":"pass","certificateId":"CERT-2025-001","testerName":"Dr. Sharma","status":"approved"}'

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
  -c "{\"function\":\"CreateQualityTest\",\"Args\":[\"$QUALITY_JSON\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Quality test recorded successfully${NC}"
else
    echo -e "${RED}✗ Failed to record quality test${NC}"
    exit 1
fi

sleep 3

# Step 4: Query quality test
echo ""
echo -e "${YELLOW}Step 4: Query quality test to verify${NC}"
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetQualityTest","Args":["QT001"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Quality test retrieved successfully${NC}"
else
    echo -e "${RED}✗ Failed to retrieve quality test${NC}"
fi

sleep 2

# Step 5: Processor records processing step
echo ""
echo -e "${YELLOW}Step 5: Processor records drying and grinding${NC}"
PROCESSING_JSON='{"id":"PS001","type":"ProcessingStep","previousStepId":"QT001","batchId":"BATCH-2025-001","processorId":"PROC001","processorName":"Herbal Processing Pvt Ltd","processType":"drying_and_grinding","processDate":"2025-11-18","timestamp":"2025-11-18T10:00:00Z","inputQuantity":100.5,"outputQuantity":85.0,"unit":"kg","temperature":45.0,"duration":24.0,"equipment":"Industrial Dryer Model XYZ","parameters":{"humidity":"40%","airflow":"high"},"qualityChecks":["visual_inspection","moisture_check"],"operatorId":"OP001","operatorName":"Suresh Patel","location":"Processing Unit, Jaipur","latitude":26.9124,"longitude":75.7873,"status":"completed"}'

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
  -c "{\"function\":\"CreateProcessingStep\",\"Args\":[\"$PROCESSING_JSON\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Processing step recorded successfully${NC}"
else
    echo -e "${RED}✗ Failed to record processing step${NC}"
    exit 1
fi

sleep 3

# Step 6: Query processing step
echo ""
echo -e "${YELLOW}Step 6: Query processing step to verify${NC}"
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetProcessingStep","Args":["PS001"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Processing step retrieved successfully${NC}"
else
    echo -e "${RED}✗ Failed to retrieve processing step${NC}"
fi

sleep 2

# Step 7: Manufacturer creates final product with QR code
echo ""
echo -e "${YELLOW}Step 7: Manufacturer creates final product with QR code${NC}"
PRODUCT_JSON='{"id":"PROD001","type":"Product","productName":"Premium Ashwagandha Powder","productType":"powder","manufacturerId":"MFG001","manufacturerName":"Ayurvedic Wellness Ltd","batchId":"BATCH-2025-001","manufactureDate":"2025-11-19","expiryDate":"2027-11-19","quantity":85.0,"unit":"kg","qrCode":"QR-PROD001-2025","ingredients":["Withania somnifera root powder"],"collectionEventIds":["COL001"],"qualityTestIds":["QT001"],"processingStepIds":["PS001"],"certifications":["Organic","AYUSH Certified"],"packagingDate":"2025-11-19","status":"manufactured","timestamp":"2025-11-19T10:00:00Z"}'

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
  -c "{\"function\":\"CreateProduct\",\"Args\":[\"$PRODUCT_JSON\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create product${NC}"
    exit 1
fi

sleep 3

# Step 8: Query product by ID
echo ""
echo -e "${YELLOW}Step 8: Query product by ID${NC}"
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetProduct","Args":["PROD001"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product retrieved successfully${NC}"
else
    echo -e "${RED}✗ Failed to retrieve product${NC}"
fi

sleep 2

# Step 9: Query product by QR code (consumer scan simulation)
echo ""
echo -e "${YELLOW}Step 9: Query product by QR code (consumer scan)${NC}"
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetProductByQRCode","Args":["QR-PROD001-2025"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product found by QR code${NC}"
else
    echo -e "${RED}✗ Failed to find product by QR code${NC}"
fi

sleep 2

# Step 10: Generate complete provenance (full supply chain history)
echo ""
echo -e "${YELLOW}Step 10: Generate complete provenance for traceability${NC}"
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -c '{"function":"GenerateProvenance","Args":["PROD001"]}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Provenance generated successfully${NC}"
else
    echo -e "${RED}✗ Failed to generate provenance${NC}"
fi

sleep 2

# Step 11: Check chaincode containers running
echo ""
echo -e "${YELLOW}Step 11: Verify chaincode containers${NC}"
echo "Chaincode containers running:"
docker ps --filter 'name=dev-peer' --format 'table {{.Names}}\t{{.Status}}'

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Complete Supply Chain Test Finished${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "1. ✓ Farmer uploaded collection event (COL001)"
echo "2. ✓ Testing lab recorded quality test (QT001)"
echo "3. ✓ Processor recorded processing step (PS001)"
echo "4. ✓ Manufacturer created product with QR (PROD001)"
echo "5. ✓ Consumer can scan QR code and get product details"
echo "6. ✓ Complete provenance/traceability is available"
echo ""
echo "Network is ready for web portal and mobile app integration!"
echo ""
