# HerbalTrace - Optimized Workflow Design
**For 36-Hour Hackathon Implementation**

---

## 🎯 Complete System Flow (Optimized)

### **PHASE 0: User Onboarding (Admin-Controlled)**

#### Flow:
```
1. Interested Farmer visits website
   → Fills registration form (name, location, species interest, photos)
   → Request goes to Admin Dashboard

2. Admin reviews request
   → Verifies farmer credentials
   → Assigns initial harvest limits based on species
   → Creates account with role: "Farmer"
   → Generates login credentials
   → System sends SMS/Email with credentials

3. Farmer receives:
   → Username
   → Temporary password
   → Mobile app download link
   → First-time setup instructions
```

**Database Schema:**
```sql
CREATE TABLE registration_requests (
  id UUID PRIMARY KEY,
  full_name VARCHAR(255),
  phone VARCHAR(20),
  email VARCHAR(255),
  location_district VARCHAR(100),
  species_interest TEXT[],
  farm_photos TEXT[], -- URLs
  request_date TIMESTAMP,
  status VARCHAR(20), -- 'pending', 'approved', 'rejected'
  admin_notes TEXT,
  approved_by VARCHAR(100),
  approved_date TIMESTAMP
);
```

**Admin Dashboard Action:**
- View pending registrations
- Approve/Reject with notes
- Set initial harvest limits per farmer per species
- Assign to geographic zone

---

## **PHASE 1: Collection Event (Farmer - Mobile DApp)**

### Current Flow (Your Design):
```
Farmer opens mobile app (offline allowed)
→ GPS captures (lat/long), timestamp
→ Enters: species, quantity, part collected, weather, soil type
→ Takes 3-5 photos of plant/harvest
→ DApp creates FHIR-style CollectionEvent bundle
```

### ✅ **Optimizations:**

#### 1. **Enhanced Validation (Smart Contract)**
```javascript
// Chaincode validation order:
1. ✔ GPS within approved geo-fencing zone
   → Query: IsLocationInApprovedZone(lat, long, species)
   → If not in zone → Create Alert (severity: HIGH)

2. ✔ Seasonal harvesting allowed
   → Query: GetSeasonWindow(species, harvestDate)
   → If outside season → Create Alert (severity: CRITICAL)

3. ✔ Farmer harvest limit not exceeded
   → Query: GetFarmerHarvestUsage(farmerId, species, currentMonth)
   → If exceeded → Create Alert (severity: CRITICAL)
   → Block submission if limit > 120%

4. ✔ Species conservation status check
   → If "Endangered" → Require special certification
   → Auto-flag for regulator review
```

#### 2. **Offline Sync Strategy**
```
Mobile App Logic:
├── Online Mode:
│   └── Submit directly to backend → blockchain
├── Offline Mode:
│   ├── Store in local SQLite with sync_status = 'pending'
│   ├── Generate temporary collection ID: "TEMP-{timestamp}"
│   ├── Queue for sync
│   └── SMS Gateway Option:
│       └── Send compressed JSON via SMS to shortcode
│           → Backend receives SMS → reconstructs JSON → submits
└── Sync on Network:
    └── Check for pending collections → submit in order → update status
```

#### 3. **Idempotency (Critical for Offline)**
```javascript
// Backend checks before blockchain submission:
if (collectionIdExists(collection.id)) {
  if (collection.id.startsWith('TEMP-')) {
    // Offline submission, replace with real ID
    newId = generateUUID();
    collection.id = newId;
  } else {
    // Duplicate, return existing record
    return getCollectionEvent(collection.id);
  }
}
```

**Output:**
```json
{
  "collectionId": "COL-123e4567-e89b",
  "status": "pending_admin_assignment",
  "transactionId": "0x7f8b...",
  "alerts": [
    {
      "type": "HARVEST_LIMIT_WARNING",
      "message": "80% of monthly limit reached"
    }
  ]
}
```

---

## **PHASE 2: Admin Assignment (Backend Dashboard)**

