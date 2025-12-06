# HerbalTrace Blockchain API Documentation

## Overview
This document provides the complete API contract for the HerbalTrace blockchain. All 38 chaincode functions are documented with input/output schemas, validation rules, and example usage for backend and frontend integration teams.

**Chaincode Version:** 2.1  
**Sequence:** 3  
**Channel:** herbaltrace-channel  
**State Database:** CouchDB 3.3.2 with 7 indexes  

---

## Quick Reference

### Function Categories
1. **Collection Events** (5 functions) - Farmer harvest recording
2. **Batch Management** (8 functions) - Batch lifecycle
3. **Quality Testing** (3 functions) - Lab testing
4. **Processing Steps** (2 functions) - Processing workflow
5. **Product Management** (3 functions) - Final product creation
6. **Provenance** (2 functions) - Full traceability
7. **Season Windows** (4 functions) - Harvest season management
8. **Harvest Limits** (6 functions) - Sustainable harvest tracking
9. **Alerts** (10 functions) - Alert system
10. **Ledger Utility** (1 function) - Initialization

---

## 1. Collection Events (Farmer App)

### 1.1 CreateCollectionEvent
**Description:** Records a new harvest/collection event with comprehensive validation including season window, geo-fencing, and harvest limits.

**Function Name:** `CreateCollectionEvent`

**Input Schema:**
```json
{
  "farmerId": "string (required)",
  "farmerName": "string (required)",
  "species": "string (required)",
  "commonName": "string",
  "scientificName": "string",
  "quantity": "float64 (required, > 0)",
  "unit": "string (required)",
  "harvestDate": "string (required, ISO8601: YYYY-MM-DDTHH:MM:SSZ)",
  "timestamp": "string (auto-generated if not provided)",
  "latitude": "float64 (required)",
  "longitude": "float64 (required)",
  "altitude": "float64",
  "accuracy": "float64",
  "harvestMethod": "string (manual/mechanical)",
  "partCollected": "string (roots/leaves/flowers/seeds/bark)",
  "weatherConditions": "string",
  "images": ["string (IPFS hashes)"],
  "approvedZone": "boolean",
  "zoneName": "string",
  "conservationStatus": "string (LC/NT/VU/EN/CR)",
  "status": "string (pending/approved/rejected)"
}
```

**Output:**
```json
{
  "message": "Collection event created successfully",
  "collectionEventId": "CE-XXXXXXXX",
  "batchEligible": true/false,
  "validationWarnings": ["list of warnings"],
  "status": 200
}
```

**Validation Rules:**
1. `harvestDate` must be in valid ISO8601 format with timezone
2. Season window validation (if configured for species)
3. Geo-fencing validation (if enabled)
4. Harvest limit checking (alerts if approaching limit)
5. `quantity` must be positive
6. GPS coordinates required (`latitude`, `longitude`)

**Example Invocation:**
```bash
peer chaincode invoke \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"CreateCollectionEvent","Args":["{\"farmerId\":\"FARM001\",\"farmerName\":\"Rajesh Kumar\",\"species\":\"Ashwagandha\",\"quantity\":50,\"unit\":\"kg\",\"harvestDate\":\"2025-11-30T10:00:00Z\",\"latitude\":23.2599,\"longitude\":77.4126,\"harvestMethod\":\"manual\",\"partCollected\":\"roots\",\"approvedZone\":true,\"zoneName\":\"Madhya Pradesh\",\"status\":\"pending\"}"]}'
```

---

### 1.2 GetCollectionEvent
**Description:** Retrieves a collection event by ID.

**Function Name:** `GetCollectionEvent`

**Input:**
```json
{
  "collectionEventId": "string (CE-XXXXXXXX)"
}
```

**Output:** Full CollectionEvent object

**Example:**
```bash
peer chaincode query \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"GetCollectionEvent","Args":["CE-12345678"]}'
```

---

## 2. Batch Management

### 2.1 CreateBatch
**Description:** Creates a batch from one or more collection events.

**Function Name:** `CreateBatch`

