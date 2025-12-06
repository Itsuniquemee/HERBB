# HerbalTrace - Complete Flow vs Current Implementation: Gap Analysis

## 📋 Your Complete Flow Summary

### 1. **Farmer Mobile App Flow**
```
Login (Blockchain CA-issued certificates)
  ↓
Add Collection Event:
  • Estimated Weight
  • Harvest Method (dropdown)
  • Species → Auto-fills Common & Scientific Name
  • Add Images (for batch)
  • GPS Auto-capture (Lat, Lon, Altitude)
  • Timestamp Auto-capture
  • Collector ID Auto-capture
  • Weather Data Auto-fetch
  ↓
Smart Contract Validation:
  • Season window check
  • Over-harvesting limit check
  • Geo-fencing (allowed zones)
  ↓
If Valid → Batch ID Generated on Blockchain
  ↓
Batch ID shown to Admin/Regulator
  ↓
Admin assigns to Processing Department
```

**Offline Mode:** Local storage → Sync later  
**SMS Mode:** Formatted SMS → Gateway → API → Blockchain

---

### 2. **Processor Website Flow**
```
Regulator/Admin assigns batch to processor
  ↓
Processor logs events:
  • Arrival batch check
  • Drying (temperature, duration)
  • Grinding
  • Cutting
  • Storage conditions
  • Packaging
  ↓
Each event triggers:
  • Smart contract validation
  • Automatic batch status change
```

---

### 3. **Testing Laboratory Portal Flow**
```
Lab opens Batch ID
  ↓
Enter test details:
  • Moisture %
  • Pesticide residue
  • Heavy metal report
  • DNA Barcode (authenticity)
  • Microbial limits
  • Upload certificate
  ↓
Creates QualityTest Event:
  • Test files → Hash stored on blockchain
  • Tester ID + Timestamp
  ↓
Smart Contract ensures:
  • Values within legal limits
  • Valid lab identity
  • No duplicate reports
```

---

### 4. **Manufacturer Flow**
```
Manufacturer:
  • Assigns Product Batch ID
  • Validates all upstream events exist
  • Checks all tests completed
  • Enforces sustainability compliance
  ↓
When finalized:
  • Smart contract generates UUID
  • Creates QR code
  • Stores QR → IPFS
  • Stores QR hash → Blockchain
  • Prints QR on packaging
```

---

### 5. **Consumer Portal (App-less)**
```
Consumer scans QR code
  ↓
Portal loads FHIR-style Provenance Bundle:
  • Interactive Map (GPS coordinates)
  • Farmer profile (optional)
  • Harvest details
  • All processing steps
  • All quality tests (PDF certificates)
  • Sustainability compliance status
  • Carbon footprint / eco-score
  • Batch formulation info
  • Manufacturing location
  • Expiry date & Recall status
```

---

### 6. **Admin & Regulator Dashboard**
```
AYUSH, NMPB get:
  • Real-time harvesting heatmaps
  • Over-harvest alerts
  • Zone-wise species risk levels
  • Batch compliance checks
  • Audit logs (immutable)
  • Hyperledger Explorer integration
  • Gamified view
```

---

## ✅ What's Already Implemented in Blockchain

### Current Chaincode Has:

#### ✅ Data Structures (Perfect Match!)
- [x] **CollectionEvent** with GPS, weather, images, harvest method ✓
- [x] **QualityTest** with all test types, thresholds ✓
- [x] **ProcessingStep** with parameters, status ✓
- [x] **Product** with QR code, batch ID, trace IDs ✓
- [x] **Provenance** with FHIR-style bundle ✓

#### ✅ Core Functions
- [x] `CreateCollectionEvent()` - Creates collection with validation ✓
- [x] `CreateQualityTest()` - Validates quality gates ✓
- [x] `CreateProcessingStep()` - Records processing ✓
- [x] `CreateProduct()` - Creates product ✓
- [x] `GetProvenanceByQRCode()` - Consumer scanning ✓

#### ✅ Validations
- [x] Geo-fencing check ✓
- [x] Conservation limits ✓
- [x] Quality gates (moisture, pesticides, heavy metals, aflatoxins) ✓
- [x] Sustainability score calculation ✓

---

## ❌ Critical Gaps in Current Implementation

