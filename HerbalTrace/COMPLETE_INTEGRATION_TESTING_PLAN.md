# Complete Integration & Testing Plan
## HerbalTrace: Farmer to Consumer End-to-End Testing

**Date:** December 3, 2025  
**Status:** Backend ✅ | Blockchain ✅ | Mobile App 🔄 | Web Portal 🔄

---

## 🎯 Current Status Assessment

### ✅ What's Ready
1. **Backend API** (Node.js + Express) - Running on `http://localhost:3000`
2. **Blockchain Network** (Hyperledger Fabric) - 4 orgs deployed
3. **Chaincode** (Smart Contracts) - All functions implemented
4. **Database** (PostgreSQL + CouchDB) - Configured

### 🔄 What Needs Integration
1. **Flutter Mobile App** - On teammate's laptop (needs Gradle fix on your laptop)
2. **Web Portal** - On GitHub (needs cloning and modifications)
3. **End-to-End Testing** - Complete flow validation

---

## 📱 Step 1: Fix Flutter Mobile App (Your Laptop)

### Problem: Gradle Not Running
```powershell
# Navigate to mobile app
cd d:\Trial\HerbalTrace\mobile-app

# Check current Flutter/Gradle status
flutter doctor -v
flutter clean
flutter pub get

# Fix common Gradle issues
cd android
.\gradlew clean
cd ..

# Try running
flutter run
```

### If Gradle Still Fails:
**Option A: Use Android Studio**
1. Open `mobile-app/android` folder in Android Studio
2. Let it sync Gradle automatically
3. Tools → Flutter → Flutter Clean
4. Run from Android Studio

**Option B: Skip Your Laptop - Use Teammate's**
- Test mobile app on their working setup
- Focus your laptop on backend/web portal

---

## 🌐 Step 2: Clone and Setup Web Portal

### 2.1 Clone from GitHub
```powershell
# Ask your teammate for the GitHub repository URL
cd d:\Trial\HerbalTrace

# Clone web portal repository
git clone https://github.com/YOUR_USERNAME/herbaltrace-web-portal.git web-portal

cd web-portal
npm install
```

### 2.2 Configure Backend Connection
**File: `web-portal/.env` or `web-portal/src/config.js`**
```javascript
REACT_APP_API_URL=http://localhost:3000/api/v1
REACT_APP_BLOCKCHAIN_EXPLORER_URL=http://localhost:5984
```

### 2.3 Start Web Portal
```powershell
cd d:\Trial\HerbalTrace\web-portal
npm start
# Opens on http://localhost:3001 or 3002
```

---

## 🧪 Step 3: Complete End-to-End Testing Flow

### Phase 1: Farmer Operations (Mobile App)

#### Test 1.1: Farmer Registration & Login
**Mobile App:**
1. Open app on teammate's device
2. Register new farmer: "Ramesh Kumar, Himachal Pradesh"
3. Login with credentials
4. Verify dashboard loads with zones

**Backend Verification:**
```powershell
# Check farmer created
curl http://localhost:3000/api/v1/farmers | ConvertFrom-Json | Select-Object -Last 1
```

#### Test 1.2: Record Collection Event
**Mobile App:**
1. Navigate to "New Collection"
2. Enable GPS (should auto-capture location)
3. Select species: "Ashwagandha"
4. Enter quantity: "5.5 kg"
5. Select plant part: "Root"
6. Take 2 photos
7. Mark quality checks
8. Submit

**Expected:**
- GPS coordinates captured: `(31.1048° N, 77.1734° E)`
- Auto-detects geo-fence zone: "Shimla Zone A"
- Shows "Submitting to blockchain..." loader
- Success: "Collection recorded! Txn ID: 0x..."

**Backend Verification:**
```powershell
# Check collection event created on blockchain
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/collection-events" -Method Get | 
  Select-Object -Last 1 -ExpandProperty data | ConvertTo-Json
```

#### Test 1.3: View Collections History
**Mobile App:**
1. Navigate to "My Collections"
2. Verify new collection appears
3. Tap to see details
4. Check blockchain verification badge ✅
5. View transaction hash

---

### Phase 2: Lab Operations (Web Portal - Lab Dashboard)