### ✅ **New Feature: Smart Assignment**

#### Flow:
```
1. Admin Dashboard shows:
   ├── Pending Collections (awaiting processor assignment)
   ├── Collections by Species/Location (map view)
   ├── Available Processors (with capacity info)
   └── Recommended Assignments (ML-based)

2. Admin actions:
   ├── Create Batch (group multiple collections)
   │   → Select collections (same species)
   │   → Assign to specific processor
   │   → Set priority (urgent/normal/low)
   │   → Add notes for processor
   │
   ├── Or: Auto-assign based on rules
   │   → Nearest processor with capacity
   │   → Processor specialization match
   │   → Load balancing

3. System creates BatchRecord:
   └── SubmitTransaction('CreateBatch', {
       batchId: "BATCH-{uuid}",
       collectionIds: ["COL-1", "COL-2", ...],
       assignedProcessorId: "PROC-123",
       priority: "normal",
       adminNotes: "...",
       status: "assigned_to_processor"
     })

4. Processor receives notification:
   └── SMS/Email: "New batch BATCH-xyz assigned. Contains 5 collections of Ashwagandha."
```

**Smart Contract Function:**
```go
func (t *HerbalTraceContract) CreateBatch(ctx, batchJSON string) error {
  // Validate:
  // 1. All collectionIds exist and are 'pending'
  // 2. All collections are same species
  // 3. Assigned processor exists and is active
  // 4. Update collection status to 'batched'
  // 5. Create Batch with provenance links
}
```

**Database Schema:**
```sql
CREATE TABLE batches (
  id VARCHAR(50) PRIMARY KEY,
  collection_ids TEXT[], -- Array of COL-xxx
  assigned_processor_id VARCHAR(50),
  species VARCHAR(100),
  total_quantity DECIMAL(10,2),
  priority VARCHAR(20),
  admin_notes TEXT,
  status VARCHAR(50), -- 'assigned', 'in_processing', 'completed'
  assigned_date TIMESTAMP,
  completed_date TIMESTAMP
);
```

---

## **PHASE 3: Processing Steps (Processor Dashboard)**

### Current Flow (Your Design):
```
Processor scans HBID → Creates ProcessingStep
→ Drying (temp, duration)
→ Grinding (machine, settings)
→ Storage (humidity, location)
```

### ✅ **Enhancements:**

#### 1. **Multi-Step Processing Workflow**
```
Processor Dashboard:
├── View Assigned Batches
│   └── Batch details with collection provenance
│
├── Start Processing (Select Batch)
│   ├── Step 1: Drying
│   │   ├── Input: Temperature (°C), Duration (hours), Equipment ID
│   │   ├── Photos: Before/After drying
│   │   ├── Smart Contract Check:
│   │   │   → Temp > 60°C? → Alert (over-drying risk)
│   │   │   → Duration < 4 hours? → Alert (incomplete)
│   │   └── Output: Dried batch weight
│   │
│   ├── Step 2: Grinding
│   │   ├── Input: Machine ID, Mesh size, Duration
│   │   ├── Output: Powder weight (track loss %)
│   │   └── Smart Contract: Loss > 15%? → Alert
│   │
│   ├── Step 3: Storage
│   │   ├── Input: Storage location, Humidity %, Temp
│   │   ├── Smart Contract: Humidity > 12%? → Alert
│   │   └── Status: Ready for Lab Testing
│   │
│   └── Optional: Mixing/Blending
│       └── Combine multiple batches (create new BATCH-MIX-xxx)
```