### Gap 1: **Batch Management System** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- Batch ID generated on blockchain (not manually)
- Batch status tracking throughout lifecycle
- Admin can assign batch to processor
- Batch aggregates multiple collections
- Track batch through all stages

**Currently Missing:**
```go
❌ Batch struct
❌ CreateBatch() - Generate batch ID
❌ GetBatch() - Retrieve batch details
❌ AssignBatchToProcessor() - Admin function
❌ UpdateBatchStatus() - Automatic status changes
❌ GetBatchHistory() - Complete batch timeline
❌ QueryBatchesByStatus() - Filter by status
❌ QueryBatchesByProcessor() - See assigned batches
```

---

### Gap 2: **Season Window Validation** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- Smart contract validates season window for each species

**Currently Missing:**
```go
❌ SeasonWindow struct (species, startMonth, endMonth)
❌ validateSeasonWindow() - Check if harvest is in season
❌ GetSeasonWindows() - Retrieve allowed seasons
❌ UpdateSeasonWindow() - Admin can modify seasons
```

---

### Gap 3: **Over-Harvesting Tracking** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- Track cumulative harvest per species per season
- Prevent crossing harvest limits

**Currently Missing:**
```go
❌ HarvestLimit struct (species, season, maxQuantity, currentQuantity)
❌ trackHarvestQuantity() - Accumulate harvests
❌ validateHarvestLimit() - Check against limits
❌ GetHarvestStatistics() - Current vs limit
❌ ResetSeasonalLimits() - Reset each season
❌ Alert when approaching limit
```

---

### Gap 4: **Admin/Regulator Functions** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- Admin dashboard with real-time data
- Batch assignment to processors
- Over-harvest alerts
- Compliance checks
- Audit logs

**Currently Missing:**
```go
❌ AssignBatchToProcessor() - Admin assigns
❌ GetPendingBatches() - Batches awaiting assignment
❌ GetOverHarvestAlerts() - Real-time alerts
❌ GetComplianceReport() - Compliance checks
❌ GetAuditLogs() - Immutable audit trail
❌ GetHarvestHeatmap() - Zone-wise harvest data
❌ GetSpeciesRiskLevels() - Conservation risk
```

---

### Gap 5: **Automatic Status Changes** 🚨 MEDIUM PRIORITY
**Your Flow Requires:**
- Batch status changes automatically after each event

**Currently Missing:**
```go
❌ Automatic status updates in:
   - CreateCollectionEvent() → Batch status: "collected"
   - CreateQualityTest() → Batch status: "tested"
   - CreateProcessingStep() → Batch status: "processing"
   - CreateProduct() → Batch status: "manufactured"
```

---

### Gap 6: **QR Code & IPFS Integration** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- QR code generation on blockchain
- IPFS hash storage

**Currently Missing:**
```go
❌ generateQRCode() - Generate unique QR
❌ storeQRToIPFS() - Store QR image
❌ linkQRHashToProduct() - Store IPFS hash
```

**Note:** This is typically done in BACKEND, not chaincode!

---

### Gap 7: **Duplicate Report Prevention** 🚨 MEDIUM PRIORITY
**Your Flow Requires:**
- No duplicate quality test reports

**Currently Missing:**
```go
❌ Check if quality test already exists for batch
❌ Prevent duplicate test creation
```

---

### Gap 8: **Lab Identity Verification** 🚨 MEDIUM PRIORITY
**Your Flow Requires:**
- Valid lab identity check

**Currently Missing:**
```go
❌ RegisteredLab struct (labId, name, certifications)
❌ RegisterLab() - Admin registers labs
❌ ValidateLabIdentity() - Check if lab is registered
❌ GetRegisteredLabs() - List all labs
```

---

### Gap 9: **Advanced Queries** 🚨 MEDIUM PRIORITY
**Your Flow Requires:**
- Query by date range
- Query by zone
- Query by status
- Query by batch ID

**Currently Missing:**
```go
❌ QueryCollectionsByDateRange()
❌ QueryCollectionsByZone()
❌ QueryBatchesByStatus()
❌ QueryProductsByBatch()
❌ QueryQualityTestsByLab()
❌ QueryProcessingStepsByProcessor()
```

---

