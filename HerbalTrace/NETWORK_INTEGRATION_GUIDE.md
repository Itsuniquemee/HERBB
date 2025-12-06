# HerbalTrace Blockchain Network - API Integration Guide

## Network Overview

**Network Name:** herbaltrace-network  
**Channel:** herbaltrace-channel  
**Chaincode:** herbaltrace v1.0  
**Fabric Version:** 2.5.14  
**Consensus:** RAFT (3 orderers)  

---

## 🏢 Organizations & Peers

### 1. FarmersCoopMSP (Farmers Cooperative)
- **MSP ID:** `FarmersCoopMSP`
- **Peer 0:** `peer0.farmers.herbaltrace.com:7051`
- **Peer 1:** `peer1.farmers.herbaltrace.com:8051`
- **Operations Endpoint:** `peer0.farmers.herbaltrace.com:9446`
- **TLS CA Cert:** `organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt`
- **Admin MSP:** `organizations/peerOrganizations/farmers.herbaltrace.com/users/Admin@farmers.herbaltrace.com/msp`

### 2. TestingLabsMSP (Quality Testing Labs)
- **MSP ID:** `TestingLabsMSP`
- **Peer 0:** `peer0.labs.herbaltrace.com:9051`
- **Peer 1:** `peer1.labs.herbaltrace.com:10051`
- **Operations Endpoint:** `peer0.labs.herbaltrace.com:9448`
- **TLS CA Cert:** `organizations/peerOrganizations/labs.herbaltrace.com/peers/peer0.labs.herbaltrace.com/tls/ca.crt`
- **Admin MSP:** `organizations/peerOrganizations/labs.herbaltrace.com/users/Admin@labs.herbaltrace.com/msp`

### 3. ProcessorsMSP (Herb Processors)
- **MSP ID:** `ProcessorsMSP`
- **Peer 0:** `peer0.processors.herbaltrace.com:11051`
- **Peer 1:** `peer1.processors.herbaltrace.com:12051`
- **Operations Endpoint:** `peer0.processors.herbaltrace.com:9450`
- **TLS CA Cert:** `organizations/peerOrganizations/processors.herbaltrace.com/peers/peer0.processors.herbaltrace.com/tls/ca.crt`
- **Admin MSP:** `organizations/peerOrganizations/processors.herbaltrace.com/users/Admin@processors.herbaltrace.com/msp`

### 4. ManufacturersMSP (Product Manufacturers)
- **MSP ID:** `ManufacturersMSP`
- **Peer 0:** `peer0.manufacturers.herbaltrace.com:13051`
- **Peer 1:** `peer1.manufacturers.herbaltrace.com:14051`
- **Operations Endpoint:** `peer0.manufacturers.herbaltrace.com:9452`
- **TLS CA Cert:** `organizations/peerOrganizations/manufacturers.herbaltrace.com/peers/peer0.manufacturers.herbaltrace.com/tls/ca.crt`
- **Admin MSP:** `organizations/peerOrganizations/manufacturers.herbaltrace.com/users/Admin@manufacturers.herbaltrace.com/msp`

---

## 📡 Orderer Endpoints

### Orderer 1 (Primary)
- **Endpoint:** `orderer.herbaltrace.com:7050`
- **Admin Endpoint:** `orderer.herbaltrace.com:7053`
- **TLS CA Cert:** `organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem`

### Orderer 2
- **Endpoint:** `orderer2.herbaltrace.com:8050`
- **Admin Endpoint:** `orderer2.herbaltrace.com:8053`

### Orderer 3
- **Endpoint:** `orderer3.herbaltrace.com:9050`
- **Admin Endpoint:** `orderer3.herbaltrace.com:9053`

---

## 🔐 TLS Configuration

**TLS Enabled:** Yes (required for all connections)

### Connection Requirements:
1. Client must present TLS certificates
2. Verify peer/orderer certificates using TLS CA certs
3. Set `CORE_PEER_TLS_ENABLED=true`
4. Provide correct `--tlsRootCertFiles` for each peer

