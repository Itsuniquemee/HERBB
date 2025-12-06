# Mobile App Integration Requirements & Testing Guide

**Project:** HerbalTrace - Blockchain Supply Chain Traceability for Ayurvedic Herbs  
**Date:** December 2, 2025  
**Target Users:** Farmers & Wild Collectors ONLY  
**Backend Status:** ✅ Running on http://localhost:3000  
**Blockchain Status:** ✅ Connected (Hyperledger Fabric)  
**QR System Status:** ✅ Signed QR generation & verification ready

---

## 📱 Mobile App Scope

**IMPORTANT:** The mobile app is **exclusively for Farmers and Wild Collectors** to capture geo-tagged collection events in rural, low-bandwidth environments. All other stakeholders (Labs, Processors, Manufacturers, Admins) will use the **Web Portal**.

**Mobile App Users:**
- ✅ Farmers (registered collectors)
- ✅ Wild Collectors (registered harvesters)
- ✅ Farmer Cooperative Members

**Web Portal Users (NOT in mobile app):**
- ❌ Laboratory Technicians
- ❌ Processing Facility Staff
- ❌ Manufacturers
- ❌ Quality Control Officers
- ❌ Administrators
- ❌ Supply Chain Managers
- ❌ End Consumers (public QR verification only)

---

## 📋 Backend API Details

### Base URL
```
Production: http://YOUR_SERVER_IP:3000/api/v1
Development: http://localhost:3000/api/v1
Testing: http://192.168.1.X:3000/api/v1  (Replace with your laptop's local IP)
```

### Authentication
- **Type:** JWT Bearer Token
- **Header:** `Authorization: Bearer <token>`
- **Token expires:** 24 hours
- **Refresh token:** 7 days

---

## 🎯 Required Mobile App Features

### 1. **User Authentication Module** ✅

#### Login Screen (Pre-Registered Users Only)
```dart
POST /api/v1/auth/login
{
  "username": "farmer1",  // Pre-assigned by Admin via Web Portal
  "password": "farmer123"  // Set by farmer on first login
}

Response:
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "user": {
      "id": 1,
      "username": "farmer1",
      "email": "farmer@example.com",
      "role": "Farmer",
      "organization": "FarmersCoop",
      "full_name": "Rajesh Kumar",
      "phone": "+91-9876543210",
      "registration_status": "approved",
      "blockchain_identity": "0x1a2b3c..."
    }
  }
}
```

**AUTHENTICATION FLOW:**
1. **Admin creates Login ID** via Web Portal (stored on blockchain)
2. **Admin shares Login ID** with Farmer (via SMS/WhatsApp/Paper)
3. **Farmer downloads app** from web portal landing page
4. **Farmer enters Login ID** (username) + sets password on first login
5. **System verifies** Login ID exists in blockchain
6. **Farmer gains access** to collection features

**Required UI Elements:**
- **Login ID input field** (username - pre-assigned by admin)
- **Password input field** (with show/hide)
- **First-time setup screen** (if no password set):
  - "Create your password" screen
  - Password strength indicator
  - Confirm password field
- **Login button**
- **"Forgot password?" link** → Redirects to web portal support
- **"Don't have Login ID?" message** → "Contact your cooperative admin or visit [web portal URL]"
- **Regional language selector** (Hindi, English, local languages)
- **"Remember me" checkbox**

**REMOVED FEATURES:**
- ❌ No self-registration in mobile app
- ❌ No role selection (always "Farmer")
- ❌ No in-app account creation
- ❌ No email verification flow

**Security Notes:**
- Login ID is pre-validated on blockchain before app access
- Each Login ID linked to specific cooperative/harvesting zone
- Admin can revoke access via web portal (blockchain update)
- Offline login using cached credentials (last 7 days)

---

### 2. **Geo-Tagged Collection Event Module** ✅ (Core Farmer Feature)

#### Create Collection Event Screen (Optimized for Low-Bandwidth Rural)
```dart
POST /api/v1/collections
Headers: Authorization: Bearer <token>
Body (multipart/form-data):
{
  "species": "Withania somnifera",  // Scientific name + local name
  "local_name": "Ashwagandha",
  "quantity_kg": 50.5,
  "collection_date": "2025-12-02T08:30:00Z",
  "location_lat": 28.6139,
  "location_lng": 77.2090,
  "location_name": "Farm Plot A, Village Kharkhoda, District Sonipat",
  "altitude_m": 245,  // Elevation for NMPB compliance
  "collection_method": "hand_harvest",  // hand_harvest, tool_aided, wild_collection
  "plant_part": "root",  // root, leaf, seed, bark, flower, whole_plant
  "maturity_stage": "mature",  // young, mature, over_mature
  "quality_notes": "Fresh roots, no pest damage, proper moisture",
  "weather_conditions": "Sunny, 25°C, low humidity",
  "soil_condition": "sandy_loam",
  "harvesting_zone_id": "ZONE-HP-001",  // Pre-assigned geo-fenced zone
  "cooperative_id": "COOP-FARM-001",
  "collector_license_number": "NMPB/2025/FARM/001",
  "image": <File>,  // Optional: plant photo
  "offline_captured": false,  // true if captured offline
  "device_timestamp": "2025-12-02T08:30:15Z"
}

Response:
{
  "success": true,
  "message": "Collection event recorded on blockchain successfully",
  "data": {
    "id": 456,
    "collection_number": "COL-2025-456",
    "blockchain_txid": "tx_abc123def456",
    "species": "Withania somnifera",
    "quantity_kg": 50.5,
    "status": "verified",  // verified, pending_review, rejected
    "geo_fence_validation": "passed",  // passed, failed, warning
    "seasonal_compliance": "compliant",
    "sustainability_score": 95,
    "image_url": "/uploads/collections/image_123.jpg",
    "blockchain_timestamp": "2025-12-02T08:31:00Z"
  }
}
```