### Gap 10: **Analytics for Dashboard** 🚨 MEDIUM PRIORITY
**Your Flow Requires:**
- Real-time statistics
- Heatmaps
- Trends
- Alerts

**Currently Missing:**
```go
❌ GetFarmerStatistics() - Collections, success rate
❌ GetSpeciesStatistics() - Harvest by species
❌ GetZoneStatistics() - Harvest by zone
❌ GetLabStatistics() - Test pass/fail rates
❌ GetProcessorStatistics() - Processing efficiency
❌ GetNetworkStatistics() - Overall metrics
```

---

### Gap 11: **Alert System** 🚨 HIGH PRIORITY
**Your Flow Requires:**
- Over-harvest alerts
- Quality failure alerts
- Zone violation alerts
- Compliance alerts

**Currently Missing:**
```go
❌ Alert struct
❌ CreateAlert() - Generate alerts
❌ GetAlerts() - Retrieve alerts
❌ GetAlertsByType() - Filter by type
❌ ResolveAlert() - Mark as resolved
❌ GetActiveAlerts() - Active alerts only
```

---

## 🎯 Implementation Roadmap (Priority Order)

### Phase 1: Critical Blockchain Functions (Week 1-2)

#### Priority 1.1: Batch Management System
**Files to Create:**
- `chaincode/herbaltrace/batch.go`

```go
// Add to main.go or batch.go:

type Batch struct {
    ID                  string   `json:"id"`
    Type                string   `json:"type"` // "Batch"
    Species             string   `json:"species"`
    TotalQuantity       float64  `json:"totalQuantity"`
    Unit                string   `json:"unit"`
    CollectionEventIDs  []string `json:"collectionEventIds"`
    AssignedProcessor   string   `json:"assignedProcessor,omitempty"`
    ProcessorName       string   `json:"processorName,omitempty"`
    Status              string   `json:"status"` // "collected", "assigned", "testing", "processing", "manufactured"
    CreatedDate         string   `json:"createdDate"`
    CreatedBy           string   `json:"createdBy"` // Farmer ID
    AssignedDate        string   `json:"assignedDate,omitempty"`
    AssignedBy          string   `json:"assignedBy,omitempty"` // Admin ID
    Timestamp           string   `json:"timestamp"`
}

func (c *HerbalTraceContract) CreateBatch(ctx, batchJSON) error
func (c *HerbalTraceContract) GetBatch(ctx, batchID) (*Batch, error)
func (c *HerbalTraceContract) AssignBatchToProcessor(ctx, batchID, processorID, adminID) error
func (c *HerbalTraceContract) UpdateBatchStatus(ctx, batchID, newStatus) error
func (c *HerbalTraceContract) GetBatchHistory(ctx, batchID) (*BatchHistory, error)
func (c *HerbalTraceContract) QueryBatchesByStatus(ctx, status) ([]*Batch, error)
func (c *HerbalTraceContract) QueryBatchesByProcessor(ctx, processorID) ([]*Batch, error)
func (c *HerbalTraceContract) GetPendingBatches(ctx) ([]*Batch, error)
```

#### Priority 1.2: Season Window Validation
**Add to main.go:**

```go
type SeasonWindow struct {
    ID            string `json:"id"`
    Type          string `json:"type"` // "SeasonWindow"
    Species       string `json:"species"`
    StartMonth    int    `json:"startMonth"` // 1-12
    EndMonth      int    `json:"endMonth"`   // 1-12
    Region        string `json:"region"`
    Active        bool   `json:"active"`
}

func (c *HerbalTraceContract) CreateSeasonWindow(ctx, windowJSON) error
func (c *HerbalTraceContract) ValidateSeasonWindow(species, harvestDate, region) (bool, error)
func (c *HerbalTraceContract) GetSeasonWindows(ctx, species) ([]*SeasonWindow, error)
func (c *HerbalTraceContract) UpdateSeasonWindow(ctx, windowID, windowJSON) error

// Update CreateCollectionEvent to include season validation
func (c *HerbalTraceContract) CreateCollectionEvent(ctx, eventJSON) error {
    // ... existing code ...
    
    // Add season validation
    isInSeason, err := c.ValidateSeasonWindow(event.Species, event.HarvestDate, event.ZoneName)
    if !isInSeason {
        return fmt.Errorf("harvest outside allowed season window for species: %s", event.Species)
    }
    
    // ... rest of code ...
}
```

