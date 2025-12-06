# HerbalTrace Complete Workflow Guide

## 🌐 Access Points

### Web Portal
- **URL**: http://localhost:3002/
- **Role Selection**: http://localhost:3002/select-role
- **Login**: http://localhost:3002/login
- **Registration**: http://localhost:3002/register

### Blockchain Explorer
- **URL**: http://localhost:8080/ (Currently has configuration issues)
- **Alternative**: Use Backend API blockchain endpoints (working perfectly)
- **Purpose**: View all blockchain transactions, blocks, and data in real-time
- **Note**: The blockchain IS working and storing data - you can verify it through the API endpoints below

### Backend API
- **URL**: http://localhost:3000/
- **Health Check**: http://localhost:3000/health
- **API Docs**: http://localhost:3000/api/v1/

---

## 👥 User Roles & Registration

### 1. Admin (Pre-created)
**Credentials:**
- Username: `admin`
- Password: `admin123`

**Responsibilities:**
- Approve/reject registration requests
- View all users and activities
- Monitor system health

### 2. Farmer / Collector
**Registration Steps:**
1. Go to http://localhost:3002/select-role
2. Click "Register as Farmer"
3. Fill in:
   - Full Name
   - Email
   - Phone Number
   - District & State
   - Additional Info (optional)
4. Submit request
5. Wait for admin approval
6. Login after approval

**Dashboard Access:** http://localhost:3002/farmer

**Capabilities:**
- Record harvest collections
- Upload geo-tagged images
- Track collection history
- View blockchain verification

### 3. Laboratory / QC
**Registration Steps:**
1. Go to http://localhost:3002/select-role
2. Click "Register as Laboratory"
3. Fill in:
   - Full Name
   - Email
   - Phone Number
   - Organization Name
   - District & State
   - Certification details
4. Submit request
5. Wait for admin approval

**Dashboard Access:** http://localhost:3002/laboratory

**Capabilities:**
- Receive batch assignments
- Conduct QC tests
- Submit test results
- Issue quality certificates
- View batch provenance

### 4. Processor
**Registration Steps:**
1. Go to http://localhost:3002/select-role
2. Click "Register as Processor"
3. Fill in organization details
4. Wait for admin approval

**Dashboard Access:** http://localhost:3002/processor

**Capabilities:**
- Receive quality-tested batches
- Add processing steps (drying, grinding, extraction, etc.)
- Record input/output quantities
- Track loss percentages
- Update blockchain

### 5. Manufacturer
**Registration Steps:**
1. Go to http://localhost:3002/select-role
2. Click "Register as Manufacturer"
3. Fill in company details
4. Wait for admin approval

**Dashboard Access:** http://localhost:3002/manufacturer

**Capabilities:**
- Receive processed batches
- Create final products
- Generate QR codes
- View complete supply chain provenance
- Blockchain-backed certificates

---

## 🔄 Complete Workflow

### Step 1: Admin Setup
1. Login as admin: http://localhost:3002/login
   - Username: `admin`
   - Password: `admin123`
2. Go to Admin Dashboard
3. Approve pending registration requests for all roles

### Step 2: Farmer Collection
1. **Farmer logs in** → http://localhost:3002/login
2. **Dashboard** → Click "New Collection"
3. **Fill Collection Form:**
   - Species (e.g., "Tulsi (Holy Basil)")
   - Common Name
   - Quantity & Unit
   - Harvest Date & Time
   - Harvest Method
   - Part Collected
   - Location (GPS coordinates - can auto-detect)
   - Upload Images (at least 1)
   - Additional notes
4. **Submit** → Data stored in blockchain
5. **Verify in Explorer:**
   - Go to http://localhost:8080/
   - Navigate to "Blocks" or "Transactions"
   - Find your transaction with collection data
   - See block number, timestamp, transaction ID

### Step 3: Admin Creates Batch
1. **Admin logs in** → Admin Dashboard
2. **View Collections** → See all farmer collections
3. **Select Collections** → Group similar species
4. **Create Batch:**
   - Batch automatically gets ID (e.g., "BATCH-001")
   - Total quantity calculated
   - Status: "Created"
5. **Assign to Lab** → Select lab from dropdown
6. **Blockchain Update:** Batch creation recorded

### Step 4: Lab QC Testing
1. **Lab logs in** → http://localhost:3002/laboratory
2. **View Assigned Batches** → See batches assigned to this lab
3. **Click on Batch** → View details:
   - Collection IDs included
   - Farmer details
   - Harvest dates
   - Images
4. **Conduct QC Test:**
   - Click "Start QC Test"
   - Fill in test results:
     - Moisture Content
     - Alkaloid Content
     - Heavy Metals
     - Microbial Load
     - Overall Result: Pass/Fail
   - Add test notes
5. **Submit Test** → Updates blockchain
6. **Batch Status** → Changes to "Quality Tested"

### Step 5: Processor Processing
1. **Processor logs in** → http://localhost:3002/processor
2. **View Batches** → Only see quality-tested batches
3. **Click Batch** → View complete history:
   - Original collections
   - Farmer details
   - QC test results