**SMART CONTRACT VALIDATIONS (Automatic):**
- ✅ **Geo-fencing**: GPS coordinates within approved NMPB harvesting zones
- ✅ **Seasonal restrictions**: Species harvested in permitted season only
- ✅ **Conservation limits**: Daily/monthly harvest quotas not exceeded
- ✅ **Collector authorization**: Valid license linked to blockchain identity
- ✅ **Quality thresholds**: Minimum quality metrics met

**Required UI Elements:**

**Main Collection Form:**
- **Species Selector** (searchable dropdown with icons):
  - Scientific name + Local name (हिंदी)
  - Icon/image for visual identification
  - Filtered by collector's authorized species list
- **Plant Part Selection** (visual icons): Root, Leaf, Seed, Bark, Flower, Whole Plant
- **Quantity Input** (numeric keypad, kg unit)
- **Auto GPS Capture** (large button):
  - Shows current location on map
  - Displays accuracy indicator (±5m, ±10m)
  - "Refresh GPS" option
  - Altitude auto-captured
  - **Geo-fence validation indicator** (green ✅ / red ❌)
- **Collection Date/Time** (auto-filled, editable for offline backlog)
- **Maturity Stage** (radio buttons): Young, Mature, Over-mature
- **Collection Method** (dropdown): Hand harvest, Tool-aided, Wild collection
- **Quality Assessment** (simple checkboxes):
  - ✅ No pest damage
  - ✅ Proper moisture
  - ✅ Clean (no contamination)
  - ✅ Correct maturity
  - Text area for additional notes
- **Weather** (auto-filled from device sensor or manual):
  - Temperature slider (0-45°C)
  - Condition picker (Sunny, Cloudy, Rainy)
  - Humidity slider (optional)
- **Soil Condition** (dropdown): Sandy, Loamy, Clay, Rocky
- **Photo Capture** (optional but recommended):
  - Camera button (compressed auto before upload)
  - Gallery picker
  - Thumbnail preview
  - Multiple photos (max 3)
- **Offline Indicator** (if no network):
  - "Will sync when online" banner
  - Queue count display
- **Submit Button** (large, bottom-fixed):
  - Shows "Validating..." during smart contract checks
  - Success animation with blockchain TX ID
  - Error handling with farmer-friendly messages

**Offline Mode (Critical for Rural Areas):**
- All data captured and stored locally (SQLite)
- Auto-sync when network available
- Queue indicator showing pending uploads
- Conflict resolution (if same collection edited offline/online)

**Location Map View:**
- Interactive map showing current position
- Geo-fenced approved zones (green overlay)
- Restricted zones (red overlay)
- Previous collection points (markers)
- Zoom controls, compass, re-center button

#### View My Collections Screen
```dart
GET /api/v1/collections?page=1&limit=20&farmer_id=<current_user_id>
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "collections": [
      {
        "id": 456,
        "collection_number": "COL-2025-456",
        "species": "Ashwagandha",
        "quantity_kg": 50.5,
        "collection_date": "2025-12-02",
        "status": "collected",
        "batch_id": null,
        "image_url": "/uploads/collections/image_123.jpg"
      }
    ],
    "total": 15,
    "page": 1,
    "pages": 1
  }
}
```

**Required UI Elements:**
- List view of collections
- Each card shows:
  - Collection number
  - Species (with icon)
  - Quantity
  - Date
  - Status badge (color-coded)
  - Thumbnail image
- Pull-to-refresh
- Pagination/infinite scroll
- Search bar (filter by species)
- Status filter chips (All, Collected, Batched, Processed)
- Floating action button (+ New Collection)

---

### 3. **QR Code Scanner Module** ❌ (REMOVED FROM MOBILE APP)

**IMPORTANT:** QR code scanning and certificate verification is **NOT** included in the farmer mobile app. This feature is **only available on the Web Portal** for:
- End consumers (public verification page)
- Lab technicians (verification workflow)
- Supply chain managers (audit purposes)

**Rationale:**
- Farmers don't need to verify certificates (they create collections)
- QR verification requires good internet (not always available in rural areas)
- Keeps mobile app focused and lightweight
- Consumer QR scanning happens via web portal (no app install required)

**Web Portal Features (Not in Mobile App):**
- ✅ Public QR verification page
- ✅ Lab certificate generation
- ✅ Quality test management
- ✅ Batch creation and tracking
- ✅ Supply chain dashboard
- ✅ Admin user management

---

### 4. **Certificate Generation Module** ❌ (REMOVED - WEB PORTAL ONLY)

**IMPORTANT:** Certificate generation, QC testing, and lab operations are **NOT** available in the mobile app. These features are **exclusively on the Web Portal** for:
- Laboratory technicians
- Quality control officers
- Processing facility staff
- Manufacturing partners

**Rationale:**
- Lab operations require desktop environment for data entry
- Certificate generation needs high-speed internet and printer access
- QC testing involves complex workflows not suitable for mobile
- Lab technicians work in controlled office environments (not rural areas)