#### Priority 1.3: Over-Harvesting Tracking
**Add to main.go:**

```go
type HarvestLimit struct {
    ID              string  `json:"id"`
    Type            string  `json:"type"` // "HarvestLimit"
    Species         string  `json:"species"`
    Season          string  `json:"season"` // "2025-Spring", "2025-Monsoon"
    Zone            string  `json:"zone"`
    MaxQuantity     float64 `json:"maxQuantity"`
    CurrentQuantity float64 `json:"currentQuantity"`
    Unit            string  `json:"unit"`
    AlertThreshold  float64 `json:"alertThreshold"` // Alert when 80% reached
    Status          string  `json:"status"` // "normal", "warning", "exceeded"
}

func (c *HerbalTraceContract) CreateHarvestLimit(ctx, limitJSON) error
func (c *HerbalTraceContract) TrackHarvestQuantity(ctx, species, zone, season, quantity) error
func (c *HerbalTraceContract) ValidateHarvestLimit(ctx, species, zone, season, quantity) (bool, error)
func (c *HerbalTraceContract) GetHarvestStatistics(ctx, species, zone, season) (*HarvestLimit, error)
func (c *HerbalTraceContract) ResetSeasonalLimits(ctx, season) error
func (c *HerbalTraceContract) GetHarvestLimitAlerts(ctx) ([]*HarvestLimit, error)

// Update CreateCollectionEvent to track quantities
func (c *HerbalTraceContract) CreateCollectionEvent(ctx, eventJSON) error {
    // ... existing code ...
    
    // Track harvest quantity
    err := c.TrackHarvestQuantity(ctx, event.Species, event.ZoneName, getCurrentSeason(), event.Quantity)
    if err != nil {
        return err
    }
    
    // Validate harvest limit
    withinLimit, err := c.ValidateHarvestLimit(ctx, event.Species, event.ZoneName, getCurrentSeason(), event.Quantity)
    if !withinLimit {
        // Create alert
        c.CreateAlert(ctx, Alert{
            AlertType: "over_harvest",
            Severity: "critical",
            Message: "Harvest limit exceeded",
            // ...
        })
        return fmt.Errorf("harvest limit exceeded for species: %s in zone: %s", event.Species, event.ZoneName)
    }
    
    // ... rest of code ...
}
```

#### Priority 1.4: Alert System
**File:** `chaincode/herbaltrace/alerts.go`

```go
type Alert struct {
    ID           string `json:"id"`
    Type         string `json:"type"` // "Alert"
    AlertType    string `json:"alertType"` // "over_harvest", "quality_failure", "zone_violation", "season_violation"
    Severity     string `json:"severity"` // "low", "medium", "high", "critical"
    EntityID     string `json:"entityId"` // Related batch/collection/test ID
    EntityType   string `json:"entityType"` // "Batch", "CollectionEvent", "QualityTest"
    Species      string `json:"species,omitempty"`
    Zone         string `json:"zone,omitempty"`
    Message      string `json:"message"`
    Details      string `json:"details"`
    Timestamp    string `json:"timestamp"`
    Status       string `json:"status"` // "active", "acknowledged", "resolved"
    AcknowledgedBy string `json:"acknowledgedBy,omitempty"`
    AcknowledgedDate string `json:"acknowledgedDate,omitempty"`
    ResolvedBy   string `json:"resolvedBy,omitempty"`
    ResolvedDate string `json:"resolvedDate,omitempty"`
}

func (c *HerbalTraceContract) CreateAlert(ctx, alertJSON) error
func (c *HerbalTraceContract) GetAlerts(ctx) ([]*Alert, error)
func (c *HerbalTraceContract) GetAlertsByType(ctx, alertType) ([]*Alert, error)
func (c *HerbalTraceContract) GetAlertsBySeverity(ctx, severity) ([]*Alert, error)
func (c *HerbalTraceContract) GetActiveAlerts(ctx) ([]*Alert, error)
func (c *HerbalTraceContract) AcknowledgeAlert(ctx, alertID, userID) error
func (c *HerbalTraceContract) ResolveAlert(ctx, alertID, userID, resolution) error
```

---

### Phase 2: Admin & Regulator Functions (Week 3)