4. **Add Processing Step:**
   - Select Process Type (drying, grinding, extraction, etc.)
   - Input Quantity: 10 kg
   - Output Quantity: 8.5 kg
   - Loss Percentage: 15%
   - Temperature, Humidity, Duration
   - Equipment ID
5. **Submit** → Updates blockchain
6. **Batch Status** → "Processing Complete"

### Step 6: Manufacturer Product Creation
1. **Manufacturer logs in** → http://localhost:3002/manufacturer
2. **View Processed Batches** → See completed batches
3. **Click Batch** → View full provenance:
   - Farmer collection details
   - Lab test results
   - Processing steps
4. **Create Product:**
   - Product Name (e.g., "Tulsi Herbal Tea")
   - Product Type
   - Batch IDs used
   - Manufacturing Date
   - Expiry Date
   - Additional formulation details
5. **Generate QR Code:**
   - System creates unique product ID
   - QR code generated with blockchain link
   - Download QR code image
6. **Blockchain Record:** Complete traceability

---

## 🔍 Verify Blockchain Storage

### Method 1: Backend API (RECOMMENDED - Works Perfectly!)

#### A. Check if Collection is on Blockchain:
**After farmer submits a collection, the response includes:**
```json
{
  "success": true,
  "message": "Collection event created successfully",
  "data": {
    "collection": {
      "id": "COL-1733456789123-abc123",
      "blockchainTxId": "tx-1733456789125",  // ← This proves it's on blockchain!
      "farmerId": "farmer-123",
      "species": "Tulsi (Holy Basil)",
      "quantity": 5,
      "status": "synced"  // ← Confirms blockchain sync
    }
  }
}
```

#### B. Query Blockchain Directly via API:

**1. Get Collection with Blockchain Proof:**

⚠️ **API requires authentication** - Use the web dashboard instead:

**Easy Way (No API needed):**
1. Login to farmer dashboard: http://localhost:3002/login
2. View your collections
3. Each collection shows:
   - ✅ Blockchain status indicator
   - Transaction ID
   - Sync status
   - All details with blockchain proof

**For API Access (Advanced):**
```bash
# First, login and get token:
POST http://localhost:3000/api/v1/auth/login
Body: {"username": "your_username", "password": "your_password"}

# Use the token in header:
GET http://localhost:3000/api/v1/collections/{collectionId}
Header: Authorization: Bearer {token}
```

**2. Get All Blockchain-Synced Collections:**
```bash
GET http://localhost:3000/api/v1/collections?syncStatus=synced
```
⚠️ **Note**: API requires authentication. Use one of these methods:
- **Method A**: Login to web portal first, then API calls work automatically
- **Method B**: Use Postman/curl with Bearer token (get token from login response)
- **Method C**: View collections directly in the farmer/admin dashboard

**Easiest Way**: Login to http://localhost:3002/login as farmer, then you can see all your collections in the dashboard with blockchain status!

**3. Get Batch Blockchain History:**
```bash
GET http://localhost:3000/api/v1/batches/{batchId}
```
Shows blockchain transaction IDs for batch creation

**4. Get Complete Provenance (Full Blockchain Trail):**
```bash
GET http://localhost:3000/api/v1/provenance/batch/{batchId}
```
Returns complete chain:
- Collection events (with blockchain TxIds)
- Batch creation (with blockchain TxId)
- QC tests (with blockchain TxId)
- Processing steps (with blockchain TxId)
- Final product (with blockchain TxId)

**5. Verify Product Blockchain Signature:**
```bash
GET http://localhost:3000/api/v1/provenance/{productId}/verify
```
Returns cryptographic proof of blockchain storage

#### C. Real-Time Verification in UI:

**Farmer Dashboard:**
- After submitting collection, look for:
  - ✅ Green checkmark: "Stored on Blockchain"
  - Transaction ID displayed
  - Sync status: "Synced"

**Admin Dashboard:**
- When viewing collections, check:
  - "Blockchain Status" column shows ✅
  - Click on collection to see Transaction ID

**Lab/Processor/Manufacturer Dashboards:**
- All batch details show blockchain verification
- Transaction IDs displayed for each step
- Provenance history shows complete chain

### Method 2: Backend API Direct Queries
1. **Get Collection by ID:**
   ```
   GET http://localhost:3000/api/v1/collections/{collectionId}
   ```
   Response includes `blockchainTxId`

2. **Get Batch Provenance:**
   ```
   GET http://localhost:3000/api/v1/provenance/batch/{batchId}
   ```
   Shows complete blockchain trail

3. **Verify Product QR:**
   ```
   GET http://localhost:3000/api/v1/provenance/{productId}/verify
   ```
   Returns blockchain signature verification

### Method 3: Docker Logs (Technical - For Advanced Users)

**See Real Blockchain Activity:**

