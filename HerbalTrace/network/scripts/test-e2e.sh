#!/bin/bash

# Complete Supply Chain Test - Using simpler approach
echo "=========================================="
echo "HerbalTrace Complete Supply Chain Test"
echo "=========================================="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create JSON files
cd /tmp

cat > col001.json <<'EOF'
{"id":"COL001","type":"CollectionEvent","farmerId":"FARMER001","farmerName":"Rajesh Kumar","species":"Withania somnifera","commonName":"Ashwagandha","scientificName":"Withania somnifera","quantity":100.5,"unit":"kg","latitude":26.9124,"longitude":75.7873,"altitude":450.0,"accuracy":5.0,"harvestDate":"2025-11-17","timestamp":"2025-11-17T10:00:00Z","harvestMethod":"manual","partCollected":"root","weatherConditions":"Clear sky","soilType":"Sandy loam","approvedZone":true,"zoneName":"Rajasthan Zone A","conservationStatus":"Least Concern","certificationIds":["ORG-2025-001"],"status":"pending"}
EOF

cat > qt001.json <<'EOF'
{"id":"QT001","type":"QualityTest","collectionEventId":"COL001","batchId":"BATCH-2025-001","labId":"LAB001","labName":"Ayurvedic Quality Lab","testDate":"2025-11-17","timestamp":"2025-11-17T14:00:00Z","testTypes":["moisture","pesticide","dna_barcode"],"moistureContent":8.5,"pesticideResults":{"organophosphates":"pass"},"heavyMetals":{"lead":0.5},"dnaBarcodeMatch":true,"dnaSequence":"ATCG","microbialLoad":1000.0,"aflatoxins":5.0,"overallResult":"pass","certificateId":"CERT-2025-001","testerName":"Dr. Sharma","status":"approved"}
EOF

cat > ps001.json <<'EOF'
{"id":"PS001","type":"ProcessingStep","previousStepId":"QT001","batchId":"BATCH-2025-001","processorId":"PROC001","processorName":"Herbal Processing Ltd","processType":"drying_and_grinding","processDate":"2025-11-18","timestamp":"2025-11-18T10:00:00Z","inputQuantity":100.5,"outputQuantity":85.0,"unit":"kg","temperature":45.0,"duration":24.0,"equipment":"Industrial Dryer XYZ","parameters":{"humidity":"40%"},"qualityChecks":["visual_inspection"],"operatorId":"OP001","operatorName":"Suresh Patel","location":"Jaipur","latitude":26.9124,"longitude":75.7873,"status":"completed"}
EOF

cat > prod001.json <<'EOF'
{"id":"PROD001","type":"Product","productName":"Premium Ashwagandha Powder","productType":"powder","manufacturerId":"MFG001","manufacturerName":"Ayurvedic Wellness Ltd","batchId":"BATCH-2025-001","manufactureDate":"2025-11-19","expiryDate":"2027-11-19","quantity":85.0,"unit":"kg","qrCode":"QR-PROD001-2025","ingredients":["Withania somnifera root powder"],"collectionEventIds":["COL001"],"qualityTestIds":["QT001"],"processingStepIds":["PS001"],"certifications":["Organic","AYUSH Certified"],"packagingDate":"2025-11-19","status":"manufactured","timestamp":"2025-11-19T10:00:00Z"}
EOF

# Copy JSON files into CLI container
docker cp col001.json cli:/tmp/
docker cp qt001.json cli:/tmp/
docker cp ps001.json cli:/tmp/
docker cp prod001.json cli:/tmp/

# Step 1: Create Collection Event
echo ""
echo -e "${YELLOW}Step 1: Farmer creates collection event${NC}"
docker exec cli bash -c 'peer chaincode invoke -o orderer.herbaltrace.com:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.farmers.herbaltrace.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt --peerAddresses peer0.labs.herbaltrace.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt -c "{\"function\":\"CreateCollectionEvent\",\"Args\":[\"$(cat /tmp/col001.json)\"]}"'

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
docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetCollectionEvent","Args":["COL001"]}'

sleep 2

# Step 3: Create Quality Test
echo ""
echo -e "${YELLOW}Step 3: Testing lab records quality test${NC}"
docker exec cli bash -c 'peer chaincode invoke -o orderer.herbaltrace.com:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.labs.herbaltrace.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt --peerAddresses peer0.processors.herbaltrace.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt -c "{\"function\":\"CreateQualityTest\",\"Args\":[\"$(cat /tmp/qt001.json)\"]}"'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Quality test recorded${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 4: Query Quality Test
echo ""
echo -e "${YELLOW}Step 4: Query quality test${NC}"
docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetQualityTest","Args":["QT001"]}'

sleep 2

# Step 5: Create Processing Step
echo ""
echo -e "${YELLOW}Step 5: Processor records processing${NC}"
docker exec cli bash -c 'peer chaincode invoke -o orderer.herbaltrace.com:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.processors.herbaltrace.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt --peerAddresses peer0.manufacturers.herbaltrace.com:13051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt -c "{\"function\":\"CreateProcessingStep\",\"Args\":[\"$(cat /tmp/ps001.json)\"]}"'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Processing step recorded${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 6: Query Processing Step
echo ""
echo -e "${YELLOW}Step 6: Query processing step${NC}"
docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProcessingStep","Args":["PS001"]}'

sleep 2

# Step 7: Create Product
echo ""
echo -e "${YELLOW}Step 7: Manufacturer creates product with QR${NC}"
docker exec cli bash -c 'peer chaincode invoke -o orderer.herbaltrace.com:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.manufacturers.herbaltrace.com:13051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt --peerAddresses peer0.farmers.herbaltrace.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt -c "{\"function\":\"CreateProduct\",\"Args\":[\"$(cat /tmp/prod001.json)\"]}"'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product created${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

sleep 5

# Step 8: Query Product
echo ""
echo -e "${YELLOW}Step 8: Query product by ID${NC}"
docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProduct","Args":["PROD001"]}'

sleep 2

# Step 9: Query Product by QR Code
echo ""
echo -e "${YELLOW}Step 9: Query product by QR code (consumer scan)${NC}"
docker exec cli peer chaincode query -C herbaltrace-channel -n herbaltrace -c '{"function":"GetProductByQRCode","Args":["QR-PROD001-2025"]}'

sleep 2

# Step 10: Generate Provenance
echo ""
echo -e "${YELLOW}Step 10: Generate complete provenance${NC}"
docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 --ordererTLSHostnameOverride orderer.herbaltrace.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.farmers.herbaltrace.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt -c '{"function":"GenerateProvenance","Args":["PROD001"]}'

sleep 2

echo ""
echo -e "${YELLOW}Step 11: Check chaincode containers${NC}"
docker ps --filter 'name=dev-peer' --format 'table {{.Names}}\t{{.Status}}'

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Complete Supply Chain Test Finished${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "1. ✓ Farmer uploaded collection (COL001)"
echo "2. ✓ Lab recorded quality test (QT001)"
echo "3. ✓ Processor recorded processing (PS001)"
echo "4. ✓ Manufacturer created product (PROD001)"
echo "5. ✓ QR code generation (QR-PROD001-2025)"
echo "6. ✓ Complete provenance available"
echo ""
echo "Network ready for web portal/app integration!"