**Input Schema:**
```json
{
  "farmerId": "string (required)",
  "farmerName": "string (required)",
  "species": "string (required)",
  "totalQuantity": "float64 (required)",
  "unit": "string (required)",
  "collectionEventIds": ["string (required, array of CE-XXX)"],
  "harvestStartDate": "string (required, YYYY-MM-DD)",
  "harvestEndDate": "string (required, YYYY-MM-DD)",
  "createdDate": "string (auto-generated)",
  "status": "string (collected/assigned/testing/processing/manufactured)"
}
```

**Output:**
```json
{
  "message": "Batch created successfully",
  "batchId": "BATCH-XXXXXXXX",
  "status": 200
}
```

**Validation Rules:**
1. All `collectionEventIds` must exist and be approved
2. `harvestEndDate` >= `harvestStartDate`
3. `totalQuantity` must be positive

**Example:**
```bash
peer chaincode invoke \
  -C herbaltrace-channel \
  -n herbaltrace \
  -c '{"function":"CreateBatch","Args":["{\"farmerId\":\"FARM001\",\"farmerName\":\"Rajesh Kumar\",\"species\":\"Ashwagandha\",\"totalQuantity\":50,\"unit\":\"kg\",\"collectionEventIds\":[\"CE-12345678\"],\"harvestStartDate\":\"2025-11-30\",\"harvestEndDate\":\"2025-11-30\",\"status\":\"collected\"}"]}'
```

---

### 2.2 GetBatch
**Function Name:** `GetBatch`

**Input:** `{"batchId": "BATCH-XXXXXXXX"}`

**Output:** Full Batch object

---

### 2.3 AssignBatchToProcessor
**Function Name:** `AssignBatchToProcessor`

**Input:**
```json
{
  "batchId": "string (required)",
  "processorId": "string (required)",
  "processorName": "string (required)",
  "assignedBy": "string (required)"
}
```

**Effect:** Updates batch status to "assigned", sets processor details, records assignment timestamp.

---

### 2.4 UpdateBatchStatus
**Function Name:** `UpdateBatchStatus`

**Input:**
```json
{
  "batchId": "string (required)",
  "newStatus": "string (collected/assigned/testing/processing/manufactured)"
}
```

---

### 2.5 GetBatchHistory
**Function Name:** `GetBatchHistory`

**Input:** `{"batchId": "BATCH-XXXXXXXX"}`

**Output:** Array of all historical versions of the batch (full audit trail)

---

### 2.6 QueryBatchesByStatus (Rich Query - Requires CouchDB Index)
**Function Name:** `QueryBatchesByStatus`

**Input:** `{"status": "collected"}`

**Output:** Array of batches matching status

**Index Required:** `indexBatchStatus` on fields `[status, farmerId, createdDate]`

---

### 2.7 QueryBatchesByProcessor (Rich Query)
**Function Name:** `QueryBatchesByProcessor`

**Input:** `{"processorId": "PROC001"}`

**Output:** Array of batches assigned to processor

**Index Required:** `indexBatchProcessor` on fields `[processorId, status, assignedDate]`

---

### 2.8 GetPendingBatches (Rich Query)
**Function Name:** `GetPendingBatches`

**Output:** Array of batches with status "collected" (not yet assigned)

**Index Required:** `indexBatchStatus`

---

## 3. Quality Testing (Lab Portal)

### 3.1 CreateQualityTest
**Description:** Records quality test results from lab.

**Function Name:** `CreateQualityTest`

**Input Schema:**
```json
{
  "collectionEventId": "string",
  "batchId": "string (required)",
  "labId": "string (required)",
  "labName": "string (required)",
  "testDate": "string (YYYY-MM-DD)",
  "timestamp": "string (auto-generated)",
  "testTypes": ["string (moisture/pesticide/dna_barcode/heavy_metals/microbial/aflatoxins)"],
  "moistureContent": "float64 (percentage)",
  "pesticideResults": {"pesticideName": "pass/fail"},
  "heavyMetals": {"metalName": "float64 (ppm)"},
  "dnaBarcodeMatch": "boolean",
  "dnaSequence": "string",
  "microbialLoad": "float64 (CFU/g)",
  "aflatoxins": "float64 (ppb)",
  "overallResult": "string (pass/fail/conditional)",
  "certificateId": "string",
  "certificateUrl": "string (IPFS URL)",
  "testerName": "string (required)",
  "testerSignature": "string",
  "status": "string (pending/approved/rejected)"
}
```

