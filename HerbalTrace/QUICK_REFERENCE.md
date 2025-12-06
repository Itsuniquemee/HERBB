# HerbalTrace - Quick Reference Card

## 🚀 Start/Stop Network

```bash
# Start all services
cd /mnt/d/Trial/HerbalTrace/network/docker
docker compose -f docker-compose-herbaltrace.yaml up -d

# Stop all services
docker compose -f docker-compose-herbaltrace.yaml down

# Restart services
docker compose -f docker-compose-herbaltrace.yaml restart

# View logs
docker logs -f peer0.farmers.herbaltrace.com
docker logs -f orderer.herbaltrace.com
```

## 📡 Quick Test Commands

```bash
# Test complete flow
/mnt/d/Trial/HerbalTrace/network/scripts/test-final.sh

# Query a product
docker exec cli peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetProduct","Args":["PROD001"]}'

# Create new collection (example)
docker exec cli peer chaincode invoke \
  -o orderer.herbaltrace.com:7050 \
  --ordererTLSHostnameOverride orderer.herbaltrace.com \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/herbaltrace.com/orderers/orderer.herbaltrace.com/msp/tlscacerts/tlsca.herbaltrace.com-cert.pem \
  -C herbaltrace-channel \
  -n herbaltrace \
  --peerAddresses peer0.farmers.herbaltrace.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/farmers.herbaltrace.com/peers/peer0.farmers.herbaltrace.com/tls/ca.crt \
  -c '{"function":"CreateCollectionEvent","Args":["{\"id\":\"COL002\",\"farmerId\":\"FARMER002\",\"species\":\"Tulsi\",\"quantity\":50,\"latitude\":28.7041,\"longitude\":77.1025}"]}'
```

## 🏢 Network Endpoints

| Organization | Peer Address | Port |
|--------------|--------------|------|
| FarmersCoopMSP | peer0.farmers.herbaltrace.com | 7051 |
| TestingLabsMSP | peer0.labs.herbaltrace.com | 9051 |
| ProcessorsMSP | peer0.processors.herbaltrace.com | 11051 |
| ManufacturersMSP | peer0.manufacturers.herbaltrace.com | 13051 |

| Orderer | Endpoint | Port |
|---------|----------|------|
| Orderer1 | orderer.herbaltrace.com | 7050 |
| Orderer2 | orderer2.herbaltrace.com | 8050 |
| Orderer3 | orderer3.herbaltrace.com | 9050 |

## 📋 Chaincode Functions

### Write Operations (Invoke)
- `CreateCollectionEvent` - Farmer creates harvest record
- `CreateQualityTest` - Lab records test results
- `CreateProcessingStep` - Processor records processing
- `CreateProduct` - Manufacturer creates product with QR
- `GenerateProvenance` - Generate full supply chain history

### Read Operations (Query)
- `GetCollectionEvent` - Get harvest record by ID
- `GetQualityTest` - Get test result by ID
- `GetProcessingStep` - Get processing record by ID
- `GetProduct` - Get product by ID
- `GetProductByQRCode` - Get product by QR (needs CouchDB)

## 🔑 Key File Locations

```
HerbalTrace/
├── chaincode/herbaltrace/main.go          # Smart contract code
├── network/
│   ├── docker/docker-compose-herbaltrace.yaml  # Network config
│   ├── peercfg/core.yaml                  # Peer configuration
│   ├── organizations/                     # Certificates & MSP
│   └── scripts/
│       └── test-final.sh                  # E2E test script
└── NETWORK_INTEGRATION_GUIDE.md           # Full API docs
```

## 🔧 Troubleshooting

### Check container status
```bash
docker ps -a | grep herbaltrace
```

### View chaincode containers
```bash
docker ps --filter 'name=dev-peer'
```

### Check chaincode installation
```bash
docker exec cli peer lifecycle chaincode queryinstalled
```

### Check chaincode commitment
```bash
docker exec cli peer lifecycle chaincode querycommitted \
  --channelID herbaltrace-channel --name herbaltrace
```

### Restart if issues
```bash
cd /mnt/d/Trial/HerbalTrace/network/docker
docker compose -f docker-compose-herbaltrace.yaml restart
```

## 📊 Network Status Check

```bash
# Check all 12 containers are running
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep herbaltrace

# Should show:
# - 3 orderers (orderer, orderer2, orderer3)
# - 8 peers (2 per org x 4 orgs)
# - 1 CLI container
```

## 🎯 Sample Data IDs

Test data created by `test-final.sh`:
- Collection: `COL001` (Ashwagandha, 100.5kg, Rajesh Kumar)
- Quality Test: `QT001` (Pass, Dr. Sharma)
- Processing: `PS001` (85kg processed, Herbal Processing Ltd)
- Product: `PROD001` (QR: QR-PROD001-2025, Ashwagandha Powder)

## 🌐 For Web Portal/App Development

### API Endpoints to Implement:
```
POST   /api/collections       # Create harvest record
POST   /api/quality-tests     # Record lab test
POST   /api/processing        # Record processing step
POST   /api/products          # Create product
GET    /api/products/:id      # Get product details
GET    /api/scan/:qrCode      # Consumer QR scan
GET    /api/provenance/:id    # Get full trace history
```

### QR Code Format:
```
QR-{PRODUCT_ID}-{YEAR}
Example: QR-PROD001-2025
```

### Integration Steps:
1. Set up Fabric Node SDK in your backend
2. Load connection profile & certificates
3. Create wallet with user identities
4. Connect to gateway and get contract
5. Submit/evaluate transactions
6. Return JSON responses to frontend/mobile

---

**Network:** ✅ OPERATIONAL  
**Chaincode:** ✅ COMMITTED  
**Tests:** ✅ PASSED  
**Ready for:** Web Portal & Mobile App Integration
