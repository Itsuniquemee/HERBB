# Backend API Endpoints Required for New Chaincode Functions

## 🎯 Critical 3 Features - Backend Integration Guide

### 1. Batch Management APIs

#### POST /api/batches
**Create New Batch**
```json
{
  "species": "Ashwagandha",
  "totalQuantity": 150.5,
  "unit": "kg",
  "collectionEventIds": ["event_001", "event_002"],
  "createdBy": "farmer1"
}
```
**Chaincode:** `CreateBatch(batchJSON)`

---

#### GET /api/batches/:batchId
**Get Batch Details**
**Chaincode:** `GetBatch(batchID)`

---

#### GET /api/batches/:batchId/history
**Get Batch History**
**Chaincode:** `GetBatchHistory(batchID)`

---

#### POST /api/batches/:batchId/assign
**Admin Assigns Batch to Processor**
```json
{
  "processorId": "processor1",
  "processorName": "Ayurvedic Processors Ltd",
  "adminId": "admin1"
}
```
**Chaincode:** `AssignBatchToProcessor(batchID, processorID, processorName, adminID)`

---

#### PATCH /api/batches/:batchId/status
**Update Batch Status**
```json
{
  "status": "testing" // collected, assigned, testing, processing, manufactured
}
```
**Chaincode:** `UpdateBatchStatus(batchID, newStatus)`

---

#### GET /api/batches/status/:status
**Query Batches by Status**
**Chaincode:** `QueryBatchesByStatus(status)`

---

#### GET /api/batches/processor/:processorId
**Get Processor's Batches**
**Chaincode:** `QueryBatchesByProcessor(processorID)`

---

#### GET /api/batches/pending
**Get Pending Batches (for admin dashboard)**
**Chaincode:** `GetPendingBatches()`

---

### 2. Season Window & Harvest Limit APIs

#### POST /api/admin/season-windows
**Create Season Window (Admin Only)**
```json
{
  "id": "season_ashwagandha_north",
  "species": "Ashwagandha",
  "startMonth": 10,
  "endMonth": 3,
  "region": "North India",
  "createdBy": "admin1"
}
```
**Chaincode:** `CreateSeasonWindow(windowJSON)`

---

#### GET /api/season-windows/:species
**Get Season Windows for Species**
**Chaincode:** `GetSeasonWindows(species)`

---

#### PUT /api/admin/season-windows/:windowId
**Update Season Window (Admin Only)**
**Chaincode:** `UpdateSeasonWindow(windowID, windowJSON)`

---

#### POST /api/season-windows/validate
**Validate Harvest Date (called before creating collection)**
```json
{
  "species": "Ashwagandha",
  "harvestDate": "2025-12-01T10:00:00Z",
  "region": "North India"
}
```
**Chaincode:** `ValidateSeasonWindow(species, harvestDate, region)`

---

#### POST /api/admin/harvest-limits
**Create Harvest Limit (Admin Only)**
```json
{
  "id": "limit_Ashwagandha_Zone_A_2025-Winter",
  "species": "Ashwagandha",
  "season": "2025-Winter",
  "zone": "Zone A",
  "maxQuantity": 1000,
  "unit": "kg",
  "alertThreshold": 80,
  "createdBy": "admin1"
}
```
**Chaincode:** `CreateHarvestLimit(limitJSON)`

---

#### GET /api/harvest-limits/statistics
**Get Harvest Statistics**
```json
{
  "species": "Ashwagandha",
  "zone": "Zone A",
  "season": "2025-Winter"
}
```
**Chaincode:** `GetHarvestStatistics(species, zone, season)`

---

#### GET /api/harvest-limits/alerts
**Get Harvest Limit Alerts (warning/exceeded)**
**Chaincode:** `GetHarvestLimitAlerts()`

---

#### POST /api/admin/harvest-limits/reset
**Reset Seasonal Limits (Admin Only)**
```json
{
  "season": "2025-Winter"
}
```
**Chaincode:** `ResetSeasonalLimits(season)`

---

### 3. Alert Management APIs

#### POST /api/alerts
**Create Alert (System or Manual)**
```json
{
  "id": "alert_custom_001",
  "alertType": "compliance",
  "severity": "medium",
  "entityId": "batch_001",
  "entityType": "Batch",
  "species": "Ashwagandha",
  "zone": "Zone A",
  "message": "Compliance check required",
  "details": "Batch requires additional documentation",
  "createdBy": "admin1"
}
```
**Chaincode:** `CreateAlert(alertJSON)`

**Alert Types:** `over_harvest`, `quality_failure`, `zone_violation`, `season_violation`, `compliance`, `system`  
**Severity Levels:** `low`, `medium`, `high`, `critical`

---

#### GET /api/alerts
**Get All Alerts**
**Chaincode:** `GetAlerts()`

---

#### GET /api/alerts/active
**Get Active Alerts**
**Chaincode:** `GetActiveAlerts()`

---

#### GET /api/alerts/critical
**Get Critical Alerts**
**Chaincode:** `GetCriticalAlerts()`

---

#### GET /api/alerts/type/:alertType
**Get Alerts by Type**
**Chaincode:** `GetAlertsByType(alertType)`

---

#### GET /api/alerts/severity/:severity
**Get Alerts by Severity**
**Chaincode:** `GetAlertsBySeverity(severity)`

---

#### GET /api/alerts/entity/:entityId
**Get Alerts for Entity**
**Query Params:** `entityType` (optional)
**Chaincode:** `GetAlertsByEntity(entityID, entityType)`

---

#### PATCH /api/alerts/:alertId/acknowledge
**Acknowledge Alert**
```json
{
  "userId": "admin1"
}
```
**Chaincode:** `AcknowledgeAlert(alertID, userID)`