#### Priority 2.1: Lab Registration
**Add to main.go:**

```go
type RegisteredLab struct {
    ID             string   `json:"id"`
    Type           string   `json:"type"` // "RegisteredLab"
    LabName        string   `json:"labName"`
    LabID          string   `json:"labId"`
    Certifications []string `json:"certifications"`
    Location       string   `json:"location"`
    Active         bool     `json:"active"`
    RegisteredDate string   `json:"registeredDate"`
    RegisteredBy   string   `json:"registeredBy"` // Admin ID
}

func (c *HerbalTraceContract) RegisterLab(ctx, labJSON) error
func (c *HerbalTraceContract) ValidateLabIdentity(ctx, labID) (bool, error)
func (c *HerbalTraceContract) GetRegisteredLabs(ctx) ([]*RegisteredLab, error)
func (c *HerbalTraceContract) DeactivateLab(ctx, labID) error

// Update CreateQualityTest to validate lab
func (c *HerbalTraceContract) CreateQualityTest(ctx, testJSON) error {
    // ... existing code ...
    
    // Validate lab identity
    isValid, err := c.ValidateLabIdentity(ctx, test.LabID)
    if !isValid {
        return fmt.Errorf("invalid lab identity: %s", test.LabID)
    }
    
    // Check for duplicate reports
    existingTests, _ := c.QueryQualityTestsByBatch(ctx, test.BatchID)
    for _, existingTest := range existingTests {
        if existingTest.LabID == test.LabID && existingTest.Status != "rejected" {
            return fmt.Errorf("duplicate test report from lab: %s for batch: %s", test.LabID, test.BatchID)
        }
    }
    
    // ... rest of code ...
}
```

#### Priority 2.2: Advanced Queries
**File:** `chaincode/herbaltrace/queries.go`

```go
func (c *HerbalTraceContract) QueryCollectionsByDateRange(ctx, startDate, endDate) ([]*CollectionEvent, error)
func (c *HerbalTraceContract) QueryCollectionsByZone(ctx, zoneName) ([]*CollectionEvent, error)
func (c *HerbalTraceContract) QueryBatchesByStatus(ctx, status) ([]*Batch, error)
func (c *HerbalTraceContract) QueryProductsByBatch(ctx, batchID) ([]*Product, error)
func (c *HerbalTraceContract) QueryQualityTestsByLab(ctx, labID) ([]*QualityTest, error)
func (c *HerbalTraceContract) QueryQualityTestsByBatch(ctx, batchID) ([]*QualityTest, error)
func (c *HerbalTraceContract) QueryProcessingStepsByProcessor(ctx, processorID) ([]*ProcessingStep, error)
func (c *HerbalTraceContract) QueryProcessingStepsByBatch(ctx, batchID) ([]*ProcessingStep, error)
func (c *HerbalTraceContract) QueryProductsByManufacturer(ctx, manufacturerID) ([]*Product, error)
```

#### Priority 2.3: Analytics Functions
**File:** `chaincode/herbaltrace/analytics.go`

```go
type FarmerStatistics struct {
    FarmerID          string  `json:"farmerId"`
    FarmerName        string  `json:"farmerName"`
    TotalCollections  int     `json:"totalCollections"`
    TotalQuantity     float64 `json:"totalQuantity"`
    Unit              string  `json:"unit"`
    SpeciesCount      int     `json:"speciesCount"`
    SuccessRate       float64 `json:"successRate"` // % approved
    AverageScore      float64 `json:"averageScore"`
}

type SpeciesStatistics struct {
    Species           string  `json:"species"`
    TotalHarvested    float64 `json:"totalHarvested"`
    TotalLimit        float64 `json:"totalLimit"`
    PercentageUsed    float64 `json:"percentageUsed"`
    ZonesHarvested    []string `json:"zonesHarvested"`
    FarmersCount      int     `json:"farmersCount"`
    AverageQuality    float64 `json:"averageQuality"`
}

type ZoneStatistics struct {
    ZoneName          string  `json:"zoneName"`
    TotalCollections  int     `json:"totalCollections"`
    SpeciesCount      int     `json:"speciesCount"`
    TotalQuantity     float64 `json:"totalQuantity"`
    ComplianceRate    float64 `json:"complianceRate"`
    RiskLevel         string  `json:"riskLevel"` // "low", "medium", "high"
}

func (c *HerbalTraceContract) GetFarmerStatistics(ctx, farmerID) (*FarmerStatistics, error)
func (c *HerbalTraceContract) GetSpeciesStatistics(ctx, species, season) (*SpeciesStatistics, error)
func (c *HerbalTraceContract) GetZoneStatistics(ctx, zoneName) (*ZoneStatistics, error)
func (c *HerbalTraceContract) GetLabStatistics(ctx, labID) (*LabStatistics, error)
func (c *HerbalTraceContract) GetProcessorStatistics(ctx, processorID) (*ProcessorStatistics, error)
func (c *HerbalTraceContract) GetNetworkStatistics(ctx) (*NetworkStatistics, error)
func (c *HerbalTraceContract) GetHarvestHeatmapData(ctx) (map[string]interface{}, error)
```