---

## 📋 Chaincode Functions (Smart Contract API)

### 1. Collection Events (Farmer Operations)

#### Create Collection Event
```javascript
Function: "CreateCollectionEvent"
Args: [JSON_STRING]

Example JSON:
{
  "id": "COL001",
  "type": "CollectionEvent",
  "farmerId": "FARMER001",
  "farmerName": "Rajesh Kumar",
  "species": "Withania somnifera",
  "commonName": "Ashwagandha",
  "scientificName": "Withania somnifera",
  "quantity": 100.5,
  "unit": "kg",
  "latitude": 26.9124,
  "longitude": 75.7873,
  "altitude": 450.0,
  "accuracy": 5.0,
  "harvestDate": "2025-11-17",
  "timestamp": "2025-11-17T10:00:00Z",
  "harvestMethod": "manual",
  "partCollected": "root",
  "weatherConditions": "Clear sky",
  "soilType": "Sandy loam",
  "approvedZone": true,
  "zoneName": "Rajasthan Zone",
  "conservationStatus": "Least Concern",
  "certificationIds": ["ORG-2025-001"],
  "status": "pending"
}
```

#### Get Collection Event
```javascript
Function: "GetCollectionEvent"
Args: ["COL001"]
Returns: CollectionEvent object
```

### 2. Quality Tests (Lab Operations)

#### Create Quality Test
```javascript
Function: "CreateQualityTest"
Args: [JSON_STRING]

Example JSON:
{
  "id": "QT001",
  "type": "QualityTest",
  "collectionEventId": "COL001",
  "batchId": "BATCH-2025-001",
  "labId": "LAB001",
  "labName": "Ayurvedic Quality Lab",
  "testDate": "2025-11-17",
  "timestamp": "2025-11-17T14:00:00Z",
  "testTypes": ["moisture", "pesticide", "dna_barcode", "heavy_metals"],
  "moistureContent": 8.5,
  "pesticideResults": {"organophosphates": "pass", "pyrethroids": "pass"},
  "heavyMetals": {"lead": 0.5, "mercury": 0.1, "arsenic": 0.3},
  "dnaBarcodeMatch": true,
  "dnaSequence": "ATCG...",
  "microbialLoad": 1000.0,
  "aflatoxins": 5.0,
  "overallResult": "pass",
  "certificateId": "CERT-2025-001",
  "testerName": "Dr. Sharma",
  "status": "approved"
}
```

#### Get Quality Test
```javascript
Function: "GetQualityTest"
Args: ["QT001"]
Returns: QualityTest object
```

### 3. Processing Steps (Processor Operations)

#### Create Processing Step
```javascript
Function: "CreateProcessingStep"
Args: [JSON_STRING]

Example JSON:
{
  "id": "PS001",
  "type": "ProcessingStep",
  "previousStepId": "QT001",
  "batchId": "BATCH-2025-001",
  "processorId": "PROC001",
  "processorName": "Herbal Processing Ltd",
  "processType": "drying_and_grinding",
  "processDate": "2025-11-18",
  "timestamp": "2025-11-18T10:00:00Z",
  "inputQuantity": 100.5,
  "outputQuantity": 85.0,
  "unit": "kg",
  "temperature": 45.0,
  "duration": 24.0,
  "equipment": "Industrial Dryer",
  "parameters": {"humidity": "40%", "airflow": "high"},
  "qualityChecks": ["visual_inspection", "moisture_check"],
  "operatorId": "OP001",
  "operatorName": "Suresh Patel",
  "location": "Jaipur",
  "latitude": 26.9124,
  "longitude": 75.7873,
  "status": "completed"
}
```

#### Get Processing Step
```javascript
Function: "GetProcessingStep"
Args: ["PS001"]
Returns: ProcessingStep object
```

### 4. Products (Manufacturer Operations)