#### Test 2.1: Lab Technician Login
**Web Portal:**
1. Navigate to `http://localhost:3001/login`
2. Login as Lab Technician
   - Username: `lab_tech_001`
   - Password: `Lab@123`
3. Dashboard should show "Pending Tests" section

#### Test 2.2: Conduct Quality Test
**Web Portal - Lab Dashboard:**
1. Go to "Pending Collections" tab
2. Find Ramesh's Ashwagandha collection
3. Click "Start Test"
4. Fill QC form:
   - Heavy Metals: Pass
   - Pesticides: Pass
   - Moisture: 8.5%
   - Purity: 95%
   - Notes: "Good quality roots"
5. Upload test certificate PDF
6. Submit → Should record on blockchain

**Backend Verification:**
```powershell
# Get QC test details
$collectionId = "COLL_20251203_001"
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/qc-tests?collectionId=$collectionId" | 
  ConvertTo-Json -Depth 5
```

#### Test 2.3: Generate QC Certificate
**Expected:**
- PDF generated with QR code
- QR contains: Collection ID, Lab ID, Test Date, Results
- Certificate stored on IPFS (or local storage)
- Hash recorded on blockchain

---

### Phase 3: Admin Operations (Web Portal - Admin Dashboard)

#### Test 3.1: Admin Login & Batch Creation
**Web Portal:**
1. Login as Admin
   - Username: `admin_farmcoop`
   - Password: `Admin@123`
2. Navigate to "Batch Management"
3. Click "Create New Batch"
4. Select approved collections:
   - Ramesh's 5.5kg Ashwagandha (passed QC)
   - Add 2-3 more collections
5. Total batch: ~20kg
6. Submit → Batch ID generated: `BATCH_20251203_001`

**Backend Verification:**
```powershell
# Get batch details
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/batches/BATCH_20251203_001" | 
  ConvertTo-Json -Depth 5
```

#### Test 3.2: Assign Batch to Processor
**Web Portal - Admin Dashboard:**
1. Find `BATCH_20251203_001`
2. Click "Assign to Processor"
3. Select: "Ayurvedic Processing Ltd"
4. Add notes: "Urgent batch for winter formulation"
5. Confirm → Processor receives notification

---

### Phase 4: Processor Operations (Web Portal - Processor Dashboard)

#### Test 4.1: Processor Receives & Processes Batch
**Web Portal:**
1. Login as Processor
   - Username: `processor_ayur`
   - Password: `Processor@123`
2. Dashboard shows "Incoming Batches" notification
3. View `BATCH_20251203_001` details
4. Click "Start Processing"
5. Record processing steps:
   - **Step 1:** Cleaning/Washing (Dec 3, 10:00 AM)
   - **Step 2:** Drying (Dec 3, 2:00 PM)
   - **Step 3:** Grinding (Dec 4, 9:00 AM)
6. Each step records: timestamp, operator, notes, photos
7. Mark as "Completed" → Output: 18kg processed powder

**Backend Verification:**
```powershell
# Get processing history
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/batches/BATCH_20251203_001/processing" | 
  Select-Object -ExpandProperty steps | Format-Table
```

#### Test 4.2: Quality Check After Processing
**Expected:**
- Processor conducts internal QC
- Records moisture, particle size, contamination check
- Submits to blockchain
- Status changes: `Processing` → `Processed`

---

### Phase 5: Manufacturer Operations (Web Portal - Manufacturer Dashboard)

#### Test 5.1: Create Finished Product
**Web Portal:**
1. Login as Manufacturer
   - Username: `mfg_wellness`
   - Password: `Mfg@123`
2. Navigate to "Product Creation"
3. Click "New Product"
4. Fill formulation:
   - Product Name: "Ashwagandha Capsules 500mg"
   - Batch ID: `BATCH_20251203_001`
   - Input Quantity: 18kg powder
   - Output: 36,000 capsules (500mg each)
   - Batch Number: `MFG_ASH_20251203_01`
   - Expiry: Dec 3, 2027
5. Add other ingredients:
   - Gelatin capsules (excipient)
   - Magnesium stearate (binder)
6. Upload formulation approval certificate
7. Submit → Product created on blockchain

**Backend Verification:**
```powershell
# Get finished product details
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/products/MFG_ASH_20251203_01" | 
  ConvertTo-Json -Depth 5
```