**All Lab/QC Features on Web Portal:**
- ✅ QC test management
- ✅ Certificate generation with blockchain recording
- ✅ QR code generation for product packaging
- ✅ Lab result entry and validation
- ✅ Batch quality approval workflows
- ✅ Pesticide/moisture/DNA test recording
- ✅ Compliance reporting (NMPB, AYUSH)
- ✅ Print labels with QR codes

---

### 5. **My Collections Tracking Module** ✅ (Farmer-Focused)

#### View My Collections Screen (Farmer's Personal Dashboard)
```dart
GET /api/v1/collections?farmer_id=<current_user_id>&page=1&limit=20
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "collections": [
      {
        "id": 456,
        "collection_number": "COL-2025-456",
        "species": "Withania somnifera",
        "local_name": "Ashwagandha",
        "quantity_kg": 50.5,
        "collection_date": "2025-12-02",
        "status": "verified",  // verified, pending_review, batched, processed
        "geo_fence_validation": "passed",
        "sustainability_score": 95,
        "batch_id": "BATCH-2025-789",  // null if not yet batched
        "batch_status": "quality_testing",  // Only if batched
        "payment_status": "pending",  // pending, processed, paid
        "image_url": "/uploads/collections/image_123.jpg",
        "blockchain_txid": "tx_abc123..."
      }
    ],
    "total": 15,
    "page": 1,
    "summary": {
      "total_collections": 15,
      "total_quantity_kg": 450.5,
      "pending_payment": 8,
      "this_month_collections": 5
    }
  }
}
```

#### Collection Details Screen (Farmer's View)
```dart
GET /api/v1/collections/:id
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "id": 456,
    "collection_number": "COL-2025-456",
    "species": "Withania somnifera",
    "local_name": "Ashwagandha",
    "plant_part": "root",
    "quantity_kg": 50.5,
    "collection_date": "2025-12-02T08:30:00Z",
    "location": {
      "lat": 28.6139,
      "lng": 77.2090,
      "name": "Farm Plot A, Village Kharkhoda",
      "altitude_m": 245,
      "geo_fence_zone": "ZONE-HP-001"
    },
    "quality": {
      "maturity_stage": "mature",
      "quality_notes": "Fresh roots, no pest damage",
      "sustainability_score": 95
    },
    "status_timeline": [
      {
        "status": "collected",
        "timestamp": "2025-12-02T08:31:00Z",
        "blockchain_txid": "tx_abc123..."
      },
      {
        "status": "verified",
        "timestamp": "2025-12-02T09:00:00Z",
        "verified_by": "Cooperative Admin"
      },
      {
        "status": "batched",
        "timestamp": "2025-12-03T10:00:00Z",
        "batch_number": "BATCH-2025-789"
      }
    ],
    "batch_info": {
      "batch_number": "BATCH-2025-789",
      "status": "quality_testing",
      "processor": "Processing Unit A",
      "expected_processing_date": "2025-12-05"
    },
    "payment_info": {
      "status": "pending",
      "estimated_amount": 2525.00,  // ₹50 per kg
      "payment_due_date": "2025-12-15"
    },
    "images": [
      "/uploads/collections/image_123.jpg"
    ]
  }
}
```

**Required UI Elements:**

**My Collections List Screen:**
- **Summary Cards** (top of screen):
  - Total collections this month
  - Total quantity (kg)
  - Pending payments count
  - Current month earnings estimate
- **Collection Cards** (list view):
  - Collection number
  - Species name (scientific + local)
  - Quantity (large, bold)
  - Collection date
  - Status badge (color-coded):
    - 🟢 Verified (passed validation)
    - 🟡 Pending Review
    - 🔵 Batched (in processing)
    - 🟣 Processed (ready for payment)
  - Payment status indicator
  - Thumbnail image
  - Blockchain verified icon (✅)
- **Filters/Sort** (top bar):
  - Status filter (All, Verified, Batched, Paid)
  - Date range picker
  - Species filter
  - Sort: Recent, Quantity, Payment status
- **Pull-to-refresh**
- **Floating Action Button**: "+ New Collection"

**Collection Detail Screen:**
- **Header**: Collection number + status badge
- **Location Map**: Shows collection point on interactive map
- **Collection Info Card**:
  - Species (with icon)
  - Plant part & quantity
  - Date & time
  - Location name
  - Altitude & geo-fence zone
- **Quality Assessment Card**:
  - Maturity stage
  - Quality notes
  - Sustainability score (circular progress)
- **Status Timeline** (vertical stepper):
  - Collected → Verified → Batched → Processed → Paid
  - Each step shows date, time, blockchain TX
  - Current status highlighted
- **Batch Information** (if batched):
  - Batch number (clickable)
  - Current batch status
  - Processor name
  - Expected completion date
- **Payment Information**:
  - Status badge
  - Estimated amount (₹)
  - Payment due date
  - "Track Payment" button
- **Images Gallery**: Swipeable collection photos
- **Blockchain Verification**:
  - Transaction ID
  - "View on Blockchain" button (opens web portal)
  - Timestamp
- **Action Buttons** (if editable):
  - "Edit Collection" (only if status = pending_review)
  - "Report Issue"
  - "Share Details"

**Offline Capability:**
- Cache recent collections (last 50)
- Show "Syncing..." indicator when uploading
- Offline-first architecture

---

### 6. **Dashboard & Profile Module** ✅ (Farmer Home Screen)