**Output:**
```json
{
  "message": "Quality test created successfully",
  "testId": "TEST-XXXXXXXX",
  "status": 200
}
```

**Side Effect:** Automatically updates batch status to "testing"

---

### 3.2 GetQualityTest
**Function Name:** `GetQualityTest`

**Input:** `{"testId": "TEST-XXXXXXXX"}`

---

### 3.3 QueryQualityTestsByBatch (Rich Query)
**Function Name:** `QueryQualityTestsByBatch`

**Input:** `{"batchId": "BATCH-XXXXXXXX"}`

**Index Required:** `indexQualityTestBatch` on fields `[batchId, labId, testDate, overallResult]`

---

## 4. Processing Steps (Processor Portal)

### 4.1 CreateProcessingStep
**Description:** Records a processing event (drying, grinding, extraction, formulation).

**Function Name:** `CreateProcessingStep`

**Input Schema:**
```json
{
  "previousStepId": "string (required, TEST-XXX or PROC-XXX)",
  "batchId": "string (required)",
  "processorId": "string (required)",
  "processorName": "string (required)",
  "processType": "string (drying/grinding/extraction/formulation)",
  "processDate": "string (YYYY-MM-DD)",
  "timestamp": "string (auto-generated)",
  "inputQuantity": "float64 (required)",
  "outputQuantity": "float64 (required)",
  "unit": "string (required)",
  "temperature": "float64 (Celsius)",
  "duration": "float64 (hours)",
  "equipment": "string",
  "parameters": {"key": "value"},
  "qualityChecks": ["string"],
  "operatorId": "string (required)",
  "operatorName": "string (required)",
  "location": "string",
  "latitude": "float64",
  "longitude": "float64",
  "status": "string (in_progress/completed/failed)"
}
```

**Output:**
```json
{
  "message": "Processing step created successfully",
  "processingStepId": "PROC-XXXXXXXX",
  "status": 200
}
```

**Side Effect:** Updates batch status to "processing"

---

### 4.2 GetProcessingStep
**Function Name:** `GetProcessingStep`

**Input:** `{"processingStepId": "PROC-XXXXXXXX"}`

---

## 5. Product Management (Manufacturer Portal)

### 5.1 CreateProduct
**Description:** Creates final product with QR code for consumer scanning.

**Function Name:** `CreateProduct`

**Input Schema:**
```json
{
  "productName": "string (required)",
  "productType": "string (powder/extract/capsule/oil)",
  "manufacturerId": "string (required)",
  "manufacturerName": "string (required)",
  "batchId": "string (required)",
  "manufactureDate": "string (YYYY-MM-DD)",
  "expiryDate": "string (YYYY-MM-DD)",
  "quantity": "float64 (required)",
  "unit": "string (required)",
  "qrCode": "string (required, unique)",
  "ingredients": ["string"],
  "collectionEventIds": ["string"],
  "qualityTestIds": ["string"],
  "processingStepIds": ["string"],
  "certifications": ["string (Organic/Fair Trade/AYUSH Certified)"],
  "packagingDate": "string (YYYY-MM-DD)",
  "status": "string (manufactured/distributed/sold)",
  "timestamp": "string (auto-generated)"
}
```

**Output:**
```json
{
  "message": "Product created successfully",
  "productId": "PROD-XXXXXXXX",
  "qrCode": "QR-XXXXXXXX",
  "status": 200
}
```

**Side Effect:** Updates batch status to "manufactured"

---

### 5.2 GetProduct
**Function Name:** `GetProduct`

**Input:** `{"productId": "PROD-XXXXXXXX"}`

---

### 5.3 GetProductByQRCode
**Function Name:** `GetProductByQRCode`

**Input:** `{"qrCode": "QR-XXXXXXXX"}`

**Use Case:** Consumer scans QR code → retrieves product details

---

## 6. Provenance (Consumer Portal)