#### Test 5.2: Generate Consumer QR Codes
**Web Portal - Manufacturer Dashboard:**
1. Navigate to `MFG_ASH_20251203_01` product page
2. Click "Generate QR Codes"
3. Options:
   - **Master QR:** Entire batch (36,000 capsules)
   - **Unit QR:** Per bottle (60 capsules each = 600 bottles)
4. Generate 600 unit QR codes
5. Download as ZIP file:
   - 600 PNG images (QR codes)
   - 1 CSV file (QR → Product mapping)
   - 1 PDF (Print-ready labels)

**QR Code Content:**
```json
{
  "type": "HERBALTRACE_PRODUCT",
  "productId": "MFG_ASH_20251203_01",
  "batchId": "BATCH_20251203_001",
  "scanUrl": "https://herbaltrace.app/verify/QR_XXXX",
  "mfgDate": "2025-12-03",
  "expiryDate": "2027-12-03"
}
```

---

### Phase 6: Consumer Verification (Web Portal - Public Page)

#### Test 6.1: Consumer Scans QR Code
**Setup:**
1. Print one QR code (or display on screen)
2. Use phone camera or QR scanner app

**Web Portal - Public Verification Page:**
1. Scanning redirects to: `http://localhost:3001/verify/QR_XXXX`
2. Loads interactive verification page
3. Shows:
   - ✅ **Authentic Product** banner
   - Product details (name, batch, expiry)
   - Manufacturer info
   - "View Complete Journey" button

#### Test 6.2: View Provenance Journey
**Web Portal:**
1. Click "View Complete Journey"
2. Interactive timeline displays:
   
   **Dec 3, 2025, 8:30 AM** - 📍 Collection  
   - Farmer: Ramesh Kumar  
   - Location: Shimla, Himachal Pradesh (Map)  
   - GPS: 31.1048°N, 77.1734°E  
   - Species: Withania somnifera (Ashwagandha)  
   - Quantity: 5.5 kg roots  
   - Photos: [View 2 images]  
   
   **Dec 3, 2025, 2:00 PM** - 🧪 Lab Testing  
   - Lab: Ayurvedic Quality Labs  
   - Test Result: ✅ PASSED  
   - Heavy Metals: Pass | Pesticides: Pass  
   - Certificate: [Download PDF]  
   
   **Dec 3, 2025, 4:00 PM** - 📦 Batch Creation  
   - Admin: FarmersCoop Admin  
   - Batch ID: BATCH_20251203_001  
   - Total Quantity: 20 kg (4 collections)  
   
   **Dec 3-4, 2025** - ⚙️ Processing  
   - Processor: Ayurvedic Processing Ltd  
   - Steps: Cleaning → Drying → Grinding  
   - Output: 18 kg powder  
   
   **Dec 4, 2025, 3:00 PM** - 🏭 Manufacturing  
   - Manufacturer: Wellness Ayurveda Pvt Ltd  
   - Product: Ashwagandha Capsules 500mg  
   - Batch: MFG_ASH_20251203_01  
   - Output: 36,000 capsules  
   
3. Interactive map shows journey: Shimla → Lab → Processor → Manufacturer
4. Each step has blockchain transaction hash (clickable)
5. Download full provenance bundle (PDF)

---

## 🔄 Step 4: Complete Testing Workflow

### 4.1 One Full Cycle Test
**Goal:** Record 1 collection → QC → Batch → Process → Manufacture → Generate QR

**Timeline:** 1-2 hours
1. **0:00-0:15** - Mobile app: Record collection (Ramesh)
2. **0:15-0:30** - Web portal: Lab conducts QC test
3. **0:30-0:45** - Web portal: Admin creates batch
4. **0:45-1:00** - Web portal: Assign to processor
5. **1:00-1:20** - Web portal: Processor records steps
6. **1:20-1:40** - Web portal: Manufacturer creates product
7. **1:40-2:00** - Web portal: Generate QR codes
8. **2:00+** - Test consumer scanning

### 4.2 Validation Checklist
After full cycle, verify:

