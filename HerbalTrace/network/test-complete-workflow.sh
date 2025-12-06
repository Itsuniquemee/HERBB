#!/bin/bash

# ==============================================================================
# HerbalTrace Blockchain - Complete Workflow Test Script
# ==============================================================================
# This script tests the entire end-to-end supply chain workflow:
# 1. Collection Event (Farmer harvests herbs)
# 2. Batch Creation (Group collection events)
# 3. Quality Testing (Lab tests)
# 4. Processing Steps (Drying, grinding, extraction)
# 5. Product Creation (Final product with QR code)
# 6. Provenance Retrieval (Full traceability)
# 7. Validation (Season windows, harvest limits)
# 8. Alerts (Create and query alerts)
# ==============================================================================

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}HerbalTrace Blockchain - Complete Test${NC}"
echo -e "${BLUE}========================================${NC}"

# Set environment variables
export CHANNEL_NAME="herbaltrace-channel"
export CHAINCODE_NAME="herbaltrace"
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem

# ==============================================================================
# PHASE 1: Setup Season Windows and Harvest Limits
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 1] Setting up Season Windows and Harvest Limits${NC}"

# Create Season Window for Ashwagandha (Winter: Nov-Feb)
echo -e "${GREEN}→ Creating season window for Ashwagandha (Winter)${NC}"
docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"CreateSeasonWindow","Args":["{\"species\":\"Ashwagandha\",\"commonName\":\"Indian Ginseng\",\"scientificName\":\"Withania somnifera\",\"startMonth\":11,\"endMonth\":2,\"optimalConditions\":\"Cool, dry climate\",\"zoneName\":\"Central India\",\"active\":true}"]}' \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt

sleep 2

# Create Harvest Limit for Farmer FARM001
echo -e "${GREEN}→ Creating harvest limit for Farmer FARM001${NC}"
docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"CreateHarvestLimit","Args":["{\"farmerId\":\"FARM001\",\"farmerName\":\"Rajesh Kumar\",\"species\":\"Ashwagandha\",\"maxQuantity\":500,\"unit\":\"kg\",\"season\":\"Winter-2025\",\"zoneName\":\"Madhya Pradesh\",\"active\":true}"]}' \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt

sleep 2

# ==============================================================================
# PHASE 2: Collection Event (Farmer harvests herbs)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 2] Creating Collection Event${NC}"

echo -e "${GREEN}→ Farmer FARM001 harvests 50kg Ashwagandha${NC}"
COLLECTION_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"CreateCollectionEvent","Args":["{\"farmerId\":\"FARM001\",\"farmerName\":\"Rajesh Kumar\",\"species\":\"Ashwagandha\",\"commonName\":\"Indian Ginseng\",\"scientificName\":\"Withania somnifera\",\"quantity\":50,\"unit\":\"kg\",\"harvestDate\":\"2025-11-30\",\"timestamp\":\"2025-11-30T10:00:00Z\",\"latitude\":23.2599,\"longitude\":77.4126,\"altitude\":500,\"accuracy\":5,\"harvestMethod\":\"manual\",\"partCollected\":\"roots\",\"weatherConditions\":\"Temperature: 22°C, Humidity: 55%, Conditions: Clear\",\"images\":[\"Qm...\"],\"approvedZone\":true,\"zoneName\":\"Madhya Pradesh\",\"conservationStatus\":\"LC\",\"status\":\"pending\"}"]}' \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt 2>&1)

echo "$COLLECTION_RESULT"
COLLECTION_ID=$(echo "$COLLECTION_RESULT" | grep -o 'CE-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Collection Event ID: ${COLLECTION_ID}${NC}"

sleep 3

# ==============================================================================
# PHASE 3: Batch Creation
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 3] Creating Batch${NC}"