#### Dashboard Home Screen
```dart
GET /api/v1/farmers/dashboard
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "farmer_info": {
      "id": 1,
      "full_name": "Rajesh Kumar",
      "cooperative": "FarmersCoop Himachal",
      "license_number": "NMPB/2025/FARM/001",
      "authorized_species": ["Withania somnifera", "Ocimum sanctum", "Curcuma longa"],
      "harvesting_zones": ["ZONE-HP-001", "ZONE-HP-002"]
    },
    "this_month_summary": {
      "total_collections": 12,
      "total_quantity_kg": 350.5,
      "pending_review": 2,
      "verified_collections": 10,
      "estimated_earnings": 17525.00
    },
    "recent_collections": [/* Last 5 collections */],
    "notifications": [
      {
        "id": 1,
        "type": "collection_verified",
        "message": "Your collection COL-2025-456 has been verified",
        "timestamp": "2025-12-02T10:00:00Z"
      },
      {
        "id": 2,
        "type": "payment_processed",
        "message": "Payment for Batch BATCH-2025-789 has been processed",
        "timestamp": "2025-12-01T15:30:00Z"
      }
    ],
    "seasonal_alerts": [
      {
        "species": "Withania somnifera",
        "message": "Optimal harvesting season ends in 15 days",
        "priority": "high"
      }
    ],
    "blockchain_status": {
      "connected": true,
      "last_sync": "2025-12-02T16:45:00Z"
    }
  }
}
```

**Dashboard UI Elements:**

**Header Section:**
- Farmer name & photo (circular avatar)
- Cooperative name
- Blockchain connection indicator (green dot + "Connected")
- Notification bell icon (with badge count)

**Quick Stats Cards** (horizontal scrollable):
1. **This Month Collections**:
   - Large number (12)
   - Icon + "Collections"
   - Trend indicator (↑ 20% vs last month)
2. **Total Quantity**:
   - Large number (350.5 kg)
   - Icon + "Harvested"
3. **Pending Review**:
   - Number (2)
   - Icon + "Awaiting Verification"
4. **Estimated Earnings**:
   - Amount (₹17,525)
   - Icon + "This Month"

**Quick Actions** (large buttons):
- 🌱 **"New Collection"** (primary, large)
- 📋 **"My Collections"**
- 📊 **"Payment History"**
- ℹ️ **"Help & Guidelines"**

**Recent Collections** (list, last 5):
- Mini cards with species, quantity, date, status
- "View All" button

**Notifications Panel** (collapsible):
- Recent alerts (collection verified, payment processed, etc.)
- "Mark all as read"

**Seasonal Alerts** (banner):
- Important messages about harvesting seasons
- NMPB compliance reminders
- Weather warnings

**Bottom Navigation**:
- 🏠 Home (Dashboard)
- 🌱 Collections (List)
- 📍 Zones (Map of authorized areas)
- 👤 Profile

#### Farmer Profile Screen
```dart
GET /api/v1/farmers/profile
Headers: Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "username": "farmer1",
    "full_name": "Rajesh Kumar",
    "email": "rajesh@example.com",
    "phone": "+91-9876543210",
    "cooperative": "FarmersCoop Himachal",
    "license_number": "NMPB/2025/FARM/001",
    "license_valid_until": "2027-12-31",
    "blockchain_identity": "0x1a2b3c4d5e6f...",
    "authorized_species": [
      {"scientific": "Withania somnifera", "local": "Ashwagandha"},
      {"scientific": "Ocimum sanctum", "local": "Tulsi"}
    ],
    "harvesting_zones": [
      {"id": "ZONE-HP-001", "name": "Shimla District - Zone A"},
      {"id": "ZONE-HP-002", "name": "Mandi District - Zone B"}
    ],
    "statistics": {
      "total_collections": 145,
      "total_quantity_kg": 4250.5,
      "total_earnings": 212525.00,
      "member_since": "2024-06-15",
      "sustainability_rating": 4.8
    }
  }
}
```

**Profile UI Elements:**
- **Header**: Profile photo (editable), name, cooperative
- **Account Information**:
  - Username (Login ID)
  - Email & Phone (editable)
  - Blockchain identity (copyable)
  - "Change Password" button
- **License & Authorization**:
  - License number
  - Valid until date
  - Status badge (Active/Expired)
  - Authorized species list with icons
  - Harvesting zones (clickable → shows map)
- **Statistics Card**:
  - Total collections
  - Total quantity harvested
  - Total earnings (all-time)
  - Member since date
  - Sustainability rating (⭐⭐⭐⭐⭐)
- **Settings**:
  - Language preference
  - Notification settings
  - Offline sync settings
  - App theme (light/dark)
- **Help & Support**:
  - "Contact Cooperative Admin"
  - "NMPB Guidelines"
  - "Collection Best Practices"
  - "App Tutorial"
- **About**:
  - App version
  - Terms & Conditions
  - Privacy Policy
- **Logout Button** (bottom, red)

---

## 📱 Required Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  http: ^1.1.0
  dio: ^5.4.0  # For advanced HTTP features
  
  # State Management
  provider: ^6.1.1  # or bloc, riverpod
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0  # For storing tokens
  
  # QR Code
  qr_code_scanner: ^1.0.1  # or mobile_scanner: ^3.5.5
  qr_flutter: ^4.1.0  # For displaying QR codes
  
  # Image Handling
  image_picker: ^1.0.5
  cached_network_image: ^3.3.0
  
  # Location/GPS
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Date/Time
  intl: ^0.18.1
  
  # UI Components
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0  # Loading animations
  pull_to_refresh: ^2.0.0
  
  # URL Launcher
  url_launcher: ^6.2.2  # For blockchain links