#### 2. **Real-time Validation**
```javascript
// Smart Contract (ProcessingStep validation):
func (t *HerbalTraceContract) CreateProcessingStep(ctx, stepJSON string) error {
  step := parseProcessingStep(stepJSON);
  
  // Quality Rules:
  if step.ProcessType == "drying" {
    if step.Temperature > 60 {
      createAlert(ctx, "OVER_DRYING_RISK", step.BatchID);
    }
    if step.Moisture > 12 {
      createAlert(ctx, "HIGH_MOISTURE_RISK", step.BatchID);
    }
  }
  
  if step.ProcessType == "grinding" {
    inputQty := getBatchQuantity(step.BatchID);
    loss := (inputQty - step.OutputQuantity) / inputQty * 100;
    if loss > 15 {
      createAlert(ctx, "HIGH_PROCESSING_LOSS", step.BatchID);
    }
  }
  
  // Update batch status
  updateBatchStatus(step.BatchID, "processing_step_completed");
  return ctx.GetStub().PutState(step.ID, stepBytes);
}
```

**Output:**
```json
{
  "processingStepId": "PROC-STEP-123",
  "batchId": "BATCH-456",
  "processType": "drying",
  "status": "completed",
  "transactionId": "0x9a3b...",
  "alerts": []
}
```

---

## **PHASE 4: Lab Testing (Quality Control)**

### Current Flow (Your Design):
```
Lab scans HBID → Enters test results
→ Moisture, Pesticide, DNA, Heavy metals
→ Smart contract validates thresholds
→ QualityTestApproved or QualityTestFailed
```

### ✅ **Optimizations:**

#### 1. **Comprehensive Test Suite**
```
Lab Dashboard:
├── View Batches Ready for Testing
│   └── Filter by processor, species, date
│
├── Create Quality Test
│   ├── Select Batch
│   ├── Enter Test Results:
│   │   ├── Moisture Content (%) [Target: 8-12%]
│   │   ├── Pesticide Screen:
│   │   │   ├── Chlorpyrifos (ppm) [Max: 0.01]
│   │   │   ├── Malathion (ppm) [Max: 0.01]
│   │   │   └── DDT (ppm) [Max: 0.001]
│   │   ├── Heavy Metals:
│   │   │   ├── Lead (ppm) [Max: 5]
│   │   │   ├── Cadmium (ppm) [Max: 0.3]
│   │   │   └── Mercury (ppm) [Max: 0.1]
│   │   ├── DNA Barcode:
│   │   │   ├── Sequence Match (%)
│   │   │   └── Species Confirmation (Yes/No)
│   │   ├── Microbial Load (CFU/g) [Max: 10^5]
│   │   └── Aflatoxins (ppb) [Max: 20]
│   │
│   ├── Upload Certificate (PDF)
│   ├── Assign Grade: A / B / C / F
│   └── Submit to Blockchain
│
└── View Test History
    └── Pass/Fail statistics
```

#### 2. **Smart Contract Auto-Grading**
```go
func (t *HerbalTraceContract) CreateQualityTest(ctx, testJSON string) error {
  test := parseQualityTest(testJSON);
  
  // Auto-calculate overall result:
  failReasons := [];
  
  if test.MoistureContent > 12 || test.MoistureContent < 8 {
    failReasons.append("Moisture out of range");
  }
  
  if test.PesticideResults.Chlorpyrifos > 0.01 {
    failReasons.append("Pesticide: Chlorpyrifos exceeds limit");
  }
  
  if test.HeavyMetals.Lead > 5 {
    failReasons.append("Heavy metal: Lead exceeds limit");
  }
  
  if !test.DNABarcodeMatch {
    failReasons.append("DNA authentication failed");
    test.OverallResult = "fail"; // Critical failure
  }
  
  // Auto-assign grade:
  if len(failReasons) == 0 {
    test.OverallResult = "pass";
    test.Grade = "A";
  } else if isCriticalFailure(failReasons) {
    test.OverallResult = "fail";
    test.Grade = "F";
    
    // Trigger alerts:
    createAlert(ctx, "QUALITY_TEST_FAILED", test.BatchID);
    notifyProcessor(test.BatchID, failReasons);
    notifyAdmin(test.BatchID, failReasons);
  } else {
    test.OverallResult = "conditional";
    test.Grade = "B";
  }
  
  // Update batch status:
  updateBatchStatus(test.BatchID, "quality_tested");
  
  return ctx.GetStub().PutState(test.ID, testBytes);
}
```