**Backend API:**
```powershell
# Check all entities created
Invoke-RestMethod "http://localhost:3000/api/v1/collection-events" | Measure-Object
Invoke-RestMethod "http://localhost:3000/api/v1/qc-tests" | Measure-Object
Invoke-RestMethod "http://localhost:3000/api/v1/batches" | Measure-Object
Invoke-RestMethod "http://localhost:3000/api/v1/products" | Measure-Object
```

**Blockchain:**
```powershell
# Check blockchain transactions
docker exec peer0.farmcoop.herbaltrace.com peer chaincode query `
  -C herbalchannel -n herbaltrace `
  -c '{"function":"GetCollectionEvent","Args":["COLL_20251203_001"]}'
```

**Database:**
```powershell
# Connect to PostgreSQL and verify records
docker exec -it postgres_herbaltrace psql -U herbaltrace -d herbaltrace_db -c `
  "SELECT COUNT(*) FROM collection_events;"
```

---

## 🔧 Step 5: Modify Web Portal (If Needed)

### Common Modifications Needed:

#### 5.1 Update API Endpoints
**File: `web-portal/src/api/config.js`**
```javascript
// Old (might be hardcoded)
const API_BASE = 'https://api.herbaltrace.com';

// New (your local backend)
const API_BASE = 'http://localhost:3000/api/v1';
```

#### 5.2 Fix CORS Issues
If you see CORS errors in browser console:

**Backend: `d:\Trial\HerbalTrace\backend\src\index.ts`**
```typescript
// Add before routes
app.use(cors({
  origin: ['http://localhost:3001', 'http://localhost:3002'],
  credentials: true
}));
```

#### 5.3 Update User Credentials
**Web Portal Login Forms:**
- Check if login credentials match your backend database
- Update if needed in backend seed data:
  
```powershell
# Re-seed users with correct credentials
cd d:\Trial\HerbalTrace\backend
npm run seed
```

#### 5.4 Enable Blockchain Explorer Link
**File: `web-portal/src/components/BlockchainBadge.jsx`**
```javascript
// Link to local CouchDB Fauxton
const explorerUrl = `http://localhost:5984/_utils/#database/herbalchannel__herbaltrace/_all_docs`;
```

---

## 🎯 Step 6: Testing Matrix

### Scenario 1: Happy Path (Everything Works)
| Step | Actor | Action | Expected Result |
|------|-------|--------|-----------------|
| 1 | Farmer | Record collection | ✅ Blockchain Txn ID |
| 2 | Lab | Conduct QC test | ✅ Test passed, certificate generated |
| 3 | Admin | Create batch | ✅ Batch ID assigned |
| 4 | Admin | Assign to processor | ✅ Processor notified |
| 5 | Processor | Process batch | ✅ Processing steps recorded |
| 6 | Manufacturer | Create product | ✅ Product ID, formulation saved |
| 7 | Manufacturer | Generate QR | ✅ 600 QR codes downloaded |
| 8 | Consumer | Scan QR | ✅ Journey displayed with map |

### Scenario 2: Quality Failure Path
| Step | Actor | Action | Expected Result |
|------|-------|--------|-----------------|
| 1 | Farmer | Record collection | ✅ Blockchain Txn ID |
| 2 | Lab | Conduct QC test | ❌ Test failed (heavy metals) |
| 3 | System | Auto-reject collection | ✅ Status: "Rejected", farmer notified |
| 4 | Admin | Try to create batch | ❌ Error: "Cannot include rejected collections" |

### Scenario 3: Geo-Fence Violation
| Step | Actor | Action | Expected Result |
|------|-------|--------|-----------------|
| 1 | Farmer | Record collection | ⚠️ Warning: "Outside authorized zone" |
| 2 | System | Flag for admin review | ✅ Status: "Pending Admin Approval" |
| 3 | Admin | Review GPS coordinates | Decision: Approve/Reject |

---

## 📊 Step 7: Performance & Load Testing

### 7.1 Simulate Multiple Farmers
```powershell
# Use Postman or curl to simulate 10 concurrent farmers
for ($i=1; $i -le 10; $i++) {
    $body = @{
        farmerId = "FARMER_HP_$(Get-Random -Minimum 1000 -Maximum 9999)"
        species = "Ashwagandha"
        quantity = (Get-Random -Minimum 1 -Maximum 20)
        latitude = 31.1048
        longitude = 77.1734
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "http://localhost:3000/api/v1/collection-events" `
      -Method POST -Body $body -ContentType "application/json"
}
```

### 7.2 Blockchain Performance
```powershell
# Measure transaction throughput
$startTime = Get-Date
# Submit 100 transactions
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
Write-Host "Throughput: $($100 / $duration) TPS"
```

---

## 🚀 Step 8: Deployment Preparation (Future)

### 8.1 Mobile App Deployment
**Android:**
```bash
cd mobile-app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**iOS:**
```bash
flutter build ios --release
# Requires Mac + Xcode + Apple Developer Account
```

### 8.2 Web Portal Deployment
```bash
cd web-portal
npm run build
# Deploy to Vercel/Netlify/AWS S3
```

### 8.3 Backend Deployment
```bash
# Dockerize backend
cd backend
docker build -t herbaltrace-backend:latest .
docker push your-registry/herbaltrace-backend:latest

# Deploy to AWS ECS / Google Cloud Run / Azure Container Apps
```

---

## 🐛 Common Issues & Fixes

### Issue 1: Flutter Gradle Build Failed
**Error:** `Gradle sync failed` or `Could not resolve dependencies`

**Fix:**
```bash
cd mobile-app/android
# Update Gradle wrapper
./gradlew wrapper --gradle-version=8.0
# Clear cache
./gradlew clean
./gradlew build --refresh-dependencies
```

### Issue 2: Backend Cannot Connect to Blockchain
**Error:** `Failed to connect to peer`

**Fix:**
```powershell
# Restart Fabric network
cd d:\Trial\HerbalTrace\network
docker-compose down
docker-compose up -d
# Wait 30 seconds
cd ..\backend
npm start
```

### Issue 3: QR Code Generation Fails
**Error:** `QR code library not found`

**Fix:**
```bash
# Install QR code library
cd backend
npm install qrcode
# Or in web portal
cd web-portal
npm install qrcode.react
```

### Issue 4: CORS Errors in Web Portal
**Error:** `Access-Control-Allow-Origin header missing`

**Fix:**
```javascript
// backend/src/index.ts
import cors from 'cors';
app.use(cors({ origin: '*' })); // For development only
```

---

## 📝 Final Checklist

### Before Testing:
- [ ] Backend running: `http://localhost:3000`
- [ ] Blockchain network up: `docker ps` shows 4+ containers
- [ ] Database seeded: Users, zones, species exist
- [ ] Mobile app running on teammate's device
- [ ] Web portal cloned and `npm install` completed
- [ ] Web portal running: `http://localhost:3001`

### During Testing:
- [ ] Farmer records 1 collection successfully
- [ ] Lab conducts 1 QC test successfully
- [ ] Admin creates 1 batch successfully
- [ ] Processor records processing steps
- [ ] Manufacturer creates 1 product
- [ ] QR codes generated (at least 1)
- [ ] Consumer scan shows journey

### After Testing:
- [ ] All blockchain transactions visible in CouchDB
- [ ] All API endpoints tested and working
- [ ] Error handling tested (failed QC, geo-fence violation)
- [ ] Performance acceptable (< 3 seconds per transaction)
- [ ] Documentation updated with test results

---

## 🎉 Success Criteria

Your HerbalTrace system is **fully functional** when:

1. ✅ **Farmer** can record collection via mobile app → Appears in blockchain
2. ✅ **Lab** can conduct QC test via web portal → Certificate generated
3. ✅ **Admin** can create batch and assign → Processor receives notification
4. ✅ **Processor** can record processing steps → History tracked
5. ✅ **Manufacturer** can create product → QR codes generated
6. ✅ **Consumer** can scan QR → Complete journey displayed with map
7. ✅ **All blockchain transactions** are immutable and verifiable
8. ✅ **System handles 10+ concurrent users** without lag

---

## 📞 Next Steps

1. **Share this document** with your teammate
2. **Clone web portal** from GitHub to your laptop
3. **Run one full test cycle** following Phase 1-6
4. **Document any issues** encountered
5. **Share test results** for final review
6. **Plan production deployment** (AWS, Azure, or Google Cloud)

**Let me know when you're ready to start testing, and I can guide you through each step in real-time!** 🚀