#### Create Product
```javascript
Function: "CreateProduct"
Args: [JSON_STRING]

Example JSON:
{
  "id": "PROD001",
  "type": "Product",
  "productName": "Premium Ashwagandha Powder",
  "productType": "powder",
  "manufacturerId": "MFG001",
  "manufacturerName": "Ayurvedic Wellness Ltd",
  "batchId": "BATCH-2025-001",
  "manufactureDate": "2025-11-19",
  "expiryDate": "2027-11-19",
  "quantity": 85.0,
  "unit": "kg",
  "qrCode": "QR-PROD001-2025",
  "ingredients": ["Withania somnifera root powder"],
  "collectionEventIds": ["COL001"],
  "qualityTestIds": ["QT001"],
  "processingStepIds": ["PS001"],
  "certifications": ["Organic", "AYUSH Certified"],
  "packagingDate": "2025-11-19",
  "status": "manufactured",
  "timestamp": "2025-11-19T10:00:00Z"
}
```

#### Get Product
```javascript
Function: "GetProduct"
Args: ["PROD001"]
Returns: Product object
```

#### Get Product by QR Code (Consumer Scan)
```javascript
Function: "GetProductByQRCode"
Args: ["QR-PROD001-2025"]
Returns: Product object
Note: Requires CouchDB for rich queries (currently using LevelDB)
Alternative: Use GetProduct with product ID encoded in QR
```

### 5. Provenance & Traceability

#### Generate Provenance
```javascript
Function: "GenerateProvenance"
Args: ["PROD001"]
Returns: Complete supply chain history bundle including:
  - Collection events
  - Quality tests
  - Processing steps
  - Final product
  - Sustainability score
  - Total distance traveled
```

---

## 🚀 Sample Integration Code

### Node.js (Fabric SDK)

```javascript
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

async function connectToNetwork(orgName, userName) {
    // Load connection profile
    const ccpPath = path.resolve(__dirname, 'connection-profile.json');
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

    // Create wallet
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    // Check if user exists in wallet
    const identity = await wallet.get(userName);
    if (!identity) {
        throw new Error(`Identity ${userName} not found in wallet`);
    }

    // Connect to gateway
    const gateway = new Gateway();
    await gateway.connect(ccp, {
        wallet,
        identity: userName,
        discovery: { enabled: true, asLocalhost: false }
    });

    // Get network and contract
    const network = await gateway.getNetwork('herbaltrace-channel');
    const contract = network.getContract('herbaltrace');

    return { gateway, contract };
}

// Create collection event
async function createCollectionEvent(collectionData) {
    const { gateway, contract } = await connectToNetwork('FarmersCoopMSP', 'farmer1');
    
    try {
        await contract.submitTransaction(
            'CreateCollectionEvent',
            JSON.stringify(collectionData)
        );
        console.log('Collection event created successfully');
    } finally {
        gateway.disconnect();
    }
}

// Query product
async function getProduct(productId) {
    const { gateway, contract } = await connectToNetwork('FarmersCoopMSP', 'user1');
    
    try {
        const result = await contract.evaluateTransaction('GetProduct', productId);
        return JSON.parse(result.toString());
    } finally {
        gateway.disconnect();
    }
}

// Generate provenance
async function getProvenance(productId) {
    const { gateway, contract } = await connectToNetwork('FarmersCoopMSP', 'user1');
    
    try {
        const result = await contract.submitTransaction('GenerateProvenance', productId);
        return JSON.parse(result.toString());
    } finally {
        gateway.disconnect();
    }
}
```

### REST API Example (Express.js)

```javascript
const express = require('express');
const app = express();
app.use(express.json());

// Create collection endpoint
app.post('/api/collections', async (req, res) => {
    try {
        await createCollectionEvent(req.body);
        res.status(201).json({ success: true, message: 'Collection created' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get product endpoint
app.get('/api/products/:id', async (req, res) => {
    try {
        const product = await getProduct(req.params.id);
        res.json(product);
    } catch (error) {
        res.status(404).json({ error: 'Product not found' });
    }
});

// QR code scan endpoint
app.get('/api/scan/:qrCode', async (req, res) => {
    try {
        // Extract product ID from QR code
        const productId = req.params.qrCode.replace('QR-', '').split('-')[0];
        const provenance = await getProvenance(productId);
        res.json(provenance);
    } catch (error) {
        res.status(404).json({ error: 'Product not found' });
    }
});

app.listen(3000, () => console.log('API running on port 3000'));
```