#### 3. **Failed Test Workflow**
```
If QualityTest.Grade == "F":
├── Blockchain creates Alert
├── Processor Dashboard shows:
│   └── "Batch BATCH-456 FAILED quality test"
│   └── Reason: "DNA mismatch - wrong species"
│   └── Action Required: "Retest or Reject batch"
│
├── Admin Dashboard shows:
│   └── Critical Alert with batch details
│   └── Actions:
│       ├── Approve Retest
│       ├── Mark for Destruction
│       └── Investigate Farmer
│
└── Email/SMS sent to all stakeholders
```

**Output:**
```json
{
  "qualityTestId": "TEST-789",
  "batchId": "BATCH-456",
  "overallResult": "pass",
  "grade": "A",
  "certificateUrl": "https://ipfs.io/...",
  "transactionId": "0x4c5d...",
  "status": "approved_for_manufacturing"
}
```

---

## **PHASE 5: Manufacturing (Final Batch Creation)**

### Current Flow (Your Design):
```
Manufacturer selects herb lots
→ System merges provenance bundles
→ Creates BatchRecord with FBID
→ All inputs must be tested & approved
```

### ✅ **Enhanced Flow:**

#### 1. **Manufacturing Dashboard**
```
Manufacturer:
├── View Approved Batches (Grade A/B only)
│   └── Filter by species, processor, test date
│
├── Create Manufacturing Batch
│   ├── Step 1: Select Input Batches (multiple)
│   │   ├── Show: Species, Quantity, Grade, Test Date
│   │   ├── Validation:
│   │   │   → All same species? ✔
│   │   │   → All Grade A or B? ✔
│   │   │   → None expired (< 6 months old)? ✔
│   │   └── Total Input Quantity: 50 kg
│   │
│   ├── Step 2: Manufacturing Details
│   │   ├── Product Name: "Organic Ashwagandha Powder"
│   │   ├── Manufacturing Date
│   │   ├── Batch Size: 1000 units (50g each)
│   │   ├── Packaging Type: "Glass jar with seal"
│   │   ├── Expiry: 2 years from mfg date
│   │   └── Add product images
│   │
│   ├── Step 3: Review Provenance
│   │   └── System shows complete journey:
│   │       ├── 5 Collections (Farmers A, B, C)
│   │       ├── Processing by Facility X
│   │       ├── Lab Test by Lab Y (Grade A)
│   │       └── Total: 12 blockchain transactions
│   │
│   └── Step 4: Generate Product
│       └── Submit to blockchain
│           → Creates Product Record
│           → Links all provenance
│           → Status: "ready_for_qr"
```

#### 2. **Smart Contract - Product Creation**
```go
func (t *HerbalTraceContract) CreateProduct(ctx, productJSON string) error {
  product := parseProduct(productJSON);
  
  // Validate all input batches:
  for _, batchId := range product.InputBatchIds {
    batch := getBatch(ctx, batchId);
    
    if batch.Status != "quality_tested" {
      return errors.New("Batch not tested: " + batchId);
    }
    
    test := getLatestQualityTest(ctx, batchId);
    if test.Grade == "F" {
      return errors.New("Batch failed quality test: " + batchId);
    }
    
    if isExpired(batch.CreatedDate, 6 months) {
      return errors.New("Batch expired: " + batchId);
    }
  }
  
  // Create provenance bundle:
  product.ProvenanceBundle = generateProvenanceBundle(ctx, product.InputBatchIds);
  product.Status = "ready_for_qr";
  
  return ctx.GetStub().PutState(product.ID, productBytes);
}
```

**Output:**
```json
{
  "productId": "PROD-xyz789",
  "fbid": "FBID-2025-001",
  "status": "ready_for_qr",
  "provenanceSummary": {
    "totalFarmers": 3,
    "totalCollections": 5,
    "processingSteps": 3,
    "qualityTests": 2,
    "grades": ["A", "A"]
  },
  "transactionId": "0x8f2a..."
}
```