---

### Phase 3: Status Update Automation (Week 4)

#### Update All Create Functions
```go
// Update CreateCollectionEvent
func (c *HerbalTraceContract) CreateCollectionEvent(ctx, eventJSON) error {
    // ... existing validations ...
    
    // Auto-update batch status
    if event.BatchID != "" {
        c.UpdateBatchStatus(ctx, event.BatchID, "collected")
    }
    
    // ... save event ...
}

// Update CreateQualityTest
func (c *HerbalTraceContract) CreateQualityTest(ctx, testJSON) error {
    // ... existing validations ...
    
    // Auto-update batch status
    c.UpdateBatchStatus(ctx, test.BatchID, "tested")
    
    // If test failed, create alert
    if test.OverallResult == "fail" {
        c.CreateAlert(ctx, Alert{
            AlertType: "quality_failure",
            Severity: "high",
            EntityID: test.BatchID,
            EntityType: "QualityTest",
            Message: "Quality test failed for batch",
            // ...
        })
    }
    
    // ... save test ...
}

// Update CreateProcessingStep
func (c *HerbalTraceContract) CreateProcessingStep(ctx, stepJSON) error {
    // ... existing validations ...
    
    // Auto-update batch status
    c.UpdateBatchStatus(ctx, step.BatchID, "processing")
    
    // ... save step ...
}

// Update CreateProduct
func (c *HerbalTraceContract) CreateProduct(ctx, productJSON) error {
    // ... existing validations ...
    
    // Auto-update batch status
    c.UpdateBatchStatus(ctx, product.BatchID, "manufactured")
    
    // ... save product ...
}
```

---

## 📋 Complete Implementation Checklist

### Week 1-2: Critical Functions
- [ ] Create `batch.go` with Batch struct and 8 functions
- [ ] Add SeasonWindow struct and 4 functions to main.go
- [ ] Add HarvestLimit struct and 6 functions to main.go
- [ ] Create `alerts.go` with Alert struct and 7 functions
- [ ] Update CreateCollectionEvent with all validations
- [ ] Test batch creation and assignment
- [ ] Test season validation
- [ ] Test harvest limit tracking
- [ ] Test alert generation

### Week 3: Admin & Queries
- [ ] Add RegisteredLab struct and 4 functions
- [ ] Create `queries.go` with 9 query functions
- [ ] Create `analytics.go` with 7 analytics functions
- [ ] Update CreateQualityTest with lab validation
- [ ] Add duplicate report check
- [ ] Test all query functions
- [ ] Test analytics calculations

### Week 4: Automation & Polish
- [ ] Add automatic status updates to all Create functions
- [ ] Add alert creation on failures
- [ ] Add comprehensive logging
- [ ] Write unit tests for all functions
- [ ] Integration testing
- [ ] Performance testing
- [ ] Deploy to test network

---

## 🎯 Next Immediate Steps

1. **Start with Batch Management** - This is the foundation of your flow
2. **Add Season & Harvest Limit Validation** - Critical for compliance
3. **Implement Alert System** - Needed for admin dashboard
4. **Add Admin Functions** - Batch assignment, lab registration
5. **Create Query Functions** - For all dashboards
6. **Add Analytics** - For reports and heatmaps
7. **Test End-to-End** - Complete flow from farmer to consumer

**Want me to start implementing these chaincode enhancements?**