### 6.1 GetProvenance
**Description:** Retrieves complete supply chain history for a product (FHIR-style bundle).

**Function Name:** `GetProvenance`

**Input:** `{"productId": "PROD-XXXXXXXX"}`

**Output Schema:**
```json
{
  "id": "PROV-XXXXXXXX",
  "productId": "PROD-XXXXXXXX",
  "qrCode": "QR-XXXXXXXX",
  "generatedDate": "ISO8601 timestamp",
  "collectionEvents": [CollectionEvent],
  "qualityTests": [QualityTest],
  "processingSteps": [ProcessingStep],
  "product": Product,
  "sustainabilityScore": "float64 (0-100)",
  "totalDistance": "float64 (km traveled)"
}
```

**Use Case:** Consumer scans QR → displays full farm-to-shelf journey

---

### 6.2 GetProvenanceByQRCode
**Function Name:** `GetProvenanceByQRCode`

**Input:** `{"qrCode": "QR-XXXXXXXX"}`

---

## 7. Season Windows (Admin/Regulator)

### 7.1 CreateSeasonWindow
**Function Name:** `CreateSeasonWindow`

**Input Schema:**
```json
{
  "id": "string (required, SW-XXXXXXXX)",
  "species": "string (required)",
  "commonName": "string",
  "scientificName": "string",
  "startMonth": "int (1-12, required)",
  "endMonth": "int (1-12, required)",
  "region": "string (required)",
  "zoneName": "string",
  "optimalConditions": "string",
  "active": "boolean"
}
```

---

### 7.2 ValidateSeasonWindow
**Function Name:** `ValidateSeasonWindow`

**Input:** `{"species": "string", "harvestDate": "ISO8601"}`

**Output:** `{"valid": true/false, "message": "string"}`

---

### 7.3 GetSeasonWindows
**Function Name:** `GetSeasonWindows`

**Input:** `{"species": "string"}`

**Index Required:** `indexSeasonWindow` on fields `[species, startMonth, endMonth, active]`

---

### 7.4 UpdateSeasonWindow
**Function Name:** `UpdateSeasonWindow`

**Input:** `{"id": "SW-XXXXXXXX", ...updated fields}`

---

## 8. Harvest Limits (Sustainability Tracking)

### 8.1 CreateHarvestLimit
**Function Name:** `CreateHarvestLimit`

**Input Schema:**
```json
{
  "id": "string (required, HL-XXXXXXXX)",
  "farmerId": "string (required)",
  "farmerName": "string",
  "species": "string (required)",
  "maxQuantity": "float64 (required)",
  "unit": "string (required)",
  "season": "string (required, e.g., Winter-2025)",
  "region": "string",
  "zoneName": "string",
  "active": "boolean"
}
```

---

### 8.2 TrackHarvestQuantity
**Function Name:** `TrackHarvestQuantity`

**Input:** `{"farmerId": "string", "species": "string", "quantity": "float64", "season": "string"}`

**Side Effect:** Creates alert if approaching or exceeding limit

---

### 8.3 ValidateHarvestLimit
**Function Name:** `ValidateHarvestLimit`

**Input:** `{"farmerId": "string", "species": "string", "quantity": "float64", "season": "string"}`

**Output:** `{"valid": true/false, "remainingQuota": "float64"}`

---

### 8.4 GetHarvestStatistics
**Function Name:** `GetHarvestStatistics`

**Input:** `{"farmerId": "string", "species": "string", "season": "string"}`

**Output:**
```json
{
  "totalHarvested": "float64",
  "maxAllowed": "float64",
  "percentageUsed": "float64",
  "remainingQuota": "float64"
}
```

---

### 8.5 ResetSeasonalLimits
**Function Name:** `ResetSeasonalLimits`

**Input:** `{"season": "string"}`

---

### 8.6 GetHarvestLimitAlerts
**Function Name:** `GetHarvestLimitAlerts`

**Output:** Array of alerts for farmers approaching/exceeding limits

**Index Required:** `indexHarvestLimit` on fields `[farmerId, species, season, active]`

---

## 9. Alerts (Admin Dashboard)