---

## 📱 Mobile App Integration

### QR Code Format
```
QR-PROD001-2025
Format: QR-{PRODUCT_ID}-{YEAR}
```

### Consumer Scan Flow
1. User scans QR code on product
2. App extracts product ID from QR
3. App calls blockchain via REST API
4. Display provenance: farm → lab → processor → manufacturer
5. Show certifications, test results, sustainability score

---

## 🔑 Security & Authentication

### For Production:
1. **Fabric CA Integration:** Use Fabric CA for certificate management
2. **User Enrollment:** Register users with appropriate roles
3. **API Gateway:** Add JWT authentication for REST API
4. **Rate Limiting:** Implement rate limits on API endpoints
5. **Input Validation:** Validate all JSON inputs before submitting to blockchain

### Certificate Locations:
```
network/organizations/
├── ordererOrganizations/
│   └── herbaltrace.com/
│       ├── ca/
│       ├── msp/
│       ├── orderers/
│       └── users/
└── peerOrganizations/
    ├── farmers.herbaltrace.com/
    ├── labs.herbaltrace.com/
    ├── processors.herbaltrace.com/
    └── manufacturers.herbaltrace.com/
        ├── ca/
        ├── msp/
        ├── peers/
        └── users/
            ├── Admin@{org}/msp/
            └── User1@{org}/msp/
```

---

## 🧪 Testing & Verification

### Test Script
```bash
# Run complete end-to-end test
./network/scripts/test-final.sh
```

### Verified Features:
✅ Farmer collection event creation  
✅ Quality test recording  
✅ Processing step tracking  
✅ Product manufacturing  
✅ Product retrieval by ID  
✅ Complete provenance generation  

---

## 📊 Monitoring & Operations

### Check Network Health
```bash
# View all containers
docker ps

# Check peer logs
docker logs peer0.farmers.herbaltrace.com

# Check chaincode containers
docker ps --filter 'name=dev-peer'

# Query committed chaincode
docker exec cli peer lifecycle chaincode querycommitted \
  --channelID herbaltrace-channel --name herbaltrace
```

### Metrics Endpoints
- Peer metrics: `http://peer0.farmers.herbaltrace.com:9446/metrics`
- Orderer metrics: `http://orderer.herbaltrace.com:9443/metrics`

---

## 🔄 Data Flow Summary

```
FARMER (Mobile App)
    ↓ CreateCollectionEvent
[BLOCKCHAIN - COL001]
    ↓
TESTING LAB (Web Portal)
    ↓ CreateQualityTest
[BLOCKCHAIN - QT001]
    ↓
PROCESSOR (Web Portal)
    ↓ CreateProcessingStep
[BLOCKCHAIN - PS001]
    ↓
MANUFACTURER (Web Portal)
    ↓ CreateProduct + QR Code
[BLOCKCHAIN - PROD001]
    ↓
CONSUMER (Mobile App)
    ↓ Scan QR Code → GetProduct/GenerateProvenance
[BLOCKCHAIN - Full Trace back History]
```

---

## 📞 Support & Next Steps

### Ready for Integration:
1. ✅ Network is running and tested
2. ✅ Chaincode functions verified
3. ✅ Sample data flow tested
4. ✅ QR code mechanism defined

### Recommended Next Steps:
1. Set up Fabric SDK in your web portal backend
2. Create user enrollment/registration system
3. Build REST API layer (Express.js/FastAPI)
4. Develop mobile app with QR scanner
5. Add Fabric CA for production certificate management
6. Consider migrating to CouchDB for rich queries

---

**Network Status:** ✅ READY FOR PRODUCTION INTEGRATION  
**Test Date:** November 17, 2025  
**Fabric Version:** 2.5.14  
**Documentation Version:** 1.0