echo -e "${GREEN}→ Creating batch from collection event ${COLLECTION_ID}${NC}"
BATCH_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"CreateBatch\",\"Args\":[\"{\\\"farmerId\\\":\\\"FARM001\\\",\\\"farmerName\\\":\\\"Rajesh Kumar\\\",\\\"species\\\":\\\"Ashwagandha\\\",\\\"totalQuantity\\\":50,\\\"unit\\\":\\\"kg\\\",\\\"collectionEventIds\\\":[\\\"${COLLECTION_ID}\\\"],\\\"harvestStartDate\\\":\\\"2025-11-30\\\",\\\"harvestEndDate\\\":\\\"2025-11-30\\\",\\\"createdDate\\\":\\\"2025-11-30T10:30:00Z\\\",\\\"status\\\":\\\"collected\\\"}\"]}" \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt 2>&1)

echo "$BATCH_RESULT"
BATCH_ID=$(echo "$BATCH_RESULT" | grep -o 'BATCH-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Batch ID: ${BATCH_ID}${NC}"

sleep 3

# Verify batch created
echo -e "${GREEN}→ Verifying batch ${BATCH_ID}${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"GetBatch\",\"Args\":[\"${BATCH_ID}\"]}"

sleep 2

# ==============================================================================
# PHASE 4: Quality Testing (Lab tests the batch)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 4] Quality Testing${NC}"

echo -e "${GREEN}→ Lab LAB001 testing batch ${BATCH_ID}${NC}"
QUALITY_TEST_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"CreateQualityTest\",\"Args\":[\"{\\\"collectionEventId\\\":\\\"${COLLECTION_ID}\\\",\\\"batchId\\\":\\\"${BATCH_ID}\\\",\\\"labId\\\":\\\"LAB001\\\",\\\"labName\\\":\\\"Central Testing Lab\\\",\\\"testDate\\\":\\\"2025-11-30\\\",\\\"timestamp\\\":\\\"2025-11-30T12:00:00Z\\\",\\\"testTypes\\\":[\\\"moisture\\\",\\\"pesticide\\\",\\\"heavy_metals\\\",\\\"dna_barcode\\\"],\\\"moistureContent\\\":8.5,\\\"pesticideResults\\\":{\\\"Chlorpyrifos\\\":\\\"pass\\\",\\\"Malathion\\\":\\\"pass\\\"},\\\"heavyMetals\\\":{\\\"Lead\\\":0.5,\\\"Mercury\\\":0.1,\\\"Cadmium\\\":0.2},\\\"dnaBarcodeMatch\\\":true,\\\"dnaSequence\\\":\\\"ATCG...\\\",\\\"microbialLoad\\\":100,\\\"aflatoxins\\\":2.5,\\\"overallResult\\\":\\\"pass\\\",\\\"certificateId\\\":\\\"CERT-2025-001\\\",\\\"certificateUrl\\\":\\\"https://ipfs.io/ipfs/Qm...\\\",\\\"testerName\\\":\\\"Dr. Sharma\\\",\\\"status\\\":\\\"pending\\\"}\" ]}" \
  --peerAddresses peer0.labs.herbaltrace.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt 2>&1)