---

## **PHASE 6: QR Code Generation (Encrypted)**

### ✅ **Advanced QR System:**

#### 1. **QR Data Structure**
```javascript
// What goes into QR code:
const qrPayload = {
  productId: "PROD-xyz789",
  batchCode: "FBID-2025-001",
  mfgDate: "2025-12-01",
  expiry: "2027-12-01",
  verificationUrl: "https://herbaltrace.com/verify"
};

// Encrypt with AES-256-CBC:
const encryptedQR = encrypt(JSON.stringify(qrPayload), SECRET_KEY);

// Generate QR image:
const qrCodeImage = generateQRCode(encryptedQR);
```

#### 2. **Manufacturer Flow**
```
Manufacturer Dashboard:
├── View Products Ready for QR
│
├── Click "Generate QR Code"
│   ├── Backend calls: POST /api/v1/products/:id/generate-qr
│   ├── System:
│   │   ├── Encrypts product data (AES-256)
│   │   ├── Generates QR image (PNG, 300x300px)
│   │   ├── Stores encrypted QR in blockchain
│   │   ├── Returns QR image + download link
│   │   └── Updates product status to "qr_generated"
│   │
│   └── Manufacturer receives:
│       ├── QR Code image (for printing on label)
│       ├── Serial number (human-readable backup)
│       └── Verification URL
│
├── Download QR (bulk option for 1000 units)
│   └── Generates PDF with QR grid (print sheet)
│
└── Print Labels
    └── QR code applied to each product unit
```

#### 3. **QR Encryption Service**
```typescript
// backend/src/services/QREncryptionService.ts

import crypto from 'crypto';
import QRCode from 'qrcode';

class QREncryptionService {
  private algorithm = 'aes-256-cbc';
  private key = Buffer.from(process.env.QR_ENCRYPTION_KEY!, 'hex');
  private iv = crypto.randomBytes(16);
  
  async generateEncryptedQR(productData: any): Promise<{
    encryptedData: string;
    qrImage: Buffer;
    serialNumber: string;
  }> {
    // 1. Create payload
    const payload = {
      productId: productData.id,
      batchCode: productData.fbid,
      mfgDate: productData.manufacturingDate,
      expiry: productData.expiryDate,
      v: '1.0' // version
    };
    
    // 2. Encrypt
    const cipher = crypto.createCipheriv(this.algorithm, this.key, this.iv);
    let encrypted = cipher.update(JSON.stringify(payload), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const encryptedData = this.iv.toString('hex') + ':' + encrypted;
    
    // 3. Generate QR
    const qrImage = await QRCode.toBuffer(encryptedData, {
      width: 300,
      margin: 2,
      errorCorrectionLevel: 'H'
    });
    
    // 4. Generate human-readable serial
    const serialNumber = `HT-${productData.id.substring(0, 8)}-${Date.now()}`;
    
    return { encryptedData, qrImage, serialNumber };
  }
  
  async decryptQRCode(encryptedData: string): Promise<any> {
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];
    
    const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return JSON.parse(decrypted);
  }
}

export default new QREncryptionService();
```

**Smart Contract Function:**
```go
func (t *HerbalTraceContract) GenerateProductQR(ctx, productId string) error {
  product := getProduct(ctx, productId);
  
  if product.Status != "ready_for_qr" {
    return errors.New("Product not ready for QR generation");
  }
  
  // Generate unique QR ID
  qrId := "QR-" + generateUUID();
  
  // Create QR record
  qrRecord := QRCode{
    ID: qrId,
    ProductID: productId,
    GeneratedDate: time.Now(),
    Status: "active",
  };
  
  // Update product
  product.QRCodeID = qrId;
  product.Status = "qr_generated";
  
  ctx.GetStub().PutState(qrId, qrBytes);
  ctx.GetStub().PutState(productId, productBytes);
  
  return nil;
}
```

---

## **PHASE 7: Consumer Verification**

### ✅ **QR Scan Experience:**