### 9.1 CreateAlert
**Function Name:** `CreateAlert`

**Input Schema:**
```json
{
  "alertType": "string (season_violation/harvest_limit/quality_failure/geo_fence_breach)",
  "severity": "string (info/warning/critical)",
  "entityType": "string (farmer/lab/processor/manufacturer)",
  "entityId": "string",
  "entityName": "string",
  "message": "string (required)",
  "details": "string",
  "status": "string (active/acknowledged/resolved)"
}
```

---

### 9.2 GetActiveAlerts (Rich Query)
**Function Name:** `GetActiveAlerts`

**Output:** Array of alerts with status="active"

**Index Required:** `indexAlertStatus` on fields `[status, severity, alertType, createdDate]`

---

### 9.3 GetCriticalAlerts (Rich Query)
**Function Name:** `GetCriticalAlerts`

**Output:** Array of alerts with severity="critical" and status="active"

---

### 9.4 GetAlertsByType (Rich Query)
**Function Name:** `GetAlertsByType`

**Input:** `{"alertType": "season_violation"}`

---

### 9.5 GetAlertsBySeverity (Rich Query)
**Function Name:** `GetAlertsBySeverity`

**Input:** `{"severity": "critical"}`

---

### 9.6 GetAlertsByEntity (Rich Query)
**Function Name:** `GetAlertsByEntity`

**Input:** `{"entityId": "FARM001"}`

---

### 9.7 GetAlertStatistics
**Function Name:** `GetAlertStatistics`

**Output:**
```json
{
  "totalActive": int,
  "critical": int,
  "warning": int,
  "info": int,
  "byType": {"season_violation": int, ...}
}
```

---

### 9.8 AcknowledgeAlert
**Function Name:** `AcknowledgeAlert`

**Input:** `{"alertId": "ALERT-XXXXXXXX", "acknowledgedBy": "string"}`

---

### 9.9 ResolveAlert
**Function Name:** `ResolveAlert`

**Input:** `{"alertId": "ALERT-XXXXXXXX", "resolvedBy": "string", "resolution": "string"}`

---

### 9.10 GetAlert
**Function Name:** `GetAlert`

**Input:** `{"alertId": "ALERT-XXXXXXXX"}`

---

## 10. Utility

### 10.1 InitLedger
**Function Name:** `InitLedger`

**Description:** Initializes ledger (no-op in current version)

---

## CouchDB Indexes

The following indexes are required for rich queries to work efficiently:

1. **indexBatchStatus** - `[status, farmerId, createdDate]`
2. **indexBatchProcessor** - `[processorId, status, assignedDate]`
3. **indexAlertStatus** - `[status, severity, alertType, createdDate]`
4. **indexCollectionFarmer** - `[farmerId, harvestDate, status, species]`
5. **indexQualityTestBatch** - `[batchId, labId, testDate, overallResult]`
6. **indexSeasonWindow** - `[species, startMonth, endMonth, active]`
7. **indexHarvestLimit** - `[farmerId, species, season, active]`

---

## Integration Guidelines

### Backend Team
- Use `fabric-network` SDK to connect to Fabric gateway
- Wallet setup: `backend/network/wallet/` contains user identities
- Connection profile: `backend/connection-farmers.json` (or labs/processors/manufacturers)
- Initialize services with organization context (FarmersCoopMSP, TestingLabsMSP, ProcessorsMSP, ManufacturersMSP)

### Frontend Team
- All dates must be ISO8601 format: `YYYY-MM-DDTHH:MM:SSZ`
- QR code scanning: Call `GetProvenanceByQRCode` endpoint
- File uploads (images, certificates): Upload to IPFS first, store hash in blockchain
- Real-time monitoring: Poll `GetActiveAlerts` every 30 seconds
- Batch status tracking: Use `QueryBatchesByStatus` for dashboard

---

## Testing Status

✅ **Chaincode v2.1 deployed** (Sequence 3)  
✅ **All 4 organizations approved**  
✅ **CouchDB indexes created**  
⏳ **End-to-end workflow testing in progress**  

---

## Contact

For backend/blockchain support: [Backend Dev Team]  
For integration questions: [DevOps Team]