echo "$QUALITY_TEST_RESULT"
TEST_ID=$(echo "$QUALITY_TEST_RESULT" | grep -o 'TEST-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Quality Test ID: ${TEST_ID}${NC}"

sleep 3

# ==============================================================================
# PHASE 5: Processing Steps (Drying, Grinding)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 5] Processing Steps${NC}"

# Assign batch to processor
echo -e "${GREEN}→ Assigning batch ${BATCH_ID} to processor PROC001${NC}"
docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"AssignBatchToProcessor\",\"Args\":[\"${BATCH_ID}\",\"PROC001\",\"HerbalTech Processors\",\"Admin001\"]}" \
  --peerAddresses peer0.processors.herbaltrace.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt

sleep 2

# Create Processing Step 1: Drying
echo -e "${GREEN}→ Processing Step 1: Drying${NC}"
PROCESSING1_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"CreateProcessingStep\",\"Args\":[\"{\\\"previousStepId\\\":\\\"${TEST_ID}\\\",\\\"batchId\\\":\\\"${BATCH_ID}\\\",\\\"processorId\\\":\\\"PROC001\\\",\\\"processorName\\\":\\\"HerbalTech Processors\\\",\\\"processType\\\":\\\"drying\\\",\\\"processDate\\\":\\\"2025-11-30\\\",\\\"timestamp\\\":\\\"2025-11-30T14:00:00Z\\\",\\\"inputQuantity\\\":50,\\\"outputQuantity\\\":45,\\\"unit\\\":\\\"kg\\\",\\\"temperature\\\":50,\\\"duration\\\":48,\\\"equipment\\\":\\\"Industrial Dryer Model-500\\\",\\\"parameters\\\":{\\\"airflow\\\":\\\"medium\\\",\\\"humidity\\\":\\\"low\\\"},\\\"qualityChecks\\\":[\\\"moisture_check\\\",\\\"color_check\\\"],\\\"operatorId\\\":\\\"OP001\\\",\\\"operatorName\\\":\\\"Suresh Patel\\\",\\\"location\\\":\\\"Processing Unit A\\\",\\\"latitude\\\":23.2700,\\\"longitude\\\":77.4200,\\\"status\\\":\\\"completed\\\"}\" ]}" \
  --peerAddresses peer0.processors.herbaltrace.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt 2>&1)

echo "$PROCESSING1_RESULT"
PROCESSING1_ID=$(echo "$PROCESSING1_RESULT" | grep -o 'PROC-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Processing Step 1 ID: ${PROCESSING1_ID}${NC}"

sleep 3

# Create Processing Step 2: Grinding
echo -e "${GREEN}→ Processing Step 2: Grinding${NC}"
PROCESSING2_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"CreateProcessingStep\",\"Args\":[\"{\\\"previousStepId\\\":\\\"${PROCESSING1_ID}\\\",\\\"batchId\\\":\\\"${BATCH_ID}\\\",\\\"processorId\\\":\\\"PROC001\\\",\\\"processorName\\\":\\\"HerbalTech Processors\\\",\\\"processType\\\":\\\"grinding\\\",\\\"processDate\\\":\\\"2025-11-30\\\",\\\"timestamp\\\":\\\"2025-11-30T16:00:00Z\\\",\\\"inputQuantity\\\":45,\\\"outputQuantity\\\":43,\\\"unit\\\":\\\"kg\\\",\\\"parameters\\\":{\\\"meshSize\\\":\\\"80\\\",\\\"speed\\\":\\\"medium\\\"},\\\"equipment\\\":\\\"Grinder Model-800\\\",\\\"qualityChecks\\\":[\\\"particle_size_check\\\"],\\\"operatorId\\\":\\\"OP002\\\",\\\"operatorName\\\":\\\"Amit Singh\\\",\\\"location\\\":\\\"Processing Unit B\\\",\\\"latitude\\\":23.2700,\\\"longitude\\\":77.4200,\\\"status\\\":\\\"completed\\\"}\" ]}" \
  --peerAddresses peer0.processors.herbaltrace.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt 2>&1)