#### 1. **Consumer Flow**
```
Consumer scans QR code (no login required):

Mobile/Web Scanner:
├── Scan QR → Extracts encrypted data
├── Send to backend: POST /api/v1/provenance/verify
│   └── Backend:
│       ├── Decrypt QR data
│       ├── Query blockchain: GetProvenanceByQRCode
│       ├── Fetch complete supply chain history
│       └── Return consumer-friendly response
│
└── Display:
    ├── Product Authentication (✓ Verified)
    ├── Manufacturing Details
    ├── Complete Journey:
    │   ├── 🌱 Harvested by: Farmer Ram Singh (Location: Uttarakhand)
    │   ├── 📅 Harvest Date: Jan 15, 2025
    │   ├── 🏭 Processed by: ABC Processors
    │   ├── 🧪 Lab Tested: Grade A (View Certificate)
    │   ├── 🏢 Manufactured by: XYZ Ayurveda
    │   └── 📦 Packaged: Dec 1, 2025
    │
    ├── Interactive Map (showing farm locations)
    ├── Quality Certificates (downloadable)
    ├── Sustainability Score: 95/100
    └── Report Fake button (if consumer suspects)
```

#### 2. **Backend API**
```typescript
// provenance.routes.ts

router.post('/verify', async (req, res) => {
  try {
    const { qrData } = req.body;
    
    // 1. Decrypt QR
    const decrypted = await QREncryptionService.decryptQRCode(qrData);
    
    // 2. Query blockchain
    const fabricClient = getFabricClient();
    await fabricClient.connect('consumer-viewer', 'PublicOrg'); // Read-only
    
    const provenance = await fabricClient.evaluateTransaction(
      'GetProvenanceByQRCode',
      decrypted.productId
    );
    
    await fabricClient.disconnect();
    
    // 3. Format for consumer
    const response = {
      verified: true,
      product: provenance.product,
      journey: {
        collections: provenance.collections.map(c => ({
          farmer: c.farmerName,
          location: `${c.latitude}, ${c.longitude}`,
          date: c.harvestDate,
          species: c.species
        })),
        processing: provenance.processingSteps,
        testing: provenance.qualityTests.map(t => ({
          lab: t.labName,
          grade: t.grade,
          certificate: t.certificateUrl
        })),
        manufacturing: provenance.product
      },
      sustainabilityScore: calculateScore(provenance),
      mapData: provenance.collections.map(c => ({
        lat: c.latitude,
        lng: c.longitude,
        label: c.farmerName
      }))
    };
    
    res.json({ success: true, data: response });
    
  } catch (error) {
    res.status(400).json({
      success: false,
      verified: false,
      message: 'Invalid or tampered QR code'
    });
  }
});
```

---

## **PHASE 8: Admin & Regulator Dashboard**

### ✅ **Real-time Monitoring:**

#### 1. **Dashboard Features**
```
Admin Dashboard:
├── Overview
│   ├── Total Collections Today: 45
│   ├── Pending Processor Assignment: 12
│   ├── Active Batches in Processing: 8
│   ├── Quality Tests Pending: 5
│   ├── Products Generated This Month: 234
│   └── Critical Alerts: 2 ⚠️
│
├── Real-time Harvest Map
│   ├── Interactive map showing all collection events
│   ├── Color-coded by status:
│   │   ├── Green: Approved & assigned
│   │   ├── Yellow: Pending assignment
│   │   └── Red: Alert (geo-fence violation, limit exceeded)
│   ├── Click marker → View collection details
│   └── Filter by: Date, Species, Farmer, Status
│
├── Batch Progress Timeline
│   ├── Visual timeline for each batch:
│   │   └── Collection → Assignment → Processing → Testing → Manufacturing → QR
│   ├── Shows current stage
│   ├── Time spent at each stage
│   └── Bottleneck detection (if stuck > 7 days)
│
├── Quality Test Alerts
│   ├── Failed Tests (Grade F) - Requires Action
│   ├── Conditional Tests (Grade B/C) - Review Required
│   ├── View fail reasons
│   └── Actions:
│       ├── Approve Retest
│       ├── Contact Processor
│       └── Mark for Investigation
│
├── Sustainability Compliance Dashboard
│   ├── Farmers Complying with Harvest Limits: 95%
│   ├── Collections within Season Window: 98%
│   ├── Geo-fence Compliance: 100%
│   ├── Average Quality Grade: A-
│   ├── Species Diversity Index
│   └── Export Compliance Score
│
├── Export Certification Generator
│   ├── Select batch/product
│   ├── Generate NMPB compliant certificate
│   ├── Include:
│   │   ├── Complete provenance
│   │   ├── Quality test results
│   │   ├── Processing details
│   │   └── Blockchain transaction IDs (proof)
│   └── Download PDF (digitally signed)
│
└── User Management
    ├── Pending Farmer Registrations → Approve/Reject
    ├── Active Users (Farmers, Processors, Labs, Manufacturers)
    ├── Assign Roles & Permissions
    └── Suspend/Deactivate accounts
```