---

#### PATCH /api/alerts/:alertId/resolve
**Resolve Alert**
```json
{
  "userId": "admin1",
  "resolution": "Issue resolved. Farmer educated on season windows."
}
```
**Chaincode:** `ResolveAlert(alertID, userID, resolution)`

---

#### GET /api/alerts/statistics
**Get Alert Statistics**
**Chaincode:** `GetAlertStatistics()`

**Returns:**
```json
{
  "total": 25,
  "byStatus": {
    "active": 10,
    "acknowledged": 8,
    "resolved": 7
  },
  "bySeverity": {
    "low": 5,
    "medium": 8,
    "high": 10,
    "critical": 2
  },
  "byType": {
    "over_harvest": 5,
    "quality_failure": 3,
    "zone_violation": 8,
    "season_violation": 6,
    "compliance": 2,
    "system": 1
  }
}
```

---

## 🔄 Enhanced Existing APIs

### POST /api/collections
**Create Collection Event (Now with 8-step validation)**

**New Automatic Behaviors:**
1. ✅ Validates season window
2. ✅ Validates geo-fencing
3. ✅ Validates harvest limit
4. ✅ Tracks harvest quantity
5. ✅ Creates warning alerts (80% threshold)
6. ✅ Creates violation alerts (exceeded, out of season, wrong zone)
7. ✅ Validates conservation limits
8. ✅ Emits blockchain event

**Chaincode:** `CreateCollectionEvent(eventJSON)`

---

### POST /api/quality-tests
**Create Quality Test (Now with auto batch update)**

**New Automatic Behaviors:**
1. ✅ Updates batch status to "testing"
2. ✅ Creates quality failure alert (if test fails)
3. ✅ Emits blockchain event

**Chaincode:** `CreateQualityTest(testJSON)`

---

### POST /api/processing-steps
**Create Processing Step (Now with auto batch update)**

**New Automatic Behaviors:**
1. ✅ Updates batch status to "processing"
2. ✅ Emits blockchain event

**Chaincode:** `CreateProcessingStep(stepJSON)`

---

### POST /api/products
**Create Product (Now with auto batch update)**

**New Automatic Behaviors:**
1. ✅ Updates batch status to "manufactured"
2. ✅ Emits blockchain event

**Chaincode:** `CreateProduct(productJSON)`

---

## 📊 Dashboard-Specific Endpoints

### Admin Dashboard
```
GET /api/batches/pending
GET /api/alerts/active
GET /api/alerts/critical
GET /api/harvest-limits/alerts
GET /api/alerts/statistics
```

### Farmer Dashboard
```
GET /api/batches/status/collected (their batches)
GET /api/harvest-limits/statistics?species=X&zone=Y
GET /api/season-windows/:species
```

### Processor Dashboard
```
GET /api/batches/processor/:processorId
GET /api/batches/:batchId/history
```

### Regulator Dashboard
```
GET /api/alerts/active
GET /api/alerts/type/over_harvest
GET /api/alerts/type/season_violation
GET /api/alerts/type/zone_violation
GET /api/harvest-limits/alerts
GET /api/alerts/statistics
```

---

## 🔐 Authentication & Authorization

### Role-Based Access:
- **Admin:** All endpoints
- **Farmer:** Create collections, view their batches, check limits
- **Processor:** View assigned batches, create processing steps
- **Lab:** Create quality tests
- **Manufacturer:** Create products
- **Regulator:** View all data, acknowledge/resolve alerts

---

## 📝 Implementation Notes

### Error Handling:
All chaincode functions return descriptive errors:
```javascript
try {
  await contract.submitTransaction('CreateCollectionEvent', eventJSON);
} catch (error) {
  if (error.message.includes('harvest outside allowed season')) {
    return res.status(400).json({ 
      error: 'Season violation',
      message: error.message,
      alertCreated: true
    });
  }
  // ... other error cases
}
```

### Event Listening:
Backend should listen to blockchain events:
- `BatchCreated`
- `BatchAssigned`
- `BatchStatusUpdated`
- `SeasonWindowCreated`
- `SeasonalLimitsReset`
- `AlertCreated`
- `AlertAcknowledged`
- `AlertResolved`
- `CollectionEventCreated`
- `QualityTestCreated`
- `ProcessingStepCreated`
- `ProductCreated`

### Caching Strategy:
Cache frequently accessed data:
- Season windows (cache for 24 hours)
- Harvest limits (cache for 1 hour)
- Active alerts (cache for 5 minutes)

---

## 🚀 Quick Start Integration

### 1. Update Fabric Connection
```javascript
// backend/src/fabric/connection.js
const contract = await gateway.getContract('herbaltrace');

// New functions available:
await contract.submitTransaction('CreateBatch', batchJSON);
await contract.evaluateTransaction('GetPendingBatches');
// ... etc
```

### 2. Create Route Files
```
backend/src/routes/
  ├── batches.ts         (NEW)
  ├── seasonWindows.ts   (NEW)
  ├── harvestLimits.ts   (NEW)
  ├── alerts.ts          (NEW)
  ├── collections.ts     (UPDATE)
  ├── qualityTests.ts    (UPDATE)
  ├── processingSteps.ts (UPDATE)
  └── products.ts        (UPDATE)
```

### 3. Test Integration
```bash
# Test batch creation
curl -X POST http://localhost:3000/api/batches \
  -H "Content-Type: application/json" \
  -d '{"species":"Ashwagandha","totalQuantity":100,"unit":"kg","createdBy":"farmer1"}'

# Test alerts
curl http://localhost:3000/api/alerts/active
```

---

**All 24 new chaincode functions are ready for backend integration!** 🎉
