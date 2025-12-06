# HerbalTrace - Complete Blockchain Flow & Implementation Guide

## 📋 Table of Contents
1. [Blockchain Architecture Overview](#blockchain-architecture-overview)
2. [Complete Data Flow](#complete-data-flow)
3. [Chaincode Features (Already Implemented)](#chaincode-features-already-implemented)
4. [Missing Backend Implementations](#missing-backend-implementations)
5. [Step-by-Step Implementation Plan](#step-by-step-implementation-plan)
6. [Network Setup & Deployment](#network-setup--deployment)
7. [Testing Strategy](#testing-strategy)
8. [API Documentation](#api-documentation)

---

## 🏗️ Blockchain Architecture Overview

### Network Components
```
┌─────────────────────────────────────────────────────────────┐
│                    HerbalTrace Network                       │
├─────────────────────────────────────────────────────────────┤
│  Organizations:                                              │
│  • Org1MSP (Farmers/Collectors)                            │
│  • Org2MSP (Quality Labs)                                   │
│  • Org3MSP (Processors/Manufacturers)                       │
│                                                              │
│  Peers: 2 per organization (6 total)                        │
│  Orderer: Raft consensus (3 orderers)                      │
│  Channel: herbaltrace-channel                              │
│  Chaincode: herbaltrace                                     │
└─────────────────────────────────────────────────────────────┘
```

### Data Models (All Implemented in Chaincode)
1. **CollectionEvent** - Harvest/Collection data with GPS
2. **QualityTest** - Lab testing results
3. **ProcessingStep** - Manufacturing/processing steps
4. **Product** - Final product with QR code
5. **Provenance** - Complete supply chain history

---

## 🔄 Complete Data Flow

### Phase 1: Collection/Harvest
```
Farmer (Mobile App) 
  ↓
  Creates CollectionEvent with:
  • GPS coordinates (lat, lon, altitude, accuracy)
  • Species details (common name, scientific name)
  • Quantity, unit, harvest method
  • Part collected (leaf, root, flower, seed)
  • Weather conditions, soil type
  • Images (IPFS hashes)
  • Harvest date & timestamp
  ↓
Blockchain Validation:
  • Geo-fencing check (approved zones)
  • Conservation status validation
  • Quantity limits check
  ↓
Status: pending/verified/rejected
  ↓
NextStepID → Links to QualityTest
```

### Phase 2: Quality Testing
```
Lab Technician (Web Portal)
  ↓
  Creates QualityTest with:
  • Collection Event ID reference
  • Batch ID
  • Test types (moisture, pesticide, DNA, heavy metals)
  • Detailed test results:
    - Moisture content (%)
    - Pesticide results (pass/fail per pesticide)
    - Heavy metals (ppm values)
    - DNA barcode match
    - Microbial load (CFU/g)
    - Aflatoxins (ppb)
  • Certificate ID & URL
  • Tester name & signature
  ↓
Blockchain Validation:
  • Moisture < 12%
  • All pesticides pass
  • Heavy metals within limits:
    - Lead < 10 ppm
    - Arsenic < 3 ppm
    - Mercury < 1 ppm
    - Cadmium < 0.3 ppm
  • Aflatoxins < 20 ppb
  ↓
Overall Result: pass/fail/conditional
  ↓
NextStepID → Links to ProcessingStep
```

### Phase 3: Processing/Manufacturing
```
Processor (Web Portal)
  ↓
  Creates ProcessingStep with:
  • Previous Step ID (QualityTest)
  • Batch ID
  • Process type (drying, grinding, extraction, formulation)
  • Process date & timestamp
  • Input/Output quantities with unit
  • Processing parameters:
    - Temperature (°C)
    - Duration (hours)
    - Equipment used
    - Custom parameters (map)
  • Quality checks
  • Operator details
  • Location (GPS coordinates)
  ↓
Status: in_progress/completed/failed
  ↓
NextStepID → Links to next ProcessingStep or Product
```

### Phase 4: Product Creation
```
Manufacturer (Web Portal)
  ↓
  Creates Product with:
  • Product name & type (powder, extract, capsule, oil)
  • Manufacturer details
  • Batch ID
  • Manufacture date & expiry date
  • Quantity & unit
  • QR Code (unique identifier)
  • Ingredients list
  • Complete trace IDs:
    - CollectionEventIDs[]
    - QualityTestIDs[]
    - ProcessingStepIDs[]
  • Certifications (Organic, Fair Trade, AYUSH)
  • Packaging date
  ↓
Status: manufactured/distributed/sold
  ↓
Generates unique QR code for consumer scanning
```

### Phase 5: Provenance Generation
```
Consumer (Mobile App)
  ↓
  Scans QR Code
  ↓
Blockchain Query:
  • GetProvenanceByQRCode()
  ↓
Returns Complete Provenance:
  • Product details
  • All Collection Events (multiple sources)
  • All Quality Tests
  • All Processing Steps
  • Sustainability Score (0-100)
  • Total Distance traveled (km)
  ↓
Displayed in user-friendly format with timeline
```

---

## ✅ Chaincode Features (Already Implemented)

### 1. Data Creation Functions
- ✅ `CreateCollectionEvent(eventJSON)` - Records harvest events
- ✅ `CreateQualityTest(testJSON)` - Records lab tests
- ✅ `CreateProcessingStep(stepJSON)` - Records processing
- ✅ `CreateProduct(productJSON)` - Creates final product

### 2. Data Retrieval Functions
- ✅ `GetCollectionEvent(id)` - Get single collection event
- ✅ `GetQualityTest(id)` - Get single quality test
- ✅ `GetProcessingStep(id)` - Get single processing step
- ✅ `GetProduct(id)` - Get product by ID
- ✅ `GetProductByQRCode(qrCode)` - Get product by QR code

### 3. Provenance Functions
- ✅ `GenerateProvenance(productID)` - Build complete history
- ✅ `GetProvenanceByQRCode(qrCode)` - Consumer-facing API

### 4. Query Functions
- ✅ `QueryCollectionsByFarmer(farmerID)` - Get all farmer collections
- ✅ `QueryCollectionsBySpecies(species)` - Get all collections by species

### 5. Validation Functions (Internal)
- ✅ `validateGeoFencing(lat, lon, species)` - Zone validation
- ✅ `validateConservationLimits(species, quantity)` - Conservation checks
- ✅ `validateQualityGates(test)` - Quality threshold validation
- ✅ `calculateSustainabilityScore(provenance)` - Sustainability scoring

### 6. Additional Required Functions (To Be Added)
```go
// Batch Management
- GetAllProductsByBatch(batchID)
- GetBatchHistory(batchID)
- UpdateBatchStatus(batchID, status)

// Advanced Queries
- QueryCollectionsByDateRange(startDate, endDate)
- QueryCollectionsByZone(zoneName)
- QueryQualityTestsByLab(labID)
- QueryQualityTestsByResult(result) // pass/fail
- QueryProcessingStepsByProcessor(processorID)
- QueryProcessingStepsByType(processType)
- QueryProductsByManufacturer(manufacturerID)
- QueryProductsByDateRange(startDate, endDate)

// Analytics Functions
- GetFarmerStatistics(farmerID)
- GetSpeciesStatistics(species)
- GetLabStatistics(labID)
- GetProcessorStatistics(processorID)
- GetOverallNetworkStatistics()

// Update Functions
- UpdateCollectionEventStatus(id, status)
- UpdateQualityTestStatus(id, status)
- UpdateProcessingStepStatus(id, status)
- UpdateProductStatus(id, status)

// Search Functions
- SearchProducts(criteria)
- SearchCollectionEvents(criteria)
- GetRecentActivity(limit)

// Certification Management
- AddCertificationToCollection(eventID, certificationID)
- VerifyCertification(certificationID)
- GetCertificationHistory(certificationID)

// Alert/Notification Functions
- CreateAlert(alertJSON)
- GetAlertsByType(alertType)
- ResolveAlert(alertID)
```

---

## ❌ Missing Backend Implementations

### Current Backend Status
The backend has route files but likely missing implementations for:

1. **Fabric Connection Management**
   - Gateway connection setup
   - Wallet management
   - Identity management
   - Channel/contract initialization

2. **API Endpoints (Need Full Implementation)**
   - Collection endpoints (partially implemented?)
   - Quality test endpoints
   - Processing endpoints
   - Product endpoints
   - Provenance endpoints
   - Analytics endpoints
   - QR code endpoints

3. **Authentication & Authorization**
   - User roles (Farmer, Lab, Processor, Manufacturer, Consumer)
   - JWT token management
   - Role-based access control (RBAC)

4. **Business Logic Layer**
   - Data validation before blockchain submission
   - Error handling
   - Transaction retry logic
   - Batch processing

5. **Middleware**
   - Authentication middleware
   - Authorization middleware
   - Request validation
   - Rate limiting (partially implemented)

---

## 🎯 Step-by-Step Implementation Plan

### Step 1: Complete Chaincode Enhancement (Priority: HIGH)

#### 1.1 Add Missing Functions
Create file: `chaincode/herbaltrace/queries.go`
```go
package main

// All query functions
func (c *HerbalTraceContract) QueryCollectionsByDateRange(...)
func (c *HerbalTraceContract) QueryCollectionsByZone(...)
// ... etc
```

Create file: `chaincode/herbaltrace/analytics.go`
```go
package main

// All analytics functions
func (c *HerbalTraceContract) GetFarmerStatistics(...)
func (c *HerbalTraceContract) GetSpeciesStatistics(...)
// ... etc
```

Create file: `chaincode/herbaltrace/updates.go`
```go
package main

// All update functions
func (c *HerbalTraceContract) UpdateCollectionEventStatus(...)
func (c *HerbalTraceContract) UpdateProductStatus(...)
// ... etc
```

#### 1.2 Add Batch Management
```go
type Batch struct {
    ID                  string   `json:"id"`
    Type                string   `json:"type"` // "Batch"
    Species             string   `json:"species"`
    TotalQuantity       float64  `json:"totalQuantity"`
    Unit                string   `json:"unit"`
    CollectionEventIDs  []string `json:"collectionEventIds"`
    Status              string   `json:"status"`
    CreatedDate         string   `json:"createdDate"`
    ProcessedDate       string   `json:"processedDate,omitempty"`
}
```

#### 1.3 Add Alert System
```go
type Alert struct {
    ID          string `json:"id"`
    Type        string `json:"type"` // "Alert"
    AlertType   string `json:"alertType"` // "conservation", "quality", "zone_violation"
    Severity    string `json:"severity"` // "low", "medium", "high", "critical"
    EntityID    string `json:"entityId"`
    EntityType  string `json:"entityType"`
    Message     string `json:"message"`
    Timestamp   string `json:"timestamp"`
    Status      string `json:"status"` // "active", "acknowledged", "resolved"
    ResolvedBy  string `json:"resolvedBy,omitempty"`
    ResolvedDate string `json:"resolvedDate,omitempty"`
}
```

### Step 2: Deploy Enhanced Chaincode

```bash
# Package chaincode
cd network
./scripts/package-chaincode.sh

# Install on all peers
./scripts/install-chaincode.sh

# Approve for all organizations
./scripts/approve-chaincode.sh

# Commit chaincode definition
./scripts/commit-chaincode.sh

# Initialize chaincode
./scripts/init-chaincode.sh
```

### Step 3: Build Backend Infrastructure (Priority: HIGH)

#### 3.1 Fabric Connection Layer
Create: `backend/src/fabric/connection.ts`
```typescript
import { Gateway, Wallets, Network, Contract } from 'fabric-network';
import * as path from 'path';
import * as fs from 'fs';

export class FabricConnection {
  private gateway: Gateway;
  private network: Network;
  private contract: Contract;

  async connect(userId: string, orgName: string) {
    // Load connection profile
    // Connect to gateway
    // Get network and contract
  }

  async disconnect() {
    // Close gateway connection
  }

  getContract(): Contract {
    return this.contract;
  }
}
```

#### 3.2 Implement All Route Controllers
Create: `backend/src/controllers/`
- `collection.controller.ts`
- `quality.controller.ts`
- `processing.controller.ts`
- `product.controller.ts`
- `provenance.controller.ts`
- `analytics.controller.ts`
- `batch.controller.ts`

#### 3.3 Implement Services Layer
Create: `backend/src/services/`
- `collection.service.ts`
- `quality.service.ts`
- `processing.service.ts`
- `product.service.ts`
- `provenance.service.ts`
- `analytics.service.ts`

#### 3.4 Authentication & Authorization
Create: `backend/src/middleware/auth.ts`
```typescript
export const authenticate = async (req, res, next) => {
  // Verify JWT token
  // Attach user to request
};

export const authorize = (...roles: string[]) => {
  return (req, res, next) => {
    // Check user role
  };
};
```

### Step 4: Network Setup & Configuration

#### 4.1 Network Topology
```yaml
Organizations:
  - Org1MSP (Farmers/Collectors)
    - peer0.org1.herbaltrace.com
    - peer1.org1.herbaltrace.com
  
  - Org2MSP (Quality Labs)
    - peer0.org2.herbaltrace.com
    - peer1.org2.herbaltrace.com
  
  - Org3MSP (Processors/Manufacturers)
    - peer0.org3.herbaltrace.com
    - peer1.org3.herbaltrace.com

Orderers:
  - orderer0.herbaltrace.com
  - orderer1.herbaltrace.com
  - orderer2.herbaltrace.com

Channel: herbaltrace-channel
Chaincode: herbaltrace v1.0
```

#### 4.2 Deployment Steps
```bash
# 1. Generate crypto materials
cd network
cryptogen generate --config=./crypto-config.yaml

# 2. Generate genesis block
configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

# 3. Create channel transaction
configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/herbaltrace-channel.tx -channelID herbaltrace-channel

# 4. Generate anchor peer updates
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID herbaltrace-channel -asOrg Org1MSP
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID herbaltrace-channel -asOrg Org2MSP
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID herbaltrace-channel -asOrg Org3MSP

# 5. Start network
docker-compose -f docker/docker-compose.yaml up -d

# 6. Create channel
peer channel create -o orderer0.herbaltrace.com:7050 -c herbaltrace-channel -f ./channel-artifacts/herbaltrace-channel.tx

# 7. Join peers to channel
peer channel join -b herbaltrace-channel.block

# 8. Update anchor peers
peer channel update -o orderer0.herbaltrace.com:7050 -c herbaltrace-channel -f ./channel-artifacts/Org1MSPanchors.tx

# 9. Install and instantiate chaincode (as per Step 2)
```

### Step 5: Testing & Validation

#### 5.1 Chaincode Tests
Create: `chaincode/herbaltrace/main_test.go`
```go
package main

import (
    "testing"
    "github.com/hyperledger/fabric-chaincode-go/shim"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func TestCreateCollectionEvent(t *testing.T) {
    // Test collection event creation
}

func TestValidateGeoFencing(t *testing.T) {
    // Test geo-fencing validation
}

func TestGenerateProvenance(t *testing.T) {
    // Test provenance generation
}
```

#### 5.2 Integration Tests
Create: `backend/tests/integration/`
- `collection.test.ts`
- `quality.test.ts`
- `processing.test.ts`
- `product.test.ts`
- `provenance.test.ts`

#### 5.3 End-to-End Test Scenarios
```
Scenario 1: Complete Supply Chain Flow
1. Farmer creates collection event
2. Lab creates quality test
3. Processor creates processing step
4. Manufacturer creates product
5. Consumer scans QR code
6. Verify complete provenance

Scenario 2: Quality Failure
1. Create collection event
2. Create quality test with failures
3. Verify rejection
4. Check alert generation

Scenario 3: Conservation Violation
1. Attempt to create collection for endangered species
2. Verify rejection
3. Check alert generation

Scenario 4: Analytics
1. Create multiple transactions
2. Query farmer statistics
3. Query species statistics
4. Verify calculations
```

---

## 📚 API Documentation

### Base URL
```
http://localhost:3000/api
```

### Authentication
```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/profile
```

### Collection Events
```
POST   /api/collections                  # Create collection event
GET    /api/collections/:id              # Get single collection
GET    /api/collections                  # Get all collections
GET    /api/collections/farmer/:farmerId # Get by farmer
GET    /api/collections/species/:species # Get by species
GET    /api/collections/date-range       # Get by date range
PATCH  /api/collections/:id/status       # Update status
```

### Quality Tests
```
POST   /api/quality-tests                # Create quality test
GET    /api/quality-tests/:id            # Get single test
GET    /api/quality-tests                # Get all tests
GET    /api/quality-tests/lab/:labId     # Get by lab
GET    /api/quality-tests/result/:result # Get by result
PATCH  /api/quality-tests/:id/status     # Update status
```

### Processing Steps
```
POST   /api/processing                       # Create processing step
GET    /api/processing/:id                   # Get single step
GET    /api/processing                       # Get all steps
GET    /api/processing/processor/:processorId # Get by processor
GET    /api/processing/type/:processType     # Get by type
PATCH  /api/processing/:id/status            # Update status
```

### Products
```
POST   /api/products                         # Create product
GET    /api/products/:id                     # Get single product
GET    /api/products                         # Get all products
GET    /api/products/qr/:qrCode              # Get by QR code
GET    /api/products/manufacturer/:manufacturerId # Get by manufacturer
GET    /api/products/batch/:batchId          # Get by batch
PATCH  /api/products/:id/status              # Update status
```

### Provenance
```
GET    /api/provenance/product/:productId    # Get provenance by product ID
GET    /api/provenance/qr/:qrCode            # Get provenance by QR code
GET    /api/provenance/trace/:entityId       # Trace entity history
```

### Analytics
```
GET    /api/analytics/farmer/:farmerId       # Farmer statistics
GET    /api/analytics/species/:species       # Species statistics
GET    /api/analytics/lab/:labId             # Lab statistics
GET    /api/analytics/processor/:processorId # Processor statistics
GET    /api/analytics/network                # Overall network stats
GET    /api/analytics/dashboard              # Dashboard data
```

### Batches
```
POST   /api/batches                          # Create batch
GET    /api/batches/:id                      # Get batch
GET    /api/batches                          # Get all batches
GET    /api/batches/:id/history              # Get batch history
PATCH  /api/batches/:id/status               # Update batch status
```

### Alerts
```
POST   /api/alerts                           # Create alert
GET    /api/alerts                           # Get all alerts
GET    /api/alerts/:id                       # Get single alert
GET    /api/alerts/type/:alertType           # Get by type
PATCH  /api/alerts/:id/acknowledge           # Acknowledge alert
PATCH  /api/alerts/:id/resolve               # Resolve alert
```

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] Complete all chaincode functions
- [ ] Test chaincode thoroughly
- [ ] Implement all backend endpoints
- [ ] Set up authentication/authorization
- [ ] Configure network properly
- [ ] Set up monitoring and logging
- [ ] Prepare deployment scripts

### Deployment
- [ ] Deploy blockchain network
- [ ] Install and instantiate chaincode
- [ ] Deploy backend API server
- [ ] Configure CORS and security
- [ ] Set up SSL/TLS certificates
- [ ] Configure load balancer (if needed)
- [ ] Set up database for off-chain data (if needed)

### Post-Deployment
- [ ] Run integration tests
- [ ] Run end-to-end tests
- [ ] Monitor network health
- [ ] Set up alerting
- [ ] Document API
- [ ] Train frontend team
- [ ] Provide Postman collection
- [ ] Set up CI/CD pipeline

---

## 📞 Team Collaboration

### For Frontend Team
Provide:
1. **Complete API Documentation** (Swagger/OpenAPI)
2. **Postman Collection** with example requests
3. **API Base URL** (hosted backend)
4. **Authentication Flow** documentation
5. **WebSocket endpoints** (for real-time updates)
6. **Error codes** and handling
7. **Sample responses** for all endpoints

### Development Workflow
```
1. Complete Chaincode ──► Deploy to Test Network
                          │
                          ↓
2. Build Backend ─────────► Test with Chaincode
                          │
                          ↓
3. Deploy Backend ────────► Host on Cloud/Server
                          │
                          ↓
4. Share API Docs ────────► Frontend Integration
                          │
                          ↓
5. Integration Testing ───► Production Deployment
```

---

## 🎯 Next Immediate Steps

### Priority 1 (Do First)
1. ✅ Review this complete blockchain flow
2. Add missing chaincode functions (queries, analytics, updates)
3. Test enhanced chaincode on local network
4. Deploy chaincode to test network

### Priority 2 (Do Second)
1. Build complete backend infrastructure
2. Implement all API endpoints
3. Set up authentication/authorization
4. Test backend with blockchain

### Priority 3 (Do Third)
1. Deploy backend to cloud/server
2. Generate API documentation
3. Create Postman collection
4. Share with frontend team

### Priority 4 (Do Last)
1. Integration testing
2. Performance testing
3. Security audit
4. Production deployment

---

## 📖 Additional Resources

### Documentation to Create
1. **API_DOCUMENTATION.md** - Complete API reference
2. **CHAINCODE_FUNCTIONS.md** - All chaincode functions
3. **DEPLOYMENT_GUIDE.md** - Step-by-step deployment
4. **TESTING_GUIDE.md** - Testing procedures
5. **FRONTEND_INTEGRATION_GUIDE.md** - For frontend team

### Tools & Libraries
- **Hyperledger Fabric SDK**: fabric-network (Node.js)
- **Testing**: Jest, Mocha, Chai
- **API Documentation**: Swagger/OpenAPI
- **Monitoring**: Prometheus, Grafana
- **Logging**: Winston, ELK Stack

---

**Ready to start implementation? Let's begin with enhancing the chaincode!**