#### 2. **Alerts System**
```sql
-- Alerts table:
CREATE TABLE alerts (
  id UUID PRIMARY KEY,
  alert_type VARCHAR(50), -- 'GEO_FENCE', 'HARVEST_LIMIT', 'QUALITY_FAIL', etc.
  severity VARCHAR(20), -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  entity_type VARCHAR(50), -- 'collection', 'batch', 'test'
  entity_id VARCHAR(50),
  message TEXT,
  details JSONB,
  status VARCHAR(20), -- 'active', 'acknowledged', 'resolved'
  created_at TIMESTAMP,
  acknowledged_by VARCHAR(100),
  acknowledged_at TIMESTAMP,
  resolved_by VARCHAR(100),
  resolved_at TIMESTAMP
);
```

**Alert Types:**
```
1. GEO_FENCE_VIOLATION
   → Farmer collected outside approved zone
   → Action: Contact farmer, educate on zones

2. HARVEST_LIMIT_EXCEEDED
   → Farmer exceeded monthly/seasonal limit
   → Action: Suspend further collections, investigate

3. SEASONAL_WINDOW_VIOLATION
   → Collection outside allowed season
   → Action: Reject collection, educate farmer

4. QUALITY_TEST_FAILED
   → Batch failed lab tests
   → Action: Contact processor, investigate source

5. PROCESSING_ALERT
   → Over-drying, high loss, etc.
   → Action: Review processor, provide training

6. EXPIRED_BATCH
   → Batch older than 6 months not used
   → Action: Mark for destruction, update inventory
```

---

## **PHASE 9: Automated Recall Management**

### ✅ **Critical Feature:**

#### 1. **Recall Trigger**
```
Scenario: Lab discovers contamination in Batch BATCH-456

Admin Dashboard:
├── Click "Initiate Recall"
│   ├── Select affected batch(s)
│   ├── Enter reason: "Pesticide contamination - Chlorpyrifos > 0.05 ppm"
│   ├── Severity: Critical
│   └── Submit
│
├── System automatically:
│   ├── Queries blockchain for ALL products using BATCH-456
│   ├── Finds: 15 products (PROD-1 to PROD-15)
│   ├── Updates status to: "recalled"
│   ├── Generates recall notices
│   └── Sends notifications:
│       ├── Manufacturer: "Recall initiated for 15 products"
│       ├── Distributors: "Stop sales immediately"
│       ├── Retailers: "Remove from shelves"
│       └── Consumers (if registered): "Do not consume, return for refund"
│
└── Recall Dashboard shows:
    ├── Total products affected: 15
    ├── Products located: 12
    ├── Products returned: 8
    ├── Products still in market: 4 (track & retrieve)
    └── Recall completion: 80%
```