```

---

## 🧪 Testing Setup & Guide

### **Step 1: Backend Setup on Development Laptop**

#### Option A: Same Network (Recommended for testing)
```bash
# On Backend Laptop (where backend is running)
# 1. Find your local IP address
ipconfig  # On Windows
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100

# 2. Ensure backend is accessible
# Backend is already running on: http://localhost:3000
# Make it accessible on network: http://192.168.1.100:3000

# 3. Check Windows Firewall
# Add inbound rule for port 3000
New-NetFirewallRule -DisplayName "HerbalTrace Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

#### Option B: ngrok Tunnel (For remote testing)
```bash
# Install ngrok: https://ngrok.com/download

# Run ngrok to expose local backend
ngrok http 3000

# You'll get a public URL like:
# https://abc123.ngrok.io
# Use this as base URL in mobile app
```

### **Step 2: Mobile App Configuration**

Create `lib/config/api_config.dart`:
```dart
class ApiConfig {
  // CHANGE THIS to your backend laptop's IP or ngrok URL
  static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
  
  // Or for ngrok:
  // static const String baseUrl = 'https://abc123.ngrok.io/api/v1';
  
  static const Duration timeout = Duration(seconds: 30);
  
  static Map<String, String> headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

### **Step 3: Test User Accounts**

#### Pre-created Test Accounts (if database has seed data)
```
Admin User:
- Username: admin
- Password: admin123
- Role: Admin

Farmer User:
- Username: farmer1
- Password: farmer123
- Role: Farmer
- Organization: FarmersCoop

Lab User:
- Username: lab1
- Password: lab123
- Role: Lab
- Organization: TestingLabs
```

#### Create Test Accounts via Backend
```bash
# On backend laptop, run:
cd d:\Trial\HerbalTrace\backend

# Create test users via API or database
node -e "
const db = require('better-sqlite3')('data/herbaltrace.db');
const bcrypt = require('bcrypt');

const password = bcrypt.hashSync('test123', 10);