echo "$PROCESSING2_RESULT"
PROCESSING2_ID=$(echo "$PROCESSING2_RESULT" | grep -o 'PROC-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Processing Step 2 ID: ${PROCESSING2_ID}${NC}"

sleep 3

# ==============================================================================
# PHASE 6: Product Creation (Manufacturer creates final product)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 6] Product Creation${NC}"

echo -e "${GREEN}→ Manufacturer MFG001 creating final product${NC}"
PRODUCT_RESULT=$(docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls --cafile $ORDERER_CA \
  -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"CreateProduct\",\"Args\":[\"{\\\"productName\\\":\\\"Ashwagandha Powder Premium\\\",\\\"productType\\\":\\\"powder\\\",\\\"manufacturerId\\\":\\\"MFG001\\\",\\\"manufacturerName\\\":\\\"AyurHealth Products\\\",\\\"batchId\\\":\\\"${BATCH_ID}\\\",\\\"manufactureDate\\\":\\\"2025-11-30\\\",\\\"expiryDate\\\":\\\"2027-11-30\\\",\\\"quantity\\\":43,\\\"unit\\\":\\\"kg\\\",\\\"qrCode\\\":\\\"QR-${BATCH_ID}\\\",\\\"ingredients\\\":[\\\"Ashwagandha Root Powder (100%)\\\"],\\\"collectionEventIds\\\":[\\\"${COLLECTION_ID}\\\"],\\\"qualityTestIds\\\":[\\\"${TEST_ID}\\\"],\\\"processingStepIds\\\":[\\\"${PROCESSING1_ID}\\\",\\\"${PROCESSING2_ID}\\\"],\\\"certifications\\\":[\\\"Organic\\\",\\\"AYUSH Certified\\\"],\\\"packagingDate\\\":\\\"2025-11-30\\\",\\\"status\\\":\\\"manufactured\\\",\\\"timestamp\\\":\\\"2025-11-30T18:00:00Z\\\"}\" ]}" \
  --peerAddresses peer0.manufacturers.herbaltrace.com:13051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt 2>&1)

echo "$PRODUCT_RESULT"
PRODUCT_ID=$(echo "$PRODUCT_RESULT" | grep -o 'PROD-[A-Z0-9]*' | head -1)
echo -e "${BLUE}✓ Product ID: ${PRODUCT_ID}${NC}"

sleep 3

# ==============================================================================
# PHASE 7: Query Tests (Test Rich Queries with CouchDB indexes)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 7] Testing Rich Queries${NC}"

# Query batches by status
echo -e "${GREEN}→ Querying batches with status 'collected'${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"QueryBatchesByStatus","Args":["collected"]}'

sleep 1

# Query batches by processor
echo -e "${GREEN}→ Querying batches for processor PROC001${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"QueryBatchesByProcessor","Args":["PROC001"]}'

sleep 1

# Get pending batches
echo -e "${GREEN}→ Getting pending batches${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"GetPendingBatches","Args":[]}'

sleep 1

# Get active alerts
echo -e "${GREEN}→ Getting active alerts${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"GetActiveAlerts","Args":[]}'

sleep 1

# ==============================================================================
# PHASE 8: Provenance Retrieval (Full Traceability)
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 8] Provenance Retrieval${NC}"

echo -e "${GREEN}→ Getting full provenance for product ${PRODUCT_ID}${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c "{\"function\":\"GetProvenance\",\"Args\":[\"${PRODUCT_ID}\"]}"

# ==============================================================================
# PHASE 9: Validation Tests
# ==============================================================================
echo -e "\n${YELLOW}[PHASE 9] Validation Tests${NC}"

# Get harvest statistics
echo -e "${GREEN}→ Getting harvest statistics for Farmer FARM001 (Ashwagandha)${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"GetHarvestStatistics","Args":["FARM001","Ashwagandha","Winter-2025"]}'

sleep 1

# Get season windows
echo -e "${GREEN}→ Getting season windows for Ashwagandha${NC}"
docker exec cli peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME \
  -c '{"function":"GetSeasonWindows","Args":["Ashwagandha"]}'

sleep 1

# ==============================================================================
# PHASE 10: Summary
# ==============================================================================
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Collection Event ID: ${COLLECTION_ID}${NC}"
echo -e "${GREEN}✓ Batch ID: ${BATCH_ID}${NC}"
echo -e "${GREEN}✓ Quality Test ID: ${TEST_ID}${NC}"
echo -e "${GREEN}✓ Processing Step 1 ID: ${PROCESSING1_ID}${NC}"
echo -e "${GREEN}✓ Processing Step 2 ID: ${PROCESSING2_ID}${NC}"
echo -e "${GREEN}✓ Product ID: ${PRODUCT_ID}${NC}"
echo -e "\n${GREEN}All tests completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