#### 2. **Smart Contract - Recall Function**
```go
func (t *HerbalTraceContract) InitiateRecall(ctx, recallJSON string) error {
  recall := parseRecall(recallJSON);
  
  // Find all products linked to affected batches:
  affectedProducts := [];
  
  for _, batchId := range recall.AffectedBatchIds {
    products := queryProductsByBatch(ctx, batchId);
    affectedProducts = append(affectedProducts, products...);
  }
  
  // Update product status:
  for _, product := range affectedProducts {
    product.Status = "recalled";
    product.RecallReason = recall.Reason;
    product.RecallDate = time.Now();
    ctx.GetStub().PutState(product.ID, productBytes);
  }
  
  // Create recall record:
  recall.AffectedProductCount = len(affectedProducts);
  recall.Status = "active";
  ctx.GetStub().PutState(recall.ID, recallBytes);
  
  // Create alerts for all stakeholders:
  createRecallAlert(ctx, recall.ID, affectedProducts);
  
  return nil;
}
```

#### 3. **Consumer Notification**
```
If consumer scans QR of recalled product:

Display:
⚠️ PRODUCT RECALL NOTICE ⚠️

This product has been recalled.

Reason: Pesticide contamination detected
Recall Date: Dec 15, 2025
Batch: BATCH-456

DO NOT CONSUME

Return Instructions:
1. Visit nearest retailer for full refund
2. Call: 1800-XXX-XXXX
3. Email: recall@herbaltrace.com

Your safety is our priority.
```

---

## **FINAL WORKFLOW SUMMARY**

### Complete Journey (Step-by-Step):

```
1. REGISTRATION
   → Farmer applies via website
   → Admin approves → Farmer gets login

2. COLLECTION
   → Farmer opens mobile app (offline OK)
   → GPS + photos + data entry
   → Submit (queued if offline, synced later)
   → Blockchain validates (zone, season, limit)
   → Status: Pending assignment

3. ADMIN ASSIGNMENT
   → Admin views pending collections
   → Creates batch (groups collections)
   → Assigns to processor
   → Processor notified

4. PROCESSING
   → Processor receives batch
   → Performs: Drying → Grinding → Storage
   → Each step recorded to blockchain
   → Smart contract validates quality rules
   → Status: Ready for testing

5. LAB TESTING
   → Lab performs comprehensive tests
   → Uploads results + certificate
   → Smart contract auto-grades (A/B/C/F)
   → If fail: Alerts sent, retest required
   → If pass: Status: Approved for manufacturing

6. MANUFACTURING
   → Manufacturer selects approved batches
   → Creates final product
   → System generates provenance bundle
   → Status: Ready for QR

7. QR GENERATION
   → Manufacturer clicks "Generate QR"
   → System encrypts product data (AES-256)
   → Generates QR image
   → Manufacturer downloads & prints on label
   → Status: QR generated, ready for sale

8. CONSUMER VERIFICATION
   → Consumer scans QR (mobile/web)
   → System decrypts & queries blockchain
   → Displays complete journey with map
   → Shows quality certificates
   → Consumer trusts product authenticity

9. ADMIN MONITORING
   → Real-time dashboard
   → Map view of all activities
   → Alert management
   → Export certification
   → Recall management (if needed)

10. RECALL (if needed)
    → Admin initiates recall
    → System finds all affected products
    → Updates status to "recalled"
    → Notifies all stakeholders
    → Tracks recall progress
```

---

## 🎯 **Implementation Priority for 36 Hours**

### MVP Features (Must Have):
1. ✅ Farmer registration approval flow
2. ✅ Collection event creation (with GPS)
3. ✅ Admin batch creation & processor assignment
4. ✅ Processing steps (at least drying)
5. ✅ Lab testing (basic: moisture, grade)
6. ✅ Product creation
7. ✅ QR generation (encrypted)
8. ✅ Consumer QR scan → Provenance display
9. ✅ Admin dashboard (basic)

### Post-MVP (Nice to Have):
- Advanced lab tests (pesticide, DNA)
- Offline SMS sync
- Interactive map
- Recall management
- Export certification

---

**Your workflow is EXCELLENT! This optimized version is ready for implementation. Shall we start coding?**