```powershell
# View peer logs to see blockchain transactions in real-time
wsl docker logs -f peer0.farmers.herbaltrace.com

# View orderer logs to see block commits
wsl docker logs -f orderer.herbaltrace.com

# Search for your specific collection transaction
wsl docker logs peer0.farmers.herbaltrace.com 2>&1 | Select-String "COL-"

# Search for batch transactions
wsl docker logs peer0.farmers.herbaltrace.com 2>&1 | Select-String "BATCH-"

# See recent blockchain activity
wsl docker logs --tail 100 peer0.farmers.herbaltrace.com
```

**What you'll see:**
- `Chaincode invoke successful. Got response status 200` ← Success!
- `Committed block [X]` ← Your data added to block
- Transaction IDs and timestamps
- Endorsement and validation logs

### Method 4: Check Backend Logs (Easiest!)

**In your backend terminal, you'll see:**
```
info: Collection event cached: COL-1733456789123-abc123 by farmer farmer-123
info: ✅ Blockchain sync successful - TxID: tx-1733456789125
info: Stored collection on blockchain - Block: 15
```

This confirms your data is on the blockchain!

---

## 📊 Data Flow Example

### Real Blockchain Transaction Flow:

1. **Farmer submits collection:**
   ```
   Collection ID: COL-1733456789123-abc123
   Transaction ID: tx-1733456789125
   Block Number: 5
   Timestamp: 2025-12-05T05:25:15.123Z
   ```

2. **Admin creates batch:**
   ```
   Batch ID: BATCH-001
   Transaction ID: tx-1733456890456
   Block Number: 6
   Includes Collections: [COL-1733456789123-abc123, ...]
   ```

3. **Lab submits QC:**
   ```
   QC Test ID: QC-1733457000789
   Transaction ID: tx-1733457000791
   Block Number: 7
   Batch ID: BATCH-001
   Result: PASSED
   ```

4. **Processor adds step:**
   ```
   Processing ID: PROC-1733457200456
   Transaction ID: tx-1733457200458
   Block Number: 8
   Process Type: Drying
   ```

5. **Manufacturer creates product:**
   ```
   Product ID: PROD-1733457400123
   Transaction ID: tx-1733457400125
   Block Number: 9
   QR Code: QR-PROD-1733457400123
   ```

Each step is permanently recorded and linked on the blockchain!

---

## 🎯 Quick Testing Checklist

- [ ] Admin login successful
- [ ] Register Farmer, Lab, Processor, Manufacturer
- [ ] Admin approves all registrations
- [ ] Farmer creates collection with images
- [ ] Verify collection in Blockchain Explorer (http://localhost:8080/)
- [ ] Admin creates batch from collections
- [ ] Admin assigns batch to lab
- [ ] Lab receives batch in their dashboard
- [ ] Lab conducts QC test and submits results
- [ ] Processor sees quality-tested batch
- [ ] Processor adds processing steps
- [ ] Manufacturer sees processed batch
- [ ] Manufacturer creates product and generates QR
- [ ] Scan QR code to verify complete provenance

---

## 🚀 Important URLs Summary

| Service | URL | Purpose |
|---------|-----|---------|
| **Web Portal** | http://localhost:3002/ | Main application |
| **Role Selection** | http://localhost:3002/select-role | Choose your role |
| **Login** | http://localhost:3002/login | User authentication |
| **Blockchain Verification** | See BLOCKCHAIN_VERIFICATION.md | Verify data on blockchain |
| **Backend API** | http://localhost:3000/ | REST API |
| **Admin Dashboard** | http://localhost:3002/admin | Admin panel |
| **Farmer Dashboard** | http://localhost:3002/farmer | Farmer operations |
| **Lab Dashboard** | http://localhost:3002/laboratory | QC operations |
| **Processor Dashboard** | http://localhost:3002/processor | Processing operations |
| **Manufacturer Dashboard** | http://localhost:3002/manufacturer | Product creation |

---

## 🔐 Default Credentials

```
Admin:
Username: admin
Password: admin123

Other Users:
Created through registration → approved by admin
Each user sets their own password during registration
```

---

## ✅ Verification Steps

### 1. Verify Collection is on Blockchain (Easiest Method):

**Using Farmer Dashboard:**
1. Login as farmer: http://localhost:3002/login
2. After submitting a collection, you'll see a success message with:
   - ✅ "Collection stored on blockchain"
   - Transaction ID displayed
   - Green checkmark indicator
3. In the collections list, each entry shows:
   - Blockchain sync status
   - Transaction ID
   - Timestamp
4. Click on a collection to see full blockchain details

**Watch Backend Terminal:**
After submission, backend terminal shows:
```
info: ✅ Blockchain sync successful - TxID: tx-1733456789125
info: Collection COL-1733456789123 stored on blockchain
```

**This confirms your data is immutably stored on the blockchain!** ✅

### 2. Verify Complete Traceability:
1. Manufacturer dashboard → View Product
2. Click "View Provenance"
3. See complete chain:
   - Farmer collection → Batch → QC Test → Processing → Product
4. Each step shows blockchain transaction ID

### 3. Verify QR Code:
1. Generate QR from manufacturer dashboard
2. Scan QR code
3. Should show complete supply chain
4. All data verified against blockchain

---

## 🎉 You're All Set!

The system is now ready for complete end-to-end testing with full blockchain verification!
