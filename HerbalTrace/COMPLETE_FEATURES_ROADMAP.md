# 🎯 HerbalTrace - Complete Features & Implementation Roadmap

## 📋 Table of Contents
1. [Blockchain Functions Overview](#blockchain-functions-overview)
2. [Backend Features Breakdown](#backend-features-breakdown)
3. [Frontend Features Breakdown](#frontend-features-breakdown)
4. [Encrypted QR Code Implementation](#encrypted-qr-code-implementation)
5. [AR Journey Visualization](#ar-journey-visualization)
6. [Development Timeline](#development-timeline)
7. [Team Responsibilities](#team-responsibilities)

---

## 🔗 Blockchain Functions Overview (38 Functions)

### ✅ Already Deployed on Hyperledger Fabric v2.1

#### **Category 1: Collection Events (Farmer Operations)** - 5 Functions
```javascript
1. CreateCollectionEvent(eventJSON)
   - Records farmer harvest with GPS, species, quantity
   - Validates season window, geo-fencing, harvest limits
   - Auto-generates alerts for violations
   - Returns: Collection Event ID

2. GetCollectionEvent(eventId)
   - Retrieves single collection event by ID
   - Returns: CollectionEvent object

3. QueryCollectionsByFarmer(farmerId)
   - Lists all harvests by specific farmer
   - Uses CouchDB index: indexCollectionFarmer
   - Returns: Array of CollectionEvent objects

4. QueryCollectionsBySpecies(species)
   - Lists all harvests for a species (e.g., "Ashwagandha")
   - Returns: Array of CollectionEvent objects

5. QueryCollectionsByDateRange(startDate, endDate)
   - Lists harvests within date range
   - Returns: Array of CollectionEvent objects
```

#### **Category 2: Batch Management** - 8 Functions
```javascript
6. CreateBatch(batchJSON)
   - Groups multiple collection events into batch
   - Auto-generates batch ID (BATCH-2025-XXX)
   - Sets initial status: "collected"
   - Returns: Batch ID

7. GetBatch(batchId)
   - Retrieves batch details by ID
   - Returns: Batch object

8. UpdateBatchStatus(batchId, status)
   - Updates status: collected→testing→processing→manufactured
   - Returns: Success confirmation

9. AssignBatchToProcessor(batchId, processorId, processorName)
   - Assigns batch to processor for manufacturing
   - Updates status to "assigned"
   - Returns: Assignment confirmation

10. QueryBatchesByStatus(status)
    - Lists batches by status (e.g., "collected", "testing")
    - Uses CouchDB index: indexBatchStatus
    - Returns: Array of Batch objects

11. QueryBatchesByProcessor(processorId)
    - Lists batches assigned to processor
    - Uses CouchDB index: indexBatchProcessor
    - Returns: Array of Batch objects

12. GetPendingBatches()
    - Lists all unassigned batches
    - Returns: Array of Batch objects

13. GetBatchHistory(batchId)
    - Complete audit trail of batch status changes
    - Returns: Array of status change events with timestamps
```

#### **Category 3: Quality Testing (Lab Operations)** - 4 Functions
```javascript
14. CreateQualityTest(testJSON)
    - Records lab test results
    - Tests: active compounds, pesticides, heavy metals, DNA barcoding
    - Uploads certificate PDF to IPFS/S3
    - Auto-updates batch status to "testing_complete"
    - Returns: Quality Test ID

15. GetQualityTest(testId)
    - Retrieves test results by ID
    - Returns: QualityTest object

16. QueryQualityTestsByBatch(batchId)
    - Lists all tests for a batch
    - Uses CouchDB index: indexQualityTestBatch
    - Returns: Array of QualityTest objects

17. QueryQualityTestsByLab(labId)
    - Lists all tests performed by lab
    - Returns: Array of QualityTest objects
```

#### **Category 4: Processing Steps (Manufacturing)** - 4 Functions
```javascript
18. CreateProcessingStep(stepJSON)
    - Records processing: drying, grinding, extraction, formulation
    - Tracks input/output quantities, temperature, duration
    - Links to previous step (quality test or processing)
    - Returns: Processing Step ID

19. GetProcessingStep(stepId)
    - Retrieves processing step details
    - Returns: ProcessingStep object

20. QueryProcessingStepsByBatch(batchId)
    - Lists all processing steps for batch
    - Returns: Array of ProcessingStep objects

21. GetProcessingChain(stepId)
    - Complete processing workflow from raw to final
    - Returns: Array of ProcessingStep objects (chronological)
```

#### **Category 5: Products & QR Codes** - 4 Functions
```javascript
22. CreateProduct(productJSON)
    - Creates final product with encrypted QR code
    - Links to collection events, quality tests, processing steps
    - Generates sustainability score (0-100)
    - Returns: Product ID + QR Code

23. GetProduct(productId)
    - Retrieves product details by ID
    - Returns: Product object

24. GetProductByQRCode(qrCode)
    - Consumer scan: Retrieves product by QR code
    - Returns: Product object

25. QueryProductsByManufacturer(manufacturerId)
    - Lists all products by manufacturer
    - Returns: Array of Product objects
```

#### **Category 6: Provenance & Traceability (Consumer View)** - 2 Functions
```javascript
26. GenerateProvenance(productId)
    - Complete supply chain history bundle
    - Includes: farmers, labs, processors, sustainability score
    - Calculates total distance traveled
    - Returns: Provenance bundle (FHIR-style)

27. GetProvenanceByQRCode(qrCode)
    - Consumer QR scan → Complete journey
    - Returns: Provenance bundle
```

#### **Category 7: Season Windows (Validation)** - 4 Functions
```javascript
28. CreateSeasonWindow(windowJSON)
    - Defines allowed harvest period for species/region
    - Example: Ashwagandha in Madhya Pradesh (Nov-Feb)
    - Returns: Season Window ID

29. GetSeasonWindows(species)
    - Lists all season windows for species
    - Uses CouchDB index: indexSeasonWindow
    - Returns: Array of SeasonWindow objects

30. UpdateSeasonWindow(windowId, updateJSON)
    - Modifies existing season window
    - Returns: Success confirmation

31. ValidateSeasonWindow(species, harvestDate, region)
    - Checks if harvest date is within allowed window
    - Called automatically during CreateCollectionEvent
    - Returns: Boolean (valid/invalid)
```

#### **Category 8: Harvest Limits (Quota Management)** - 4 Functions
```javascript
32. CreateHarvestLimit(limitJSON)
    - Sets maximum harvest quantity for farmer/species/season
    - Example: FARM001 can harvest 500kg Ashwagandha in 2025-Winter
    - Returns: Harvest Limit ID

33. TrackHarvestQuantity(limitId, quantity)
    - Updates current harvest quantity
    - Triggers alert when approaching limit (80% threshold)
    - Returns: Remaining quota

34. GetHarvestStatistics(farmerId, species, season)
    - Shows quota usage: max, current, remaining
    - Returns: HarvestStatistics object

35. ValidateHarvestLimit(farmerId, species, season, quantity)
    - Checks if harvest exceeds limit
    - Called automatically during CreateCollectionEvent
    - Returns: Boolean (within limit/exceeded)
```

#### **Category 9: Alerts & Violations** - 5 Functions
```javascript
36. CreateAlert(alertJSON)
    - Creates alert for violations
    - Types: season_window, harvest_limit, geo_fence, quality_fail
    - Severity: low, medium, high, critical
    - Returns: Alert ID

37. GetActiveAlerts()
    - Lists all unresolved alerts
    - Uses CouchDB index: indexAlertStatus
    - Returns: Array of Alert objects

38. GetCriticalAlerts()
    - Lists critical severity alerts only
    - Returns: Array of Alert objects

39. AcknowledgeAlert(alertId, acknowledgedBy)
    - Marks alert as acknowledged
    - Returns: Success confirmation

40. ResolveAlert(alertId, resolvedBy, resolutionNotes)
    - Marks alert as resolved
    - Returns: Success confirmation

41. GetAlertStatistics()
    - Alert counts by type, severity, status
    - Returns: AlertStatistics object
```

---

## 🛠️ Backend Features Breakdown

### **MVP Phase 1 (Weeks 1-4)** - Core Supply Chain ✅

#### **1.1 Authentication & User Management**
```typescript
Features:
✅ User Registration (Farmer, Lab, Processor, Manufacturer, Admin)
✅ JWT-based Authentication (Access + Refresh Tokens)
✅ Role-Based Access Control (RBAC)
✅ Fabric Wallet Identity Registration
✅ User Profile Management
✅ KYC Document Upload & Verification
✅ Organization Management

Endpoints:
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh-token
POST   /api/v1/auth/logout
GET    /api/v1/users/profile
PUT    /api/v1/users/profile
POST   /api/v1/users/kyc-upload
GET    /api/v1/users/verify-kyc/:userId
```

#### **1.2 Collection Events (Farmer Harvest Tracking)**
```typescript
Features:
✅ Create Collection Event with GPS Auto-Capture
✅ Multi-Image Upload (S3/IPFS)
✅ Weather Data Integration (OpenWeatherMap)
✅ Season Window Validation (with 15s delay handling)
✅ Geo-Fencing Validation
✅ Harvest Limit Checking
✅ Auto-Alert Generation
✅ Offline Data Caching (sync when online)

Endpoints:
POST   /api/v1/collections
GET    /api/v1/collections/:id
GET    /api/v1/collections/farmer/:farmerId
GET    /api/v1/collections/species/:species
POST   /api/v1/collections/:id/images
GET    /api/v1/collections/pending-sync
```

#### **1.3 Batch Management**
```typescript
Features:
✅ Create Batch from Collection Events
✅ Assign Batch to Processor
✅ Update Batch Status (collected→assigned→testing→processing→manufactured)
✅ Query Batches by Status
✅ Query Batches by Processor
✅ Get Pending Batches
✅ Batch History/Audit Trail

Endpoints:
POST   /api/v1/batches
GET    /api/v1/batches/:id
PUT    /api/v1/batches/:id/assign
PUT    /api/v1/batches/:id/status
GET    /api/v1/batches/status/:status
GET    /api/v1/batches/processor/:processorId
GET    /api/v1/batches/pending
GET    /api/v1/batches/:id/history
```

#### **1.4 Quality Testing (Lab Operations)**
```typescript
Features:
✅ Create Quality Test Results
✅ Certificate Upload (PDF to IPFS/S3)
✅ Test Parameters: Active compounds, pesticides, heavy metals, DNA
✅ Pass/Fail Logic
✅ Auto-Update Batch Status
✅ Query Tests by Batch
✅ Query Tests by Lab

Endpoints:
POST   /api/v1/quality-tests
GET    /api/v1/quality-tests/:id
GET    /api/v1/quality-tests/batch/:batchId
GET    /api/v1/quality-tests/lab/:labId
POST   /api/v1/quality-tests/:id/certificate
```

#### **1.5 Processing Steps (Manufacturing)**
```typescript
Features:
✅ Create Processing Step (drying, grinding, extraction, formulation)
✅ Track Input/Output Quantities
✅ Record Process Parameters (temperature, duration, equipment)
✅ Link to Previous Step (quality test or processing)
✅ Query Steps by Batch
✅ Get Complete Processing Chain

Endpoints:
POST   /api/v1/processing
GET    /api/v1/processing/:id
GET    /api/v1/processing/batch/:batchId
GET    /api/v1/processing/chain/:stepId
```

#### **1.6 Products & Encrypted QR Codes** ⭐ NEW
```typescript
Features:
✅ Create Product with Encrypted QR Code
✅ AES-256 Encryption for QR Data
✅ Public/Private Key Pair Generation
✅ QR Code Image Generation (300x300 PNG)
✅ Sustainability Score Calculation
✅ Query Products by Manufacturer
✅ Consumer QR Scan with Decryption

Encryption Details:
- Algorithm: AES-256-CBC
- QR Payload: Encrypted JSON containing productId + timestamp + signature
- Decryption Key: Stored securely, shared via API for authorized scans
- QR Format: base64(encrypted(JSON.stringify({productId, timestamp, hash})))

Endpoints:
POST   /api/v1/products
GET    /api/v1/products/:id
GET    /api/v1/products/qr/:qrCode
GET    /api/v1/products/:id/qr-image
POST   /api/v1/products/qr/decrypt
GET    /api/v1/products/manufacturer/:manufacturerId
```

#### **1.7 Provenance & Consumer Traceability**
```typescript
Features:
✅ Generate Complete Provenance Bundle
✅ Consumer QR Scan → Full Journey
✅ Display Farmers, Labs, Processors
✅ Show GPS Coordinates on Map
✅ Calculate Total Distance Traveled
✅ Display Sustainability Score
✅ Timestamps for Each Step

Endpoints:
GET    /api/v1/provenance/qr/:qrCode
GET    /api/v1/provenance/product/:productId
POST   /api/v1/provenance/decrypt-and-fetch
```

---

### **MVP Phase 2 (Weeks 5-7)** - Advanced Features 🚀

#### **2.1 Season Windows Management**
```typescript
Features:
✅ Create Season Windows (Admin)
✅ Pre-populate Season Windows (Initialization)
✅ Update Season Windows
✅ Query Season Windows by Species
✅ Validate Harvest Date (with 15s delay handling)

Endpoints:
POST   /api/v1/season-windows
GET    /api/v1/season-windows
GET    /api/v1/season-windows/species/:species
PUT    /api/v1/season-windows/:id
POST   /api/v1/season-windows/validate
```

#### **2.2 Harvest Limits & Quota Management**
```typescript
Features:
✅ Create Harvest Limits (Admin)
✅ Track Harvest Quantities
✅ Get Harvest Statistics (quota usage)
✅ Validate Harvest Against Limit
✅ Auto-Alert when Approaching Limit (80% threshold)

Endpoints:
POST   /api/v1/harvest-limits
GET    /api/v1/harvest-limits/:id
GET    /api/v1/harvest-limits/farmer/:farmerId
GET    /api/v1/harvest-limits/stats
POST   /api/v1/harvest-limits/validate
```

#### **2.3 Alerts & Violation Management**
```typescript
Features:
✅ Create Alerts (Auto & Manual)
✅ Get Active Alerts
✅ Get Critical Alerts
✅ Acknowledge Alerts
✅ Resolve Alerts with Notes
✅ Get Alert Statistics
✅ Real-Time Alert Notifications (WebSocket)

Endpoints:
POST   /api/v1/alerts
GET    /api/v1/alerts
GET    /api/v1/alerts/active
GET    /api/v1/alerts/critical
PUT    /api/v1/alerts/:id/acknowledge
PUT    /api/v1/alerts/:id/resolve
GET    /api/v1/alerts/stats
```

#### **2.4 Notifications System**
```typescript
Features:
✅ Push Notifications (Firebase Cloud Messaging)
✅ SMS Notifications (Twilio)
✅ Email Notifications (SendGrid)
✅ In-App Notifications
✅ Notification Preferences Management
✅ Notification History

Types:
- Batch assignment notifications
- Quality test results
- Alert notifications
- Harvest limit warnings
- System announcements

Endpoints:
POST   /api/v1/notifications/subscribe
GET    /api/v1/notifications
PUT    /api/v1/notifications/:id/read
GET    /api/v1/notifications/unread
PUT    /api/v1/notifications/preferences
```

#### **2.5 Analytics & Dashboards**
```typescript
Features:
✅ Role-Based Dashboards (Farmer, Lab, Processor, Manufacturer, Admin)
✅ Real-Time Statistics
✅ Harvest Trends & Forecasting
✅ Quality Test Pass Rates
✅ Supply Chain Performance Metrics
✅ Sustainability Score Trends
✅ Export Reports (PDF, Excel)

Farmer Dashboard:
- Total collections, quantity harvested
- Harvest limit status, remaining quota
- Active alerts, recent collections
- Earnings, payment status

Lab Dashboard:
- Total tests performed, pass rate
- Pending tests, recent tests
- Average turnaround time

Processor Dashboard:
- Assigned batches, processing status
- Input/output efficiency
- Processing time metrics

Manufacturer Dashboard:
- Products created, inventory
- Sustainability scores
- Distribution channels

Admin Dashboard:
- Network-wide statistics
- User activity, transaction volume
- Alert summary, compliance status
- System health monitoring

Endpoints:
GET    /api/v1/analytics/dashboard
GET    /api/v1/analytics/harvest-trends
GET    /api/v1/analytics/quality-metrics
GET    /api/v1/analytics/sustainability
POST   /api/v1/analytics/export
```

---

### **Phase 3 (Weeks 8-10)** - Enhanced Features ⭐

#### **3.1 Encrypted QR Code System** ⭐ NEW
```typescript
Implementation Details:

1. QR Generation:
   - Encrypt product data using AES-256-CBC
   - Generate unique encryption key per product
   - Create QR code with encrypted payload
   - Store decryption key securely (PostgreSQL encrypted column)

2. QR Scanning:
   - Consumer scans QR code
   - Backend receives encrypted payload
   - Decrypts using stored key
   - Returns provenance data

3. Security Features:
   - Time-based expiration (optional)
   - Scan count tracking
   - IP-based rate limiting
   - Tamper detection (hash verification)

Code Example:
```typescript
// QR Generation
const crypto = require('crypto');

function generateEncryptedQR(productData) {
  const key = crypto.randomBytes(32); // 256-bit key
  const iv = crypto.randomBytes(16);  // Initialization vector
  
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(JSON.stringify(productData), 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const qrPayload = {
    data: encrypted,
    iv: iv.toString('hex'),
    timestamp: Date.now()
  };
  
  const qrCode = Buffer.from(JSON.stringify(qrPayload)).toString('base64');
  
  // Store key securely
  await storeEncryptionKey(productData.id, key.toString('hex'));
  
  return qrCode;
}

// QR Decryption
async function decryptQR(qrCode) {
  const payload = JSON.parse(Buffer.from(qrCode, 'base64').toString());
  
  // Verify timestamp (prevent replay attacks)
  if (Date.now() - payload.timestamp > 3600000) {
    throw new Error('QR code expired');
  }
  
  const key = await getEncryptionKey(payload.productId);
  const decipher = crypto.createDecipheriv('aes-256-cbc', 
    Buffer.from(key, 'hex'), 
    Buffer.from(payload.iv, 'hex')
  );
  
  let decrypted = decipher.update(payload.data, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return JSON.parse(decrypted);
}
```

Endpoints:
POST   /api/v1/qr/generate
POST   /api/v1/qr/decrypt
GET    /api/v1/qr/verify/:qrCode
GET    /api/v1/qr/stats/:productId
```

#### **3.2 AR Journey Visualization** ⭐ NEW
```typescript
AR Implementation Strategy:

Option 1: WebXR (Browser-based AR)
- Use WebXR Device API
- No app installation required
- Works on mobile browsers with AR support
- Display 3D journey overlay on product packaging

Option 2: AR.js (Marker-based AR)
- Use QR code as AR marker
- Display 3D supply chain journey
- Show farmer location, lab testing, processing steps
- Interactive 3D globe with GPS pins

Option 3: Unity + Vuforia (Native App AR)
- Mobile app with AR capabilities
- Scan product → 3D journey appears
- Interactive 3D models of herbs, farms, labs
- Gamification elements

Recommended: Hybrid Approach
1. WebXR for basic AR (immediate access)
2. Native app for advanced AR (better UX)

Features:
✅ Scan product → 3D journey overlay
✅ Show GPS locations as 3D pins on globe
✅ Timeline visualization (farm → lab → processor → product)
✅ Interactive farmer profiles (tap pin to see details)
✅ 3D herb models (Ashwagandha plant rotating)
✅ Distance traveled animation
✅ Sustainability score visualization (green meter)
✅ Quality test results as AR cards
✅ Processing steps as 3D animations

Technical Stack:
- Frontend: React Native + ViroReact (AR framework)
- 3D Models: Blender → glTF format
- AR Markers: QR codes on packaging
- Backend API: Provenance data endpoint

Backend Support Required:
1. Provenance API with 3D coordinates
2. 3D model URLs (stored in S3)
3. AR marker registration
4. AR analytics (scan tracking)

Endpoints:
GET    /api/v1/ar/journey/:qrCode
GET    /api/v1/ar/3d-models
GET    /api/v1/ar/markers/:productId
POST   /api/v1/ar/track-scan
GET    /api/v1/ar/analytics
```

#### **3.3 Blockchain Explorer (Admin)**
```typescript
Features:
✅ View All Blocks
✅ View Transactions by Block
✅ Search by Transaction ID
✅ View Chaincode Events
✅ Network Status Monitoring
✅ Peer Health Checks

Endpoints:
GET    /api/v1/blockchain/blocks
GET    /api/v1/blockchain/blocks/:blockNumber
GET    /api/v1/blockchain/transactions/:txId
GET    /api/v1/blockchain/events
GET    /api/v1/blockchain/network-status
```

---

## 📱 Frontend Features Breakdown

### **Mobile App (Flutter)** - Farmer & Consumer

#### **Phase 1: Core Features (Weeks 1-6)**

##### **1.1 Authentication & Onboarding**
```dart
Screens:
✅ Splash Screen
✅ Login Screen
✅ Registration Screen (Role Selection)
✅ OTP Verification
✅ KYC Upload Screen
✅ Profile Setup
✅ Tutorial/Walkthrough

Features:
- Biometric authentication (fingerprint/face ID)
- Offline login (cached credentials)
- Multi-language support (Hindi, English, Marathi, Telugu)
```

##### **1.2 Farmer Features**
```dart
Screens:
✅ Dashboard (Harvest stats, pending tasks, alerts)
✅ Create Collection Event Screen
  - GPS auto-capture with map view
  - Species dropdown (autocomplete)
  - Quantity input with unit selection
  - Multi-image capture (camera/gallery)
  - Weather display (auto-fetched)
  - Harvest method selection
  - Part collected selection
✅ Collection History Screen (list + filters)
✅ Harvest Limit Tracker Screen (quota visualization)
✅ Alerts Screen (violations, warnings)
✅ Earnings/Payment Screen (future)

Features:
- Offline mode (data cached, synced when online)
- Camera integration (multiple images)
- GPS auto-capture with accuracy indicator
- Season window warnings
- Harvest limit progress bar
- Push notifications
```

##### **1.3 Consumer Features (QR Scanning)**
```dart
Screens:
✅ QR Scanner Screen
✅ Provenance Journey Screen
  - Timeline view (farm → lab → processor → product)
  - Interactive map with GPS pins
  - Farmer profiles (name, photo, farm details)
  - Quality test results (pass/fail badges)
  - Processing steps (drying, grinding)
  - Sustainability score (0-100 with color coding)
  - Total distance traveled
✅ Product Details Screen
✅ AR Journey Screen (scan to view 3D journey) ⭐ NEW

Features:
- Encrypted QR decryption
- Offline provenance caching (last 10 scans)
- Share journey (WhatsApp, Twitter)
- Multi-language support
- AR journey visualization ⭐
```

##### **1.4 Common Features**
```dart
Screens:
✅ Profile Screen
✅ Settings Screen
✅ Notification Center
✅ Help/FAQ Screen
✅ About Screen

Features:
- Dark mode support
- Language selection
- Notification preferences
- Cache management
```

#### **Phase 2: Advanced Features (Weeks 7-10)**

##### **2.1 AR Journey Visualization** ⭐ NEW
```dart
Implementation:
- Use ARCore (Android) / ARKit (iOS)
- Package: ar_flutter_plugin or viro_flutter

Screens:
✅ AR Scanner Screen
  - Detect product using camera
  - Overlay 3D journey
✅ AR Journey View
  - 3D globe with GPS pins
  - Animated supply chain path
  - Interactive elements (tap to see details)
  - 3D herb models (rotating Ashwagandha plant)

Features:
- Marker-based AR (QR code as marker)
- Markerless AR (product recognition)
- 3D animations (journey timeline)
- Interactive hotspots (tap farmer pin → profile)
- Screenshot/share AR view
- AR tutorial (first-time guidance)

Dependencies:
dependencies:
  ar_flutter_plugin: ^0.7.3
  vector_math: ^2.1.4
  model_viewer_plus: ^1.5.0  # For 3D models
```

##### **2.2 Farmer Features (Advanced)**
```dart
Screens:
✅ Batch Tracking Screen (view batches created from collections)
✅ Quality Test Results Screen (view lab test results)
✅ Earnings Dashboard (payment tracking)
✅ Weather Forecast Screen (7-day forecast for harvest planning)
✅ Harvest Calendar Screen (season window visualization)

Features:
- Real-time batch status updates
- Quality test notifications
- Harvest planning based on weather
- Season window calendar view
- Earnings breakdown (per collection event)
```

##### **2.3 Offline Capabilities**
```dart
Features:
✅ Offline data collection (SQLite cache)
✅ Auto-sync when online (background sync)
✅ Conflict resolution (last-write-wins)
✅ Sync status indicator
✅ Manual sync trigger

Implementation:
- Use sqflite for local database
- Use connectivity_plus to detect network
- Use work_manager for background sync
```

---

### **Web Portal (React)** - Lab, Processor, Manufacturer, Admin

#### **Phase 1: Core Features (Weeks 1-6)**

##### **1.1 Authentication & Dashboard**
```jsx
Pages:
✅ Login Page
✅ Dashboard (role-based)
✅ Profile Page
✅ Settings Page

Features:
- JWT authentication
- Remember me (refresh token)
- Role-based navigation
- Real-time statistics
```

##### **1.2 Lab Features**
```jsx
Pages:
✅ Pending Tests Page (list of batches awaiting testing)
✅ Create Quality Test Page
  - Batch selection (dropdown with details)
  - Test parameters form (active compounds, pesticides, etc.)
  - Certificate upload (drag-drop PDF)
  - Pass/Fail selection
  - Tester signature upload
✅ Test History Page (filters, search)
✅ Certificate Viewer Page (PDF viewer)

Features:
- Batch details preview
- Certificate validation (PDF size, format)
- Auto-save draft
- Batch status auto-update
```

##### **1.3 Processor Features**
```jsx
Pages:
✅ Assigned Batches Page (list with status)
✅ Create Processing Step Page
  - Batch selection
  - Process type selection (drying, grinding, extraction)
  - Input/output quantity tracking
  - Process parameters (temperature, duration, equipment)
  - Link to previous step
✅ Processing History Page
✅ Processing Chain Viewer (flowchart visualization)

Features:
- Batch assignment notifications
- Input/output efficiency calculation
- Process parameter validation
- Visual flowchart (collection → test → processing)
```

##### **1.4 Manufacturer Features**
```jsx
Pages:
✅ Batch Selection Page (for product creation)
✅ Create Product Page
  - Product name, quantity
  - Batch selection (multi-select for blending)
  - Collection events selection
  - Quality tests selection
  - Processing steps selection
  - Encrypted QR generation ⭐
  - Sustainability score input
  - Certification IDs
✅ Product Inventory Page
✅ QR Code Management Page
  - View generated QR codes
  - Download QR images (PNG, SVG)
  - Print QR labels
  - QR scan statistics

Features:
- Encrypted QR generation with preview
- QR code download (PNG, SVG, PDF)
- Bulk QR generation
- QR analytics (scans per product)
```

##### **1.5 Admin Features**
```jsx
Pages:
✅ User Management Page (CRUD users)
✅ Season Windows Management Page
  - Create season windows
  - Edit season windows
  - Calendar view
✅ Harvest Limits Management Page
  - Set limits per farmer/species/season
  - Monitor quota usage
✅ Alerts Dashboard Page
  - Active alerts (table view)
  - Critical alerts (highlighted)
  - Acknowledge/Resolve actions
  - Alert statistics (charts)
✅ Analytics Dashboard Page
  - Network-wide statistics
  - Charts (harvest trends, quality metrics)
  - Export reports (PDF, Excel)
✅ Blockchain Explorer Page
  - View blocks, transactions
  - Search by TX ID
  - Network status monitoring

Features:
- Real-time dashboards (WebSocket updates)
- Interactive charts (Chart.js / Recharts)
- Export reports (PDF, Excel)
- User role management
- System health monitoring
```

#### **Phase 2: Advanced Features (Weeks 7-10)**

##### **2.1 Interactive Supply Chain Map**
```jsx
Page:
✅ Supply Chain Map Page
  - Show all collection events on map (GPS pins)
  - Show lab locations, processor locations
  - Draw supply chain paths (lines connecting pins)
  - Filter by species, date range
  - Click pin → View details

Features:
- Google Maps / Mapbox integration
- Heatmap visualization (harvest density)
- Route visualization (product journey)
- Distance calculation
```

##### **2.2 AR Journey Viewer (Web)** ⭐ NEW
```jsx
Page:
✅ AR Preview Page (for manufacturers)
  - Preview how AR journey looks
  - Test AR with webcam
  - Download AR marker (QR code)

Implementation:
- Use WebXR API
- Use AR.js for marker-based AR
- Display 3D journey in browser (no app needed)

Features:
- WebXR-based AR (browser AR)
- 3D journey preview
- Share AR link with consumers
```

##### **2.3 Reporting & Analytics**
```jsx
Pages:
✅ Advanced Analytics Page
  - Custom date range selection
  - Multi-metric comparison
  - Predictive analytics (harvest forecasting)
  - Sustainability trends
✅ Custom Reports Page
  - Report builder (drag-drop widgets)
  - Schedule reports (daily, weekly, monthly)
  - Email reports

Features:
- Interactive charts (drill-down)
- Data export (CSV, Excel, PDF)
- Scheduled reports
- Custom dashboards
```

---

## 🔐 Encrypted QR Code Implementation (Detailed)

### **Backend Implementation**

```typescript
// src/qr/qr.service.ts
import * as crypto from 'crypto';
import * as QRCode from 'qrcode';

@Injectable()
export class QRService {
  private readonly algorithm = 'aes-256-cbc';
  
  async generateEncryptedQR(productData: any): Promise<{
    qrCode: string;
    qrImage: string;
    encryptionKey: string;
  }> {
    // 1. Generate encryption key (256-bit)
    const key = crypto.randomBytes(32);
    const iv = crypto.randomBytes(16);
    
    // 2. Prepare payload
    const payload = {
      productId: productData.id,
      manufacturerId: productData.manufacturerId,
      timestamp: Date.now(),
      batchId: productData.batchId
    };
    
    // 3. Add signature (HMAC)
    const signature = crypto
      .createHmac('sha256', key)
      .update(JSON.stringify(payload))
      .digest('hex');
    
    payload['signature'] = signature;
    
    // 4. Encrypt payload
    const cipher = crypto.createCipheriv(this.algorithm, key, iv);
    let encrypted = cipher.update(JSON.stringify(payload), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    // 5. Create QR payload
    const qrPayload = {
      v: '1.0', // version
      d: encrypted, // data
      i: iv.toString('hex'), // IV
      t: Date.now() // timestamp
    };
    
    // 6. Encode as base64
    const qrCode = Buffer.from(JSON.stringify(qrPayload)).toString('base64');
    
    // 7. Generate QR image
    const qrImage = await QRCode.toDataURL(qrCode, {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      },
      errorCorrectionLevel: 'H' // High error correction
    });
    
    // 8. Store encryption key (encrypted in database)
    await this.storeEncryptionKey(productData.id, key.toString('hex'));
    
    return {
      qrCode,
      qrImage,
      encryptionKey: key.toString('hex')
    };
  }
  
  async decryptQR(qrCode: string): Promise<any> {
    try {
      // 1. Decode base64
      const payload = JSON.parse(Buffer.from(qrCode, 'base64').toString());
      
      // 2. Verify version
      if (payload.v !== '1.0') {
        throw new Error('Unsupported QR version');
      }
      
      // 3. Verify timestamp (prevent old QR usage)
      const age = Date.now() - payload.t;
      if (age > 365 * 24 * 60 * 60 * 1000) { // 1 year expiry
        throw new Error('QR code expired');
      }
      
      // 4. Extract product ID from encrypted data (partial decryption)
      // For full decryption, we need to fetch key from database
      // But first, we need product ID...
      // Solution: Store mapping of encrypted data hash → product ID
      
      const dataHash = crypto.createHash('sha256')
        .update(payload.d)
        .digest('hex');
      
      const productId = await this.getProductIdByDataHash(dataHash);
      
      // 5. Fetch encryption key
      const key = await this.getEncryptionKey(productId);
      
      // 6. Decrypt
      const decipher = crypto.createDecipheriv(
        this.algorithm,
        Buffer.from(key, 'hex'),
        Buffer.from(payload.i, 'hex')
      );
      
      let decrypted = decipher.update(payload.d, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      const data = JSON.parse(decrypted);
      
      // 7. Verify signature
      const signature = crypto
        .createHmac('sha256', Buffer.from(key, 'hex'))
        .update(JSON.stringify({
          productId: data.productId,
          manufacturerId: data.manufacturerId,
          timestamp: data.timestamp,
          batchId: data.batchId
        }))
        .digest('hex');
      
      if (signature !== data.signature) {
        throw new Error('QR code tampered');
      }
      
      // 8. Track scan
      await this.trackScan(data.productId);
      
      return data;
      
    } catch (error) {
      throw new Error(`QR decryption failed: ${error.message}`);
    }
  }
  
  private async storeEncryptionKey(productId: string, key: string) {
    // Store in PostgreSQL with encryption at rest
    await this.db.query(
      'INSERT INTO qr_encryption_keys (product_id, key_encrypted) VALUES ($1, pgp_sym_encrypt($2, $3))',
      [productId, key, process.env.DB_ENCRYPTION_KEY]
    );
  }
  
  private async getEncryptionKey(productId: string): Promise<string> {
    const result = await this.db.query(
      'SELECT pgp_sym_decrypt(key_encrypted, $1) as key FROM qr_encryption_keys WHERE product_id = $2',
      [process.env.DB_ENCRYPTION_KEY, productId]
    );
    return result.rows[0].key;
  }
  
  private async trackScan(productId: string) {
    await this.db.query(
      'INSERT INTO qr_scans (product_id, scanned_at, ip_address) VALUES ($1, NOW(), $2)',
      [productId, this.request.ip]
    );
  }
}
```

### **Frontend Implementation (Mobile)**

```dart
// lib/services/qr_service.dart
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class QRService {
  Future<ProvenanceData> scanAndDecrypt(String qrCode) async {
    // Send encrypted QR to backend for decryption
    final response = await http.post(
      Uri.parse('${API_BASE_URL}/api/v1/qr/decrypt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qrCode': qrCode}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Fetch provenance data
      final provenanceResponse = await http.get(
        Uri.parse('${API_BASE_URL}/api/v1/provenance/product/${data['productId']}'),
      );
      
      return ProvenanceData.fromJson(jsonDecode(provenanceResponse.body));
    } else {
      throw Exception('QR decryption failed');
    }
  }
}

// lib/screens/qr_scanner_screen.dart
class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Product QR Code')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Scan encrypted QR code on product'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );
      
      try {
        // Decrypt and fetch provenance
        final provenance = await QRService().scanAndDecrypt(scanData.code!);
        
        Navigator.pop(context); // Close loading
        
        // Navigate to provenance screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProvenanceScreen(provenance: provenance),
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR scan failed: $e')),
        );
        
        controller.resumeCamera();
      }
    });
  }
}
```

---

## 🎨 AR Journey Visualization Implementation

### **Option 1: WebXR (Browser-based AR)** - Recommended for MVP

```javascript
// web-portal/src/components/ARViewer.jsx
import { useEffect, useRef } from 'react';
import * as THREE from 'three';

function ARViewer({ provenanceData }) {
  const canvasRef = useRef(null);
  
  useEffect(() => {
    // Initialize Three.js scene
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ canvas: canvasRef.current, alpha: true });
    
    // Add 3D globe
    const geometry = new THREE.SphereGeometry(5, 32, 32);
    const texture = new THREE.TextureLoader().load('/earth-texture.jpg');
    const material = new THREE.MeshBasicMaterial({ map: texture });
    const globe = new THREE.Mesh(geometry, material);
    scene.add(globe);
    
    // Add GPS pins (farmers, labs, processors)
    provenanceData.collectionEvents.forEach(event => {
      const pin = createPin(event.latitude, event.longitude, 'green');
      scene.add(pin);
    });
    
    provenanceData.qualityTests.forEach(test => {
      const pin = createPin(test.labLatitude, test.labLongitude, 'blue');
      scene.add(pin);
    });
    
    // Add journey path (lines connecting pins)
    const path = createJourneyPath(provenanceData);
    scene.add(path);
    
    // Animation loop
    function animate() {
      requestAnimationFrame(animate);
      globe.rotation.y += 0.001;
      renderer.render(scene, camera);
    }
    animate();
    
  }, [provenanceData]);
  
  return (
    <div style={{ position: 'relative', width: '100%', height: '600px' }}>
      <canvas ref={canvasRef} style={{ width: '100%', height: '100%' }} />
      <div style={{ position: 'absolute', top: 20, left: 20 }}>
        <h3>Product Journey</h3>
        <p>Sustainability Score: {provenanceData.sustainabilityScore}/100</p>
        <p>Total Distance: {provenanceData.totalDistance} km</p>
      </div>
    </div>
  );
}

function createPin(lat, lon, color) {
  // Convert lat/lon to 3D coordinates
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lon + 180) * (Math.PI / 180);
  
  const x = -(5 * Math.sin(phi) * Math.cos(theta));
  const y = 5 * Math.cos(phi);
  const z = 5 * Math.sin(phi) * Math.sin(theta);
  
  const geometry = new THREE.SphereGeometry(0.1, 8, 8);
  const material = new THREE.MeshBasicMaterial({ color });
  const pin = new THREE.Mesh(geometry, material);
  pin.position.set(x, y, z);
  
  return pin;
}

function createJourneyPath(provenanceData) {
  const points = [];
  
  // Add farm locations
  provenanceData.collectionEvents.forEach(event => {
    points.push(latLonToVector3(event.latitude, event.longitude));
  });
  
  // Add lab locations
  provenanceData.qualityTests.forEach(test => {
    points.push(latLonToVector3(test.labLatitude, test.labLongitude));
  });
  
  const geometry = new THREE.BufferGeometry().setFromPoints(points);
  const material = new THREE.LineBasicMaterial({ color: 0xff9900 });
  const line = new THREE.Line(geometry, material);
  
  return line;
}
```

### **Option 2: AR.js (Marker-based AR)** - For Mobile App

```html
<!-- Mobile app: WebView with AR.js -->
<!DOCTYPE html>
<html>
<head>
  <script src="https://aframe.io/releases/1.3.0/aframe.min.js"></script>
  <script src="https://raw.githack.com/AR-js-org/AR.js/master/aframe/build/aframe-ar.js"></script>
</head>
<body style="margin: 0; overflow: hidden;">
  <a-scene embedded arjs="trackingMethod: best; debugUIEnabled: false;">
    <!-- AR Camera -->
    <a-marker preset="custom" type="pattern" url="/ar-marker.patt">
      
      <!-- 3D Globe -->
      <a-sphere 
        position="0 0.5 0" 
        radius="0.3" 
        color="#4CAF50"
        animation="property: rotation; to: 0 360 0; loop: true; dur: 10000">
      </a-sphere>
      
      <!-- Farmer Pin -->
      <a-cone 
        position="0.2 0.8 0.2" 
        radius-bottom="0.05" 
        radius-top="0" 
        height="0.15" 
        color="#FF5722">
      </a-cone>
      
      <!-- Lab Pin -->
      <a-cone 
        position="-0.1 0.7 0.1" 
        radius-bottom="0.05" 
        radius-top="0" 
        height="0.15" 
        color="#2196F3">
      </a-cone>
      
      <!-- Journey Path -->
      <a-entity 
        line="start: 0.2 0.8 0.2; end: -0.1 0.7 0.1; color: orange">
      </a-entity>
      
      <!-- Text: Product Name -->
      <a-text 
        value="Ashwagandha Powder" 
        position="0 1.2 0" 
        align="center" 
        color="#000" 
        width="0.8">
      </a-text>
      
      <!-- Text: Sustainability Score -->
      <a-text 
        value="Sustainability: 87/100" 
        position="0 0.2 0" 
        align="center" 
        color="#4CAF50" 
        width="0.6">
      </a-text>
      
    </a-marker>
    
    <a-entity camera></a-entity>
  </a-scene>
</body>
</html>
```

### **Option 3: Unity + Vuforia (Native AR)** - Future Phase

```csharp
// For advanced AR with gamification
// Requires native mobile app development
// Out of scope for MVP, but can be Phase 4
```

### **Backend Support for AR**

```typescript
// src/ar/ar.service.ts
@Injectable()
export class ARService {
  async getARJourney(qrCode: string) {
    // 1. Decrypt QR and get product ID
    const productData = await this.qrService.decryptQR(qrCode);
    
    // 2. Fetch provenance
    const provenance = await this.blockchainService.evaluateTransaction(
      'GetProvenanceByQRCode',
      qrCode
    );
    
    // 3. Enrich with 3D coordinates
    const arData = {
      productId: productData.productId,
      productName: provenance.product.name,
      sustainabilityScore: provenance.sustainabilityScore,
      totalDistance: provenance.totalDistance,
      
      journey: {
        farmers: provenance.collectionEvents.map(event => ({
          name: event.farmerName,
          location: {
            lat: event.latitude,
            lon: event.longitude,
            alt: event.altitude || 0
          },
          x: this.latLonToX(event.latitude, event.longitude),
          y: this.latLonToY(event.latitude, event.longitude),
          z: this.latLonToZ(event.latitude, event.longitude),
          color: '#4CAF50',
          icon: '/3d-models/farmer-pin.glb'
        })),
        
        labs: provenance.qualityTests.map(test => ({
          name: test.labName,
          location: { lat: test.labLatitude, lon: test.labLongitude },
          x: this.latLonToX(test.labLatitude, test.labLongitude),
          y: this.latLonToY(test.labLatitude, test.labLongitude),
          z: this.latLonToZ(test.labLatitude, test.labLongitude),
          color: '#2196F3',
          icon: '/3d-models/lab-pin.glb'
        })),
        
        processors: provenance.processingSteps.map(step => ({
          name: step.processorName,
          location: { lat: step.latitude, lon: step.longitude },
          x: this.latLonToX(step.latitude, step.longitude),
          y: this.latLonToY(step.latitude, step.longitude),
          z: this.latLonToZ(step.latitude, step.longitude),
          color: '#FF9800',
          icon: '/3d-models/processor-pin.glb'
        }))
      },
      
      pathPoints: this.calculateJourneyPath(provenance),
      
      models3D: {
        globe: '/3d-models/earth.glb',
        herb: '/3d-models/ashwagandha-plant.glb',
        pins: {
          farmer: '/3d-models/farmer-pin.glb',
          lab: '/3d-models/lab-pin.glb',
          processor: '/3d-models/processor-pin.glb'
        }
      }
    };
    
    // 4. Track AR scan
    await this.trackARScan(productData.productId);
    
    return arData;
  }
  
  private latLonToX(lat: number, lon: number): number {
    const phi = (90 - lat) * (Math.PI / 180);
    const theta = (lon + 180) * (Math.PI / 180);
    return -(5 * Math.sin(phi) * Math.cos(theta));
  }
  
  private latLonToY(lat: number, lon: number): number {
    const phi = (90 - lat) * (Math.PI / 180);
    return 5 * Math.cos(phi);
  }
  
  private latLonToZ(lat: number, lon: number): number {
    const phi = (90 - lat) * (Math.PI / 180);
    const theta = (lon + 180) * (Math.PI / 180);
    return 5 * Math.sin(phi) * Math.sin(theta);
  }
}

// Endpoints
GET /api/v1/ar/journey/:qrCode
GET /api/v1/ar/3d-models
POST /api/v1/ar/track-scan
GET /api/v1/ar/analytics/:productId
```

---

## 📅 Development Timeline

### **Sprint-wise Breakdown (12 Weeks Total)**

| Sprint | Duration | Backend | Frontend | AR/QR |
|--------|----------|---------|----------|-------|
| **Sprint 1** | Week 1-2 | Setup NestJS, Auth, Blockchain Service | Setup Flutter, Auth screens | - |
| **Sprint 2** | Week 3-4 | Collection Events, Weather, Storage | Farmer dashboard, Collection screen | - |
| **Sprint 3** | Week 5-6 | Batches, Quality Tests | Lab screens, Processor screens | - |
| **Sprint 4** | Week 7-8 | Processing, Products, **Encrypted QR** | Manufacturer screens, **QR scanner** | **Encrypted QR** |
| **Sprint 5** | Week 9-10 | Provenance, Season Windows, Alerts | Consumer provenance screen | **WebXR AR (basic)** |
| **Sprint 6** | Week 11-12 | Analytics, Notifications, Testing | Dashboards, Analytics | **AR.js AR (mobile)** |

---

## 👥 Team Responsibilities

### **Backend Team** (3-4 developers)

#### **Developer 1: Blockchain & Core Services**
- Blockchain service (Fabric SDK integration)
- Transaction submission/evaluation
- Wallet management
- Collection events service
- Season windows service
- Harvest limits service

#### **Developer 2: Business Logic**
- Batch management service
- Quality tests service
- Processing steps service
- Products service
- Provenance service

#### **Developer 3: Advanced Features**
- **Encrypted QR generation/decryption** ⭐
- **AR backend support** ⭐
- Alerts service
- Notifications service
- Analytics service
- Reporting

#### **Developer 4: Infrastructure & DevOps**
- Database schema & migrations
- Redis caching
- S3/IPFS storage integration
- Weather API integration
- SMS/Email gateways
- Docker deployment
- API documentation (Swagger)

---

### **Frontend Team** (4-5 developers)

#### **Developer 1: Mobile (Flutter) - Farmer**
- Farmer authentication
- Farmer dashboard
- Collection event creation
- GPS auto-capture
- Camera integration
- Offline mode
- Push notifications

#### **Developer 2: Mobile (Flutter) - Consumer**
- **QR scanner with decryption** ⭐
- Provenance journey screen
- Interactive map
- Timeline visualization
- **AR journey viewer** ⭐
- Share functionality

#### **Developer 3: Web (React) - Lab & Processor**
- Lab dashboard
- Create quality test screen
- Certificate upload
- Processor dashboard
- Create processing step screen
- Processing chain visualization

#### **Developer 4: Web (React) - Manufacturer & Admin**
- Manufacturer dashboard
- Create product screen
- **Encrypted QR generation** ⭐
- QR management page
- Admin dashboard
- User management
- Season windows management
- Harvest limits management
- Alerts dashboard

#### **Developer 5: Web (React) - Analytics & AR**
- Analytics dashboards
- Charts & reports
- Export functionality
- **WebXR AR viewer** ⭐
- **3D journey visualization** ⭐
- Blockchain explorer

---

### **3D/AR Specialist** (1 developer - Part-time)
- Create 3D models (Blender)
  - Earth globe texture
  - Herb models (Ashwagandha, Tulsi, etc.)
  - Pin icons (farmer, lab, processor)
- Export to glTF format
- AR marker design
- AR scene setup (AR.js / WebXR)
- AR testing & optimization

---

## 🎯 Priority Features for MVP

### **Must Have (MVP Phase 1)** ✅
1. Authentication & User Management
2. Collection Events (Farmer harvest tracking)
3. Batch Management
4. Quality Testing (Lab)
5. Processing Steps (Manufacturing)
6. Products with **Encrypted QR** ⭐
7. Provenance (Consumer QR scan)
8. Basic dashboards (role-based)

### **Should Have (MVP Phase 2)** 🚀
9. Season Windows Management
10. Harvest Limits & Quota
11. Alerts & Notifications
12. Analytics & Reporting
13. **Basic AR Journey (WebXR)** ⭐

### **Nice to Have (Future Phases)** 🌟
14. **Advanced AR (Native mobile)** ⭐
15. Payment Integration
16. Multi-language support
17. Blockchain explorer
18. Predictive analytics
19. Supply chain optimization
20. Gamification (farmer rewards)

---

## 🚀 Getting Started

### **Backend Team - Day 1**
```bash
# 1. Clone repository
git clone https://github.com/kunaldubey10/Trail.git
cd Trail/backend

# 2. Install dependencies
npm install

# 3. Setup environment
cp .env.example .env
# Edit .env with database, blockchain network paths

# 4. Run migrations
npm run migration:run

# 5. Initialize season windows
npm run seed:seasons

# 6. Start server
npm run start:dev

# 7. Access Swagger docs
# http://localhost:3000/api/docs
```

### **Frontend Team - Day 1**
```bash
# Mobile (Flutter)
cd mobile-app
flutter pub get
flutter run

# Web (React)
cd web-portal
npm install
npm start
# http://localhost:3001
```

---

## 📞 Questions & Support

**Backend Lead:** Contact for blockchain integration, API design  
**Frontend Lead:** Contact for UI/UX, component architecture  
**AR/3D Lead:** Contact for AR implementation, 3D models  
**DevOps Lead:** Contact for deployment, infrastructure  

---

**LET'S BUILD HERBALTRACE! 🚀**

All blockchain functions are ready ✅  
Backend architecture designed ✅  
Frontend features planned ✅  
Encrypted QR strategy defined ✅  
AR journey roadmap created ✅  

**Time to code! 💪**
