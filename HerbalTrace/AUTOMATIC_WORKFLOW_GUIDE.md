# HerbalTrace Automatic Workflow Guide

## 🔄 Automatic Batch Flow System

The HerbalTrace platform now features an **automatic batch flow system** where data seamlessly moves through each stage of the supply chain without manual batch ID entry.

---

## 📋 Complete Workflow

### **Stage 1: Farmer Creates Collection** 🌾
**Dashboard:** Farmer Dashboard (http://localhost:3001/farmer)

1. Farmer fills out the "New Collection" form:
   - Herb species
   - Quantity (kg)
   - Location & GPS coordinates
   - Moisture content
   - Photos and notes

2. Clicks **"Record on Blockchain"**

3. System:
   - Saves collection locally
   - Posts to blockchain via API
   - Generates unique Collection ID (e.g., `COL-1732498765432`)
   - Returns blockchain TX hash

4. **Result:** Collection is now visible to Laboratory dashboard automatically

---

### **Stage 2: Laboratory Tests Collection** 🔬
**Dashboard:** Laboratory Dashboard (http://localhost:3001/laboratory)

**Automatic Loading:**
- Navigate to **"Pending Tests"** or **"Overview"** section
- All farmer collections automatically appear as **"Farmer Collections (Auto-Loaded)"**
- No manual batch ID entry needed!

**Testing Process:**
1. Lab sees the collection card with:
   - Species name
   - Quantity
   - Farmer ID
   - Collection ID (automatically displayed)

2. Clicks **"Test Now"** button on any collection

3. System **auto-fills** the Collection ID in the test form

4. Lab technician enters:
   - Purity %
   - Moisture %
   - Contamination levels
   - Pesticides, heavy metals, microbial tests
   - Overall grade (A/B/C/F)
   - Notes

5. Clicks **"Record Test on Blockchain"**

6. **Result:** Quality test recorded with TX hash, batch now visible to Processor

---

### **Stage 3: Processor Processes Batch** 🏭
**Dashboard:** Processor Dashboard (http://localhost:3001/processor)

**Automatic Loading:**
- Navigate to **"Ready Batches"** section
- All quality-tested batches automatically appear as **"Lab-Tested Batches (Auto)"**
- Only shows batches that passed quality tests (Grade A, B, or C)

**Processing Steps:**
1. Processor sees batch card with:
   - Collection ID
   - Test ID
   - Quality grade
   - Test results

2. Clicks **"Process Now"** button

3. System **auto-fills** the Batch ID in the processing form

4. Processor enters:
   - Process type (Drying/Grinding/Extraction/Distillation/Packaging)
   - Temperature (°C)
   - Duration (hours)
   - Humidity %
   - Equipment used
   - Processing notes

5. Clicks **"Record Processing"**

6. **Result:** Processing step recorded with TX hash, batch now visible to Manufacturer

---

### **Stage 4: Manufacturer Creates Product & QR** 📦
**Dashboard:** Manufacturer Dashboard (http://localhost:3001/manufacturer)

**Automatic Loading:**
- Navigate to **"Processed Batches"** section
- All processed batches automatically appear from processing unit

**Product Creation:**
1. Manufacturer sees processed batch card with:
   - Processing ID
   - Batch ID
   - Process type
   - Temperature, duration
   - Processor ID
   - Blockchain TX hash

2. Clicks **"Select & Create Product"** button

3. System:
   - **Auto-fills** the Batch ID
   - Displays selected batch information
   - Opens product creation form

4. Manufacturer enters:
   - Product name (e.g., "Organic Ashwagandha Powder")
   - Quantity
   - Certifications (Organic, GMP, ISO)
   - Manufacturing date
   - Expiry date
   - Product notes

5. Clicks **"Create Product & Generate QR"**

6. System:
   - Creates product on blockchain
   - **Automatically generates QR code**
   - QR contains: Product ID, verification URL, batch traceability, TX hash
   - QR code displayed immediately

7. Manufacturer can:
   - Download QR code as PNG
   - View full product provenance
   - Print QR for product packaging

8. **Result:** Product created with QR code, visible to consumers and Admin

---

### **Stage 5: Admin Monitors Everything** 👁️
**Dashboard:** Admin Dashboard (http://localhost:3001/admin)

**Real-Time Batch Tracking:**
- Navigate to **"Batch Tracking"** section
- View all batches moving through the supply chain

**What Admin Sees:**
- **Visual Supply Chain Map:**
  - 📦 Collection → 🔬 Quality Test → 🏭 Processing → 📱 Product
  
- **For Each Batch:**
  - Current stage (Collection/Quality Test/Processing/Product)
  - Species name
  - Batch ID
  - All stakeholder IDs (Farmer, Lab, Processor, Manufacturer)
  - Quantity, grade, process type, product name
  
- **Blockchain TX Hashes:**
  - Complete list of all transaction hashes for each stage
  - Verifiable on blockchain
  - Immutable audit trail

**Network Monitoring:**
- Navigate to **"Network Status"**
- View blockchain health:
  - Peer nodes (8)
  - Orderers (3)
  - Block height
  - Transactions per second
  - All systems operational

---

## 🎯 Key Features

### ✅ **No Manual Batch IDs**
- System automatically passes batch IDs between stages
- "Select & Process" buttons auto-fill forms
- Eliminates data entry errors

### ✅ **Automatic QR Generation**
- QR code created instantly when product is manufactured
- Contains full blockchain provenance
- Downloadable for printing on packaging

### ✅ **Real-Time Visibility**
- Admin sees all batches moving through stages
- Complete blockchain TX hash audit trail
- Live supply chain tracking

### ✅ **Blockchain Verified**
- Every stage records a transaction on Hyperledger Fabric
- TX hashes visible at each step
- Immutable and tamper-proof

### ✅ **Consumer Verification**
- Consumers scan QR code with mobile app
- See complete product journey:
  - Farm origin with GPS
  - Quality test results
  - Processing details
  - Manufacturing info
  - All blockchain TX hashes

---

## 🚀 Testing the Workflow

### Step-by-Step Test:

1. **Start Farmer Dashboard:**
   ```
   http://localhost:3001/farmer
   ```
   - Create a new collection (Ashwagandha, 50kg)
   - Note the Collection ID from the alert

2. **Open Laboratory Dashboard:**
   ```
   http://localhost:3001/laboratory
   ```
   - Go to "Pending Tests" section
   - See the Ashwagandha collection automatically loaded
   - Click "Test Now"
   - Collection ID is auto-filled
   - Enter test results (Purity: 95%, Grade: A)
   - Record on blockchain

3. **Open Processor Dashboard:**
   ```
   http://localhost:3001/processor
   ```
   - Go to "Ready Batches" section
   - See the tested Ashwagandha batch automatically loaded
   - Click "Process Now"
   - Batch ID is auto-filled
   - Enter processing (Type: Drying, Temp: 60°C, Duration: 24h)
   - Record on blockchain

4. **Open Manufacturer Dashboard:**
   ```
   http://localhost:3001/manufacturer
   ```
   - Go to "Processed Batches" section
   - See the processed batch automatically loaded
   - Click "Select & Create Product"
   - Batch ID is auto-filled
   - Enter product details (Name: "Organic Ashwagandha Powder", Qty: 1000)
   - Click "Create Product & Generate QR"
   - QR code appears instantly!
   - Download QR code

5. **Open Admin Dashboard:**
   ```
   http://localhost:3001/admin
   ```
   - Go to "Batch Tracking" section
   - See the complete journey of your Ashwagandha batch
   - View all 4 blockchain TX hashes:
     1. Collection TX hash
     2. Quality test TX hash
     3. Processing TX hash
     4. Product creation TX hash

6. **Scan QR with Mobile App:**
   - Open HerbalTrace mobile app
   - Scan the QR code
   - See complete provenance with all TX hashes

---

## 📊 Dashboard URLs

| Stakeholder | URL | Purpose |
|------------|-----|---------|
| Farmer | http://localhost:3001/farmer | Create collections |
| Laboratory | http://localhost:3001/laboratory | Test collections |
| Processor | http://localhost:3001/processor | Process tested batches |
| Manufacturer | http://localhost:3001/manufacturer | Create products & QR |
| Admin | http://localhost:3001/admin | Monitor everything |

---

## 🔐 Blockchain Integration

- **Network:** Hyperledger Fabric 2.5
- **Organizations:** 4 (Farmers, Labs, Processors, Manufacturers)
- **Peers:** 8 (2 per organization)
- **Orderers:** 3 (Raft consensus)
- **Channel:** herbaltrace-channel
- **Smart Contracts:** Collection, Quality, Processing, Product, Provenance

---

## 📱 Mobile App Integration

The mobile app works alongside the web portal:
- Farmers use mobile app to create collections with GPS & photos
- Consumers use mobile app to scan QR codes
- Web portal handles Lab, Processor, Manufacturer, Admin workflows
- All data syncs via blockchain API

---

## ✨ Benefits

1. **For Farmers:**
   - Easy collection recording
   - Transparent pricing based on quality
   - Direct blockchain proof of origin

2. **For Laboratories:**
   - Streamlined testing workflow
   - Auto-loaded batches
   - Quality data on blockchain

3. **For Processors:**
   - Clear view of tested batches
   - One-click processing initiation
   - Complete traceability

4. **For Manufacturers:**
   - Auto-populated batch data
   - Instant QR generation
   - Full supply chain visibility

5. **For Consumers:**
   - Scan QR to verify authenticity
   - See complete product journey
   - Blockchain-verified trust

6. **For Admins:**
   - Real-time supply chain monitoring
   - Complete batch tracking
   - All TX hashes visible
   - Network health dashboard

---

## 🎉 You're Ready!

The system is now fully configured for automatic batch flow. Each stakeholder only needs to:
1. Navigate to their dashboard
2. See auto-loaded batches from previous stage
3. Click "Select" or "Process" or "Test Now"
4. Fill in their stage-specific data
5. Record on blockchain

**No manual batch ID copying needed!** 🚀