db.prepare(\`
  INSERT INTO users (username, email, password_hash, full_name, role, organization, status, created_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
\`).run('testfarmer', 'testfarmer@example.com', password, 'Test Farmer', 'Farmer', 'FarmersCoop', 'approved');

console.log('Test user created: testfarmer / test123');
"
```

### **Step 4: Testing Workflow**

#### Test Sequence 1: Authentication
1. **Open Mobile App**
2. **Login Screen** → Enter credentials
3. **Verify**: Token stored, user redirected to dashboard
4. **Check**: Network request logs (use Dio interceptors)

#### Test Sequence 2: Collection Creation (Farmer)
1. **Login as Farmer** (testfarmer / test123)
2. **Navigate to Collections**
3. **Tap "+" (New Collection)**
4. **Fill Form**:
   - Species: Select "Ashwagandha"
   - Quantity: 25.5 kg
   - Enable GPS location
   - Take photo (optional)
5. **Submit**
6. **Verify**: 
   - Check backend logs
   - Collection appears in list
   - Image uploaded (check backend/uploads/)

#### Test Sequence 3: QR Code Scanning
1. **Generate Test QR Code** on backend laptop:
   ```bash
   cd d:\Trial\HerbalTrace\backend
   node test-qr-generation.js
   # Displays QR code in terminal or saves to file
   ```

2. **On Mobile App**:
   - Navigate to QR Scanner
   - Scan the generated QR code
   - Verify signature validation works
   - Check certificate details display

#### Test Sequence 4: Certificate Generation (Lab)
1. **Login as Lab User**
2. **Create QC Test** (via backend or API)
3. **Navigate to Tests**
4. **Select Completed Test**
5. **Generate Certificate**
6. **Generate QR Code**
7. **Verify**:
   - QR code displays
   - Blockchain transaction ID shows
   - Can save/share QR

#### Test Sequence 5: Batch Tracking
1. **Login as Any User**
2. **Navigate to Batches**
3. **View Batch Details**
4. **Verify**:
   - Collections listed
   - QC tests shown
   - Certificates displayed
   - Status timeline correct

---

## 🔧 Debugging & Troubleshooting

### Common Issues & Solutions

#### 1. **Connection Refused / Network Error**
```
Error: SocketException: Connection refused
```
**Solution:**
- Check backend laptop IP address
- Verify firewall allows port 3000
- Ping backend IP from mobile: `ping 192.168.1.100`
- Try ngrok tunnel instead

#### 2. **401 Unauthorized**
```
Error: {"success": false, "message": "Unauthorized"}
```
**Solution:**
- Check token is being sent in headers
- Verify token hasn't expired (24h validity)
- Re-login to get fresh token
- Check Authorization header format: `Bearer <token>`

#### 3. **Image Upload Fails**
```
Error: Payload too large
```
**Solution:**
- Compress images before upload
- Use image_picker with maxWidth/maxHeight
- Backend supports up to 50MB (configured)

#### 4. **QR Scanner Not Working**
```
Error: Camera permission denied
```
**Solution:**
- Add permissions to AndroidManifest.xml:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```
- Add to Info.plist (iOS):
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Need camera to scan QR codes</string>
  ```

#### 5. **GPS Location Not Working**
```
Error: Location services disabled
```
**Solution:**
- Enable GPS on phone
- Grant location permissions
- Add permissions:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  ```

---

## 📊 Testing Checklist

### Authentication Module
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (error handling)
- [ ] Token persists after app restart
- [ ] Logout clears token
- [ ] Registration request submission
- [ ] Password visibility toggle

### Collections Module (Farmer)
- [ ] Create collection with all fields
- [ ] GPS location captured correctly
- [ ] Image upload works
- [ ] Collection appears in list
- [ ] Pull-to-refresh works
- [ ] View collection details
- [ ] Search/filter collections

### QR Scanner Module
- [ ] Camera opens correctly
- [ ] QR code scans successfully
- [ ] Valid QR shows success screen
- [ ] Invalid QR shows error
- [ ] Tampered QR detected
- [ ] Expired certificate detected
- [ ] Blockchain link clickable

### Certificate Module (Lab)
- [ ] List QC tests
- [ ] Generate certificate for test
- [ ] Certificate recorded on blockchain
- [ ] Generate QR code for certificate
- [ ] QR code displays clearly
- [ ] Share QR code works
- [ ] Download/save QR code

### Batch Tracking Module
- [ ] List batches
- [ ] View batch details
- [ ] Collections in batch displayed
- [ ] QC tests listed
- [ ] Certificates shown
- [ ] Status timeline correct

### Blockchain Module
- [ ] Blockchain status displays
- [ ] Certificate verification works
- [ ] Transaction ID links work
- [ ] Error handling for blockchain down

---

## 🚀 Deployment Checklist

### Before Release
- [ ] Change API base URL to production server
- [ ] Update QR_SIGNING_SECRET in backend .env
- [ ] Enable HTTPS for API
- [ ] Configure proper CORS on backend
- [ ] Set up proper error tracking (Sentry/Firebase)
- [ ] Add analytics (Firebase Analytics)
- [ ] Test on multiple devices
- [ ] Test on slow network (3G simulation)
- [ ] Test offline scenarios
- [ ] Security audit (tokens, API keys)

---

## 📞 Integration Support

### Backend API Reference
- **Full Documentation**: `d:\Trial\HerbalTrace\BACKEND_API_ENDPOINTS_NEW.md`
- **QR API Docs**: `d:\Trial\HerbalTrace\QR_CODE_API_DOCUMENTATION.md`
- **Blockchain Docs**: `d:\Trial\HerbalTrace\BLOCKCHAIN_INTEGRATION_STATUS.md`

### Backend Contact Points
- **Health Check**: `http://YOUR_IP:3000/health`
- **API Status**: `http://YOUR_IP:3000/`
- **Blockchain Status**: `http://YOUR_IP:3000/api/v1/blockchain/health`

### Questions to Ask Backend Team
1. What's the backend server IP address?
2. Is port 3000 accessible from network?
3. Any test user credentials available?
4. Is there seed data in the database?
5. What's the QR_SIGNING_SECRET value?

---

## ✅ Integration Completion Criteria (Farmer Mobile App)

### **Phase 1: Core Functionality (MVP)**
1. ✅ **Authentication**: Pre-registered Login ID with password setup
2. ✅ **Collection Creation**: Geo-tagged events with GPS, photos, quality notes
3. ✅ **Smart Validation**: Geo-fencing, seasonal checks (automatic via smart contracts)
4. ✅ **Offline Mode**: Capture data offline, auto-sync when online
5. ✅ **My Collections**: List view with status tracking
6. ✅ **Collection Details**: Timeline, blockchain TX, payment status
7. ✅ **Dashboard**: Summary stats, recent activity, notifications
8. ✅ **Profile**: License info, authorized species, harvesting zones
9. ✅ **Multi-Language**: Hindi + English minimum
10. ✅ **Blockchain Indicator**: Connection status in app

### **Phase 2: Enhanced Features**
- Payment history with earnings breakdown
- Interactive map of harvesting zones
- Seasonal alerts & NMPB compliance reminders
- Help & tutorial system
- Species identification guide with images
- Notification system (in-app)

### **Phase 3: Advanced Features (Future)**
- AI-powered plant species recognition
- Weather forecast integration
- SMS fallback for critical alerts
- Route optimization for collection areas
- Gamification & sustainability badges

---

## 🎯 Success Metrics & Testing Flow

### **End-to-End Testing Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│                    WEB PORTAL (Laptop)                       │
│  Admin creates Login ID → Stored on Blockchain              │
│  Admin shares Login ID with Farmer (SMS/WhatsApp)           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  MOBILE APP (Farmer Phone)                   │
│  Step 1: Farmer downloads app from web portal landing page  │
│  Step 2: Farmer enters Login ID → Verifies on blockchain    │
│  Step 3: Farmer sets password (first-time login)            │
│  Step 4: Farmer sees dashboard with authorized species      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│               COLLECTION EVENT (Mobile App)                  │
│  Step 5: Farmer taps "+ New Collection"                     │
│  Step 6: Selects species (Ashwagandha)                      │
│  Step 7: GPS auto-captures location (geo-fence validation)  │
│  Step 8: Farmer enters quantity (50.5 kg)                   │
│  Step 9: Takes photo of harvested plants                    │
│  Step 10: Farmer submits → Smart contract validates         │
│           ✅ Geo-fence passed (within approved zone)        │
│           ✅ Seasonal compliance (correct harvest season)   │
│           ✅ Conservation limit (daily quota not exceeded)  │
│  Step 11: Collection recorded on blockchain                 │
│           Blockchain TX ID: tx_abc123def456                 │
│  Step 12: Farmer sees "Collection Verified" notification    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  WEB PORTAL (Processor)                      │
│  Step 13: Processor creates Batch (combines 5 collections)  │
│  Step 14: Batch BATCH-2025-789 includes COL-2025-456        │
│  Step 15: Farmer sees "Batched" status in mobile app        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                   WEB PORTAL (Lab)                           │
│  Step 16: Lab creates QC Test for Batch BATCH-2025-789      │
│  Step 17: Lab enters test results (Pass)                    │
│  Step 18: Lab generates Certificate CERT-2025-123           │
│           → Recorded on blockchain                          │
│  Step 19: Lab generates QR code (HMAC-signed)               │
│           → QR code printed on product label                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              WEB PORTAL (Consumer Verification)              │
│  Step 20: Consumer scans QR code on product                 │
│           → Opens web portal verification page (no app!)    │
│  Step 21: Web portal verifies QR signature                  │
│           ✅ Signature valid (not tampered)                 │
│           ✅ Certificate exists on blockchain               │
│           ✅ Not expired                                    │
│  Step 22: Consumer sees full provenance:                    │
│           - Farmer name: Rajesh Kumar                       │
│           - Collection location: Village Kharkhoda (map)    │
│           - Harvest date: 2025-12-02                        │
│           - Batch processing: Processing Unit A             │
│           - Lab test results: Pass (moisture, pesticide)    │
│           - Blockchain transactions: All verified ✅        │
│           - Sustainability score: 95/100                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  MOBILE APP (Farmer Phone)                   │
│  Step 23: Farmer sees payment status updated                │
│           "Payment Processed for COL-2025-456"              │
│           Amount: ₹2,525 (₹50/kg × 50.5 kg)                │
└─────────────────────────────────────────────────────────────┘

✅ SUCCESS! Full traceability achieved!
```

### **Key Success Indicators:**
1. ✅ **Farmer can login** using Admin-assigned Login ID
2. ✅ **GPS captures location** within approved geo-fenced zone
3. ✅ **Smart contract validates** seasonal/conservation rules automatically
4. ✅ **Collection recorded on blockchain** with transaction ID
5. ✅ **Offline mode works** (farmer can work without internet)
6. ✅ **Farmer tracks status** (collected → verified → batched → paid)
7. ✅ **Web portal processes** batches, QC tests, certificates
8. ✅ **Consumer verifies QR** on web portal (sees full provenance)
9. ✅ **Payment tracking** works in mobile app
10. ✅ **Multi-language support** (farmer uses Hindi, consumer uses English)

### **Performance Metrics:**
- **Data capture time**: < 2 minutes per collection
- **GPS accuracy**: ±10 meters
- **Image upload**: < 30 seconds (compressed to 500KB)
- **Offline sync**: Within 5 minutes of network availability
- **Blockchain confirmation**: < 5 seconds
- **App size**: < 50 MB (suitable for low-end phones)
- **Battery usage**: < 5% per hour of active use

---

---

## 📋 Additional Requirements for Complete System

### **Web Portal Features (Separate Development)**

The Web Portal must include these features (NOT in mobile app):

#### **1. Landing Page (Public)**
- Hero section explaining HerbalTrace system
- "Download Farmer App" button (links to APK or Play Store)
- "Verify Product" button → QR scanner page
- About NMPB compliance & blockchain traceability
- Farmer testimonials & success stories
- Contact information

#### **2. Admin Dashboard (Login Required)**
- **User Management**:
  - Create Login IDs for farmers (stored on blockchain)
  - Assign harvesting zones & authorized species
  - Approve/reject farmer applications
  - View all farmer profiles & statistics
  - Revoke access if needed
- **Cooperative Management**:
  - Create farmer cooperatives
  - Assign admin roles
  - View cooperative-level statistics
- **System Monitoring**:
  - Blockchain health status
  - Network node status
  - Transaction volume & throughput
  - Error logs & alerts

#### **3. Processor Dashboard (Login Required)**
- View incoming collections (by species, date, farmer)
- Create batches (combine multiple collections)
- Record processing steps:
  - Drying (temperature, duration)
  - Cleaning/sorting
  - Grinding/powdering
  - Storage conditions
- Update batch status (processing → quality_testing → completed)
- View batch history & traceability

#### **4. Lab Dashboard (Login Required)**
- View batches awaiting QC testing
- Create QC tests:
  - Moisture content analysis
  - Pesticide residue testing
  - DNA barcoding authentication
  - Microbial testing
  - Heavy metal analysis
- Enter test results with numerical values
- Upload lab certificate PDFs
- Generate blockchain certificate (CERT-2025-XXX)
- Generate QR codes for product labels
- Print labels with QR codes
- View test history & compliance reports

#### **5. Manufacturer Dashboard (Login Required)**
- View batches with completed QC tests
- Record formulation steps:
  - Ingredient mixing
  - Encapsulation/tablet formation
  - Packaging details
- Update product batch numbers
- Link multiple herb batches to finished product
- Generate finished product QR codes
- View supply chain timeline

#### **6. Consumer Verification Page (Public - No Login)**
- **QR Scanner**:
  - Camera-based QR scanning
  - Or manual certificate number entry
- **Verification Results**:
  - ✅/❌ Certificate valid/invalid/tampered
  - Product name & batch number
  - **Full Provenance Display**:
    - Interactive map showing collection locations
    - Farmer profiles (name, cooperative, photo)
    - Harvest date & conditions
    - Processing facility details
    - Lab test results (moisture, pesticide, DNA)
    - Sustainability score
    - Fair-trade compliance badge
    - Blockchain transaction IDs (clickable)
    - Timeline visualization (farm → lab → processor → shelf)
  - "Download Full Report" (PDF)
  - "Report Issue" button

#### **7. Supply Chain Dashboard (All Stakeholders)**
- Real-time dashboard showing:
  - Active collections (map view)
  - Batches in processing
  - Pending QC tests
  - Certificates generated today
  - Total traceability coverage
- Analytics & Reports:
  - Harvest volume by species/region/month
  - Quality metrics trends
  - Sustainability compliance rates
  - Payment status summary
  - Export compliance documentation

#### **8. Settings & Configuration**
- NMPB guidelines configuration:
  - Geo-fenced harvesting zones (draw on map)
  - Seasonal restrictions (date ranges per species)
  - Conservation limits (daily/monthly quotas)
  - Quality thresholds (moisture %, pesticide ppm)
- Smart contract parameters
- Notification templates (SMS/email)
- Payment rate configuration (₹/kg per species)
- User roles & permissions

---

## 🔐 Authentication Architecture

### **Login ID Creation Flow (Admin → Farmer)**

```
┌─────────────────────────────────────────────────────────────┐
│            WEB PORTAL - Admin Dashboard                      │
│                                                              │
│  1. Admin fills "Create Farmer" form:                       │
│     - Full Name: Rajesh Kumar                               │
│     - Phone: +91-9876543210                                 │
│     - Cooperative: FarmersCoop Himachal                     │
│     - License Number: NMPB/2025/FARM/001                    │
│     - Authorized Species: [Ashwagandha, Tulsi]             │
│     - Harvesting Zones: [ZONE-HP-001, ZONE-HP-002]         │
│                                                              │
│  2. System auto-generates Login ID: FARMER-HP-2025-001      │
│                                                              │
│  3. Blockchain transaction created:                         │
│     Smart Contract: registerFarmer()                        │
│     - loginID: FARMER-HP-2025-001                           │
│     - blockchainIdentity: 0x1a2b3c4d5e6f...                │
│     - authorizedSpecies: [hash of species list]            │
│     - geoFencedZones: [coordinates array]                  │
│     - status: active                                        │
│     TX ID: tx_farmer_registration_abc123                   │
│                                                              │
│  4. Admin receives Login ID: FARMER-HP-2025-001             │
│                                                              │
│  5. Admin shares with farmer:                               │
│     SMS: "Welcome to HerbalTrace! Your Login ID is          │
│           FARMER-HP-2025-001. Download app: [link]"         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              MOBILE APP - First-Time Login                   │
│                                                              │
│  6. Farmer opens app → sees login screen                    │
│                                                              │
│  7. Farmer enters Login ID: FARMER-HP-2025-001              │
│                                                              │
│  8. App calls API:                                          │
│     POST /api/v1/auth/verify-login-id                       │
│     Body: { "loginId": "FARMER-HP-2025-001" }              │
│                                                              │
│  9. Backend verifies on blockchain:                         │
│     Smart Contract: getFarmerByLoginID()                    │
│     - Checks if loginID exists                              │
│     - Checks if status = active                             │
│     - Returns farmer details                                │
│                                                              │
│  10. If valid → App shows "Create Password" screen          │
│      - Password input (min 8 chars)                         │
│      - Confirm password                                     │
│      - Password strength indicator                          │
│                                                              │
│  11. Farmer sets password: "MySecure@123"                   │
│                                                              │
│  12. App calls API:                                         │
│      POST /api/v1/auth/complete-registration                │
│      Body: {                                                │
│        "loginId": "FARMER-HP-2025-001",                     │
│        "password": "MySecure@123"                           │
│      }                                                       │
│                                                              │
│  13. Backend:                                               │
│      - Hashes password (bcrypt)                             │
│      - Stores in database (linked to blockchain identity)   │
│      - Returns JWT token                                    │
│                                                              │
│  14. App stores token securely (flutter_secure_storage)     │
│                                                              │
│  15. Farmer redirected to Dashboard                         │
│      → Can now create collections!                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### **Subsequent Logins:**
```
1. Farmer enters Login ID + Password
2. Backend verifies credentials (database check)
3. Backend verifies blockchain status (still active?)
4. Returns JWT token (24h expiry)
5. App caches credentials for offline login (7 days max)
```

### **Security Features:**
- ✅ Login ID generated on blockchain (tamper-proof)
- ✅ Admin cannot see farmer passwords
- ✅ Passwords hashed with bcrypt (salt rounds: 10)
- ✅ JWT tokens with short expiry (24h)
- ✅ Refresh tokens for seamless re-authentication
- ✅ Blockchain verifies farmer authorization on every collection
- ✅ Admin can revoke access (blockchain update → app login fails)
- ✅ Offline login uses cached credentials (time-limited)

---

**Backend is ready and waiting! 🚀**  
**Network:** http://192.168.1.X:3000 (replace with your IP)  
**Status:** ✅ Running | ✅ Blockchain Connected | ✅ QR System Active

**Mobile App Scope:** Farmers & Wild Collectors Only  
**Web Portal Scope:** Labs, Processors, Manufacturers, Admins, Consumers
