# Mobile App Requirements - Farmer Collection App

**Project:** HerbalTrace - Blockchain-Based Ayurvedic Herb Traceability  
**Target Users:** Farmers & Wild Collectors ONLY  
**Platform:** Android (Flutter)  
**Connectivity:** Offline-first with auto-sync  
**Languages:** Hindi, English, Regional Languages  
**Date:** December 2, 2025

---

## 📱 App Overview

**Purpose:** Enable farmers and wild collectors to record geo-tagged collection events in rural, low-bandwidth environments. All data is validated by blockchain smart contracts for NMPB compliance.

**Key Differentiators:**
- ✅ Offline-first architecture (works without internet)
- ✅ Auto-capture GPS, timestamp, weather, device info
- ✅ Smart contract validation (geo-fencing, seasonal, conservation)
- ✅ Pre-assigned Login ID system (no self-registration)
- ✅ Multi-language support for rural users
- ✅ Optimized for low-end Android devices

---

## 🔐 Authentication System

### **Pre-Registration Flow (Admin Creates Farmer)**

**Backend Endpoint:**
```
POST /api/v1/auth/register
```

**Request (Admin via Web Portal):**
```json
{
  "username": "FARMER-HP-2025-001",
  "email": "rajesh.kumar@example.com",
  "password": "temp_admin_generated_12345",
  "full_name": "Rajesh Kumar",
  "phone": "+91-9876543210",
  "role": "Farmer",
  "organization": "FarmersCoop Himachal",
  "address": "Village Kharkhoda, District Sonipat, Haryana",
  "license_number": "NMPB/2025/FARM/001"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Farmer registered successfully",
  "data": {
    "id": 15,
    "username": "FARMER-HP-2025-001",
    "role": "Farmer",
    "organization": "FarmersCoop Himachal",
    "blockchain_identity": "0x1a2b3c4d5e6f...",
    "status": "approved"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: RegisterFarmer(farmerJSON)
{
  "loginID": "FARMER-HP-2025-001",
  "fullName": "Rajesh Kumar",
  "phone": "+91-9876543210",
  "licenseNumber": "NMPB/2025/FARM/001",
  "cooperative": "FarmersCoop Himachal",
  "authorizedSpecies": ["Withania somnifera", "Ocimum sanctum"],
  "geoFencedZones": [
    {
      "zoneId": "ZONE-HP-001",
      "name": "Shimla District - Zone A",
      "coordinates": [[28.6139, 77.2090], [28.7041, 77.1025]]
    }
  ],
  "status": "active",
  "registeredAt": "2025-12-02T10:00:00Z"
}
```

---

### **First-Time Login (Farmer Sets Password)**

**Step 1: Verify Login ID**

**Endpoint:**
```
POST /api/v1/auth/verify-login-id
```

**Request:**
```json
{
  "loginId": "FARMER-HP-2025-001"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login ID verified successfully",
  "data": {
    "exists": true,
    "status": "active",
    "needsPasswordSetup": true,
    "farmer": {
      "full_name": "Rajesh Kumar",
      "cooperative": "FarmersCoop Himachal",
      "authorized_species": ["Withania somnifera", "Ocimum sanctum"]
    }
  }
}
```

**Blockchain Query:**
```javascript
// Smart Contract: GetFarmerByLoginID(loginID)
// Returns farmer details from blockchain
```

**Step 2: Complete Registration (Set Password)**

**Endpoint:**
```
POST /api/v1/auth/complete-registration
```

**Request:**
```json
{
  "loginId": "FARMER-HP-2025-001",
  "password": "MySecure@Password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password set successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "user": {
      "id": 15,
      "username": "FARMER-HP-2025-001",
      "full_name": "Rajesh Kumar",
      "role": "Farmer",
      "organization": "FarmersCoop Himachal",
      "blockchain_identity": "0x1a2b3c4d5e6f..."
    }
  }
}
```

---

### **Subsequent Logins**

**Endpoint:**
```
POST /api/v1/auth/login
```

**Request:**
```json
{
  "username": "FARMER-HP-2025-001",
  "password": "MySecure@Password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "user": {
      "id": 15,
      "username": "FARMER-HP-2025-001",
      "email": "rajesh.kumar@example.com",
      "full_name": "Rajesh Kumar",
      "phone": "+91-9876543210",
      "role": "Farmer",
      "organization": "FarmersCoop Himachal",
      "license_number": "NMPB/2025/FARM/001",
      "blockchain_identity": "0x1a2b3c4d5e6f...",
      "authorized_species": [
        {"scientific": "Withania somnifera", "local": "Ashwagandha"},
        {"scientific": "Ocimum sanctum", "local": "Tulsi"}
      ],
      "harvesting_zones": [
        {"id": "ZONE-HP-001", "name": "Shimla District - Zone A"}
      ]
    }
  }
}
```

**Blockchain Verification:**
```javascript
// Smart Contract: ValidateFarmerLogin(loginID)
// Checks if farmer is still active on blockchain
```

---

## 🌱 Collection Event Creation

### **Auto-Captured Fields (No User Input)**

**Device Automatically Captures:**
1. **GPS Coordinates** (latitude, longitude, altitude)
2. **Timestamp** (date & time with timezone)
3. **Device Information** (model, OS version, app version)
4. **Network Status** (online/offline)
5. **GPS Accuracy** (±10m, ±20m, etc.)
6. **Weather Data** (if device has sensors):
   - Temperature (from device sensor or API)
   - Humidity (if available)
   - Atmospheric pressure
7. **Battery Level** (for data quality tracking)
8. **Image Metadata** (if photo taken):
   - EXIF data (camera settings, orientation)
   - Image resolution
   - File size (auto-compressed to <500KB)

**Backend Implementation:**
```typescript
// backend/src/routes/collection.routes.ts
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  const autoFields = {
    device_timestamp: new Date().toISOString(),
    device_info: req.headers['user-agent'],
    ip_address: req.ip,
    app_version: req.headers['x-app-version'],
    network_type: req.headers['x-network-type'], // wifi, 3g, 4g, offline
    server_timestamp: new Date().toISOString()
  };
  
  // Merge with user-provided data
  const collectionData = { ...req.body, ...autoFields };
  
  // Validate & save...
});
```

---

### **User-Provided Fields (Manual Input)**

**Required Fields:**
1. **Species** (dropdown from authorized list)
2. **Quantity** (numeric, kg)
3. **Plant Part** (root, leaf, seed, bark, flower, whole plant)
4. **Maturity Stage** (young, mature, over-mature)
5. **Quality Assessment** (checkboxes):
   - No pest damage
   - Proper moisture
   - Clean (no contamination)
   - Correct maturity

**Optional Fields:**
6. **Quality Notes** (text area, max 500 chars)
7. **Collection Method** (hand harvest, tool-aided, wild collection)
8. **Soil Condition** (sandy, loamy, clay, rocky)
9. **Photo** (1-3 images, auto-compressed)

---

### **Create Collection Endpoint**

**Endpoint:**
```
POST /api/v1/collections
```

**Request Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
X-App-Version: 1.0.0
X-Network-Type: 4g
X-GPS-Accuracy: 10
X-Device-Model: Samsung Galaxy A12
```

**Request Body:**
```json
{
  "species": "Withania somnifera",
  "local_name": "Ashwagandha",
  "quantity_kg": 50.5,
  "plant_part": "root",
  "maturity_stage": "mature",
  "collection_method": "hand_harvest",
  "quality_assessment": {
    "no_pest_damage": true,
    "proper_moisture": true,
    "clean": true,
    "correct_maturity": true
  },
  "quality_notes": "Fresh roots harvested in morning, clean soil, no damage",
  "soil_condition": "loamy",
  "location_lat": 28.6139,
  "location_lng": 77.2090,
  "altitude_m": 245,
  "location_name": "Farm Plot A, Village Kharkhoda",
  "gps_accuracy_m": 10,
  "weather_conditions": {
    "temperature_c": 25,
    "humidity_percent": 60,
    "condition": "sunny"
  },
  "offline_captured": false,
  "device_timestamp": "2025-12-02T08:30:15Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Collection event recorded on blockchain successfully",
  "data": {
    "id": 456,
    "collection_number": "COL-2025-456",
    "blockchain_txid": "tx_abc123def456",
    "species": "Withania somnifera",
    "local_name": "Ashwagandha",
    "quantity_kg": 50.5,
    "status": "verified",
    "geo_fence_validation": {
      "passed": true,
      "zone_id": "ZONE-HP-001",
      "zone_name": "Shimla District - Zone A"
    },
    "seasonal_compliance": {
      "compliant": true,
      "season_window": "October - March",
      "current_month": "December"
    },
    "conservation_check": {
      "passed": true,
      "daily_limit_kg": 100,
      "harvested_today_kg": 50.5,
      "remaining_quota_kg": 49.5
    },
    "sustainability_score": 95,
    "image_urls": [
      "/uploads/collections/COL-2025-456/image_1.jpg"
    ],
    "blockchain_timestamp": "2025-12-02T08:31:00Z",
    "farmer": {
      "username": "FARMER-HP-2025-001",
      "full_name": "Rajesh Kumar",
      "cooperative": "FarmersCoop Himachal"
    }
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: CreateCollection(collectionJSON)
{
  "collectionID": "COL-2025-456",
  "farmerID": "FARMER-HP-2025-001",
  "species": "Withania somnifera",
  "quantityKg": 50.5,
  "plantPart": "root",
  "location": {
    "lat": 28.6139,
    "lng": 77.2090,
    "altitude": 245,
    "zoneID": "ZONE-HP-001"
  },
  "timestamp": "2025-12-02T08:30:15Z",
  "qualityScore": 95,
  "geoFenceValidation": "passed",
  "seasonalCompliance": "compliant",
  "conservationCheck": "passed",
  "status": "verified",
  "createdAt": "2025-12-02T08:31:00Z"
}
```

**Smart Contract Validations:**
1. **Geo-Fencing Check:**
   ```javascript
   ValidateGeoFence(lat, lng, farmerID) → Returns zone_id or error
   ```

2. **Seasonal Compliance:**
   ```javascript
   CheckSeasonalWindow(species, currentDate) → Returns compliant/non-compliant
   ```

3. **Conservation Limits:**
   ```javascript
   CheckHarvestLimit(farmerID, species, quantityKg, date) → Returns quota status
   ```

---

## 📋 View My Collections

### **List Collections Endpoint**

**Endpoint:**
```
GET /api/v1/collections?farmer_id=<current_user_id>&page=1&limit=20
```

**Response:**
```json
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
        "collection_date": "2025-12-02T08:30:15Z",
        "status": "verified",
        "geo_fence_validation": "passed",
        "sustainability_score": 95,
        "batch_id": null,
        "payment_status": "pending",
        "image_thumbnail": "/uploads/collections/COL-2025-456/thumb.jpg",
        "blockchain_txid": "tx_abc123..."
      }
    ],
    "pagination": {
      "total": 15,
      "page": 1,
      "pages": 1,
      "limit": 20
    },
    "summary": {
      "total_collections": 15,
      "total_quantity_kg": 450.5,
      "pending_payment_count": 8,
      "this_month_collections": 5,
      "this_month_quantity_kg": 150.0
    }
  }
}
```

---

### **Collection Details Endpoint**

**Endpoint:**
```
GET /api/v1/collections/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 456,
    "collection_number": "COL-2025-456",
    "species": "Withania somnifera",
    "local_name": "Ashwagandha",
    "plant_part": "root",
    "quantity_kg": 50.5,
    "maturity_stage": "mature",
    "collection_method": "hand_harvest",
    "collection_date": "2025-12-02T08:30:15Z",
    "location": {
      "lat": 28.6139,
      "lng": 77.2090,
      "altitude_m": 245,
      "name": "Farm Plot A, Village Kharkhoda",
      "zone_id": "ZONE-HP-001",
      "zone_name": "Shimla District - Zone A",
      "gps_accuracy_m": 10
    },
    "quality": {
      "assessment": {
        "no_pest_damage": true,
        "proper_moisture": true,
        "clean": true,
        "correct_maturity": true
      },
      "notes": "Fresh roots harvested in morning, clean soil",
      "sustainability_score": 95
    },
    "weather": {
      "temperature_c": 25,
      "humidity_percent": 60,
      "condition": "sunny"
    },
    "status_timeline": [
      {
        "status": "collected",
        "timestamp": "2025-12-02T08:30:15Z",
        "blockchain_txid": "tx_abc123...",
        "actor": "FARMER-HP-2025-001"
      },
      {
        "status": "verified",
        "timestamp": "2025-12-02T08:31:00Z",
        "blockchain_txid": "tx_def456...",
        "actor": "smart_contract",
        "details": {
          "geo_fence": "passed",
          "seasonal": "compliant",
          "conservation": "passed"
        }
      }
    ],
    "batch_info": null,
    "payment_info": {
      "status": "pending",
      "estimated_amount": 2525.00,
      "rate_per_kg": 50.00,
      "payment_due_date": null
    },
    "images": [
      {
        "url": "/uploads/collections/COL-2025-456/image_1.jpg",
        "thumbnail": "/uploads/collections/COL-2025-456/thumb_1.jpg",
        "metadata": {
          "size_kb": 450,
          "resolution": "1920x1080",
          "captured_at": "2025-12-02T08:29:30Z"
        }
      }
    ],
    "blockchain": {
      "txid": "tx_abc123def456",
      "block_number": 12345,
      "timestamp": "2025-12-02T08:31:00Z",
      "immutable": true
    },
    "device_info": {
      "model": "Samsung Galaxy A12",
      "app_version": "1.0.0",
      "network_type": "4g",
      "battery_level": 85
    }
  }
}
```

**Blockchain Query:**
```javascript
// Smart Contract: GetCollection(collectionID)
// Returns full collection details from blockchain
```

---

## 📊 Farmer Dashboard

### **Dashboard Summary Endpoint**

**Endpoint:**
```
GET /api/v1/farmers/dashboard
```

**Response:**
```json
{
  "success": true,
  "data": {
    "farmer_info": {
      "id": 15,
      "username": "FARMER-HP-2025-001",
      "full_name": "Rajesh Kumar",
      "cooperative": "FarmersCoop Himachal",
      "license_number": "NMPB/2025/FARM/001",
      "license_valid_until": "2027-12-31",
      "blockchain_identity": "0x1a2b3c4d5e6f...",
      "authorized_species": [
        {"scientific": "Withania somnifera", "local": "Ashwagandha"},
        {"scientific": "Ocimum sanctum", "local": "Tulsi"}
      ],
      "harvesting_zones": [
        {"id": "ZONE-HP-001", "name": "Shimla District - Zone A"}
      ]
    },
    "this_month_summary": {
      "total_collections": 12,
      "total_quantity_kg": 350.5,
      "pending_review": 2,
      "verified_collections": 10,
      "estimated_earnings": 17525.00
    },
    "recent_collections": [
      {
        "id": 456,
        "collection_number": "COL-2025-456",
        "species": "Ashwagandha",
        "quantity_kg": 50.5,
        "date": "2025-12-02",
        "status": "verified"
      }
    ],
    "notifications": [
      {
        "id": 1,
        "type": "collection_verified",
        "title": "Collection Verified",
        "message": "Your collection COL-2025-456 has been verified on blockchain",
        "timestamp": "2025-12-02T10:00:00Z",
        "read": false
      }
    ],
    "seasonal_alerts": [
      {
        "species": "Withania somnifera",
        "message": "Optimal harvesting season ends in 15 days",
        "priority": "high",
        "expires_on": "2025-12-17"
      }
    ],
    "harvest_quotas": [
      {
        "species": "Withania somnifera",
        "daily_limit_kg": 100,
        "weekly_limit_kg": 500,
        "harvested_today_kg": 50.5,
        "remaining_today_kg": 49.5,
        "harvested_this_week_kg": 200.5,
        "remaining_this_week_kg": 299.5
      }
    ],
    "blockchain_status": {
      "connected": true,
      "last_sync": "2025-12-02T16:45:00Z",
      "pending_transactions": 0
    }
  }
}
```

**Blockchain Queries:**
```javascript
// Smart Contract: GetFarmerStatistics(farmerID)
// Returns aggregated statistics from blockchain
```

---

## 🗺️ Harvesting Zones Map

### **Get Farmer's Authorized Zones**

**Endpoint:**
```
GET /api/v1/farmers/zones
```

**Response:**
```json
{
  "success": true,
  "data": {
    "zones": [
      {
        "id": "ZONE-HP-001",
        "name": "Shimla District - Zone A",
        "coordinates": [
          [28.6139, 77.2090],
          [28.7041, 77.1025],
          [28.6500, 77.1500],
          [28.6139, 77.2090]
        ],
        "center": {
          "lat": 28.6560,
          "lng": 77.1538
        },
        "radius_km": 5,
        "authorized_species": ["Withania somnifera", "Ocimum sanctum"],
        "restrictions": {
          "seasonal_only": true,
          "max_daily_harvest_kg": 100,
          "conservation_status": "sustainable"
        }
      }
    ],
    "current_location": {
      "lat": 28.6139,
      "lng": 77.2090,
      "inside_zone": true,
      "zone_id": "ZONE-HP-001"
    }
  }
}
```

**Blockchain Query:**
```javascript
// Smart Contract: GetFarmerZones(farmerID)
// Returns geo-fenced zones from blockchain
```

---

## 📱 Mobile App UI Modules

### **1. Login Screen**
- Login ID input (pre-assigned by admin)
- Password input (set by farmer on first login)
- Language selector (Hindi/English/Regional)
- "Forgot Password" → Opens web portal link
- "Don't have Login ID?" → Contact admin message

### **2. First-Time Setup Screen**
- Welcome message with farmer name
- "Create Password" screen
- Password strength indicator
- Confirm password field
- Tutorial/walkthrough (optional)

### **3. Dashboard (Home Screen)**
- Header: Farmer name, cooperative, blockchain status
- Quick stats cards:
  - This month collections (number)
  - Total quantity (kg)
  - Pending review (number)
  - Estimated earnings (₹)
- Quick actions:
  - "+ New Collection" (large primary button)
  - "My Collections"
  - "Payment History"
  - "Zones Map"
- Recent collections (last 5)
- Notifications panel
- Seasonal alerts banner
- Bottom navigation: Home | Collections | Zones | Profile

### **4. Create Collection Screen**
- Species selector (dropdown with icons, filtered by authorized)
- Plant part selector (visual icons)
- Quantity input (numeric keypad, kg)
- GPS capture button (large, shows accuracy):
  - Current location on mini map
  - Geo-fence validation indicator (✅/❌)
  - Altitude display
  - "Refresh GPS" button
- Maturity stage (radio buttons)
- Collection method (dropdown)
- Quality assessment (checkboxes)
- Quality notes (text area, optional)
- Weather (auto-filled, editable)
- Soil condition (dropdown)
- Photo capture (camera + gallery, max 3, auto-compress)
- Offline indicator (if no network)
- Submit button (validates, then saves)

### **5. My Collections Screen**
- Summary cards (top):
  - Total collections
  - Total quantity
  - Pending payments
- List view with cards:
  - Collection number
  - Species (icon + name)
  - Quantity (bold)
  - Date
  - Status badge (color-coded)
  - Payment status
  - Thumbnail image
  - Blockchain verified icon (✅)
- Filters: Status, Date range, Species
- Sort: Recent, Quantity, Payment status
- Pull-to-refresh
- Search bar
- Floating "+ New Collection" button

### **6. Collection Details Screen**
- Header: Collection number + status badge
- Location map (interactive, shows collection point)
- Collection info card
- Quality assessment card with sustainability score
- Status timeline (vertical stepper)
- Batch information (if batched)
- Payment information
- Images gallery (swipeable)
- Blockchain verification section
- Action buttons: Edit (if pending), Share, Report Issue

### **7. Harvesting Zones Map Screen**
- Interactive map with:
  - Current location (blue dot)
  - Authorized zones (green overlay)
  - Restricted zones (red overlay)
  - Previous collection points (markers)
- Zone details popup (tap on zone):
  - Zone name
  - Authorized species
  - Daily harvest limit
  - Current day's harvest
- Zoom controls, compass, re-center button
- "Collection Mode" toggle (shows GPS accuracy, geo-fence status)

### **8. Profile Screen**
- Profile photo (editable)
- Account information (username, email, phone)
- Blockchain identity (copyable)
- License & authorization:
  - License number, valid until
  - Authorized species list
  - Harvesting zones (clickable)
- Statistics:
  - Total collections
  - Total quantity
  - Total earnings
  - Member since
  - Sustainability rating (⭐)
- Settings:
  - Language preference
  - Notification settings
  - Offline sync settings
  - App theme
- Help & support links
- About (version, terms, privacy)
- Logout button

### **9. Notifications Screen**
- List of notifications:
  - Collection verified
  - Payment processed
  - Batch created
  - Seasonal alerts
  - System updates
- Filter: All, Unread
- "Mark all as read" button

### **10. Payment History Screen**
- List of payments:
  - Payment date
  - Collection numbers (linked)
  - Amount (₹)
  - Status (pending, processed, paid)
  - Payment method
- Total earnings (all-time, this month, this year)
- Filter by date range
- Export statement (PDF)

---

## 📦 Required Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  dio: ^5.4.0  # Advanced HTTP with interceptors
  http: ^1.1.0  # Backup HTTP client
  
  # State Management
  provider: ^6.1.1
  
  # Local Storage
  shared_preferences: ^2.2.2  # Simple key-value storage
  flutter_secure_storage: ^9.0.0  # Secure token storage
  sqflite: ^2.3.0  # Offline database (SQLite)
  path_provider: ^2.1.1  # File system paths
  
  # Location/GPS
  geolocator: ^10.1.0  # GPS location
  geocoding: ^2.1.1  # Reverse geocoding (address from coordinates)
  google_maps_flutter: ^2.5.0  # Interactive maps
  
  # Camera & Images
  image_picker: ^1.0.5  # Camera + gallery
  image: ^4.1.3  # Image compression
  cached_network_image: ^3.3.0  # Cached images
  
  # Date/Time
  intl: ^0.18.1  # Internationalization, date formatting
  
  # UI Components
  flutter_svg: ^2.0.9  # SVG icons
  shimmer: ^3.0.0  # Loading animations
  pull_to_refresh: ^2.0.0  # Pull-to-refresh
  flutter_spinkit: ^5.2.0  # Loading spinners
  
  # Offline Sync
  connectivity_plus: ^5.0.2  # Network connectivity check
  
  # Permissions
  permission_handler: ^11.1.0  # Runtime permissions
  
  # Utils
  url_launcher: ^6.2.2  # Open URLs (blockchain links)
  share_plus: ^7.2.1  # Share functionality
  device_info_plus: ^9.1.1  # Device information
  package_info_plus: ^5.0.1  # App version info
  
  # Multi-language
  flutter_localizations:
    sdk: flutter
```

---

## 🔄 Offline Mode Implementation

### **Offline Data Capture Flow**

```dart
// lib/services/offline_service.dart
class OfflineService {
  final Database _db;
  final ConnectivityService _connectivity;
  
  // Save collection offline
  Future<void> saveCollectionOffline(CollectionData data) async {
    await _db.insert('offline_collections', {
      'id': uuid.v4(),
      'data': jsonEncode(data.toJson()),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
      'retry_count': 0
    });
  }
  
  // Auto-sync when online
  Future<void> syncPendingCollections() async {
    if (!await _connectivity.isConnected()) return;
    
    final pending = await _db.query('offline_collections', 
      where: 'synced = ?', 
      whereArgs: [0]
    );
    
    for (final item in pending) {
      try {
        final data = jsonDecode(item['data']);
        final response = await apiClient.post('/api/v1/collections', data);
        
        if (response.success) {
          // Mark as synced
          await _db.update('offline_collections',
            {'synced': 1, 'blockchain_txid': response.data.blockchain_txid},
            where: 'id = ?',
            whereArgs: [item['id']]
          );
        }
      } catch (e) {
        // Increment retry count
        await _db.update('offline_collections',
          {'retry_count': (item['retry_count'] as int) + 1},
          where: 'id = ?',
          whereArgs: [item['id']]
        );
      }
    }
  }
}
```

### **Backend Handling for Offline-Captured Data**

```typescript
// backend/src/routes/collection.routes.ts
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  const { offline_captured, device_timestamp, ...collectionData } = req.body;
  
  if (offline_captured) {
    // Use device timestamp for collection_date
    collectionData.collection_date = device_timestamp;
    
    // Add note about offline capture
    collectionData.notes = `${collectionData.notes || ''}\n[Offline capture - synced at ${new Date().toISOString()}]`;
  }
  
  // Validate & save...
  const result = await CollectionService.createCollection(db, collectionData, req.user!);
  
  // Record on blockchain
  const txid = await FabricService.createCollection(result);
  
  res.json({ success: true, data: { ...result, blockchain_txid: txid } });
});
```

---

## 🔒 Security Features

### **1. Token Storage**
- JWT token stored in `flutter_secure_storage` (encrypted)
- Auto-refresh before expiry
- Logout clears all tokens

### **2. Offline Login**
- Cache last successful credentials (encrypted)
- Allow offline login for max 7 days
- Require online verification after 7 days

### **3. Image Compression**
- Auto-compress images to <500KB before upload
- Preserve EXIF metadata (GPS, timestamp)
- Remove sensitive metadata (device serial, etc.)

### **4. API Security**
- All requests include `Authorization: Bearer <token>`
- Request signing (HMAC) for critical operations
- Rate limiting on backend (100 requests/hour per user)

### **5. Blockchain Verification**
- Every collection verified against blockchain identity
- Farmer authorization checked on every API call
- Geo-fence validation uses blockchain zone data

---

## 📊 Performance Optimization

### **1. App Size**
- Target: <50 MB APK
- Use ProGuard for code shrinking
- Optimize images and assets

### **2. Battery Usage**
- GPS: Use `desiredAccuracy: LocationAccuracy.high` only when creating collection
- Background sync: Use WorkManager, not constant polling
- Image compression: On-device before upload

### **3. Data Usage**
- Compress API requests (gzip)
- Cache images with `cached_network_image`
- Batch sync offline collections (not one-by-one)

### **4. Low-End Device Support**
- Minimum: Android 7.0 (API 24)
- RAM: 2 GB minimum
- Storage: 100 MB free space required
- Test on low-end devices (Samsung Galaxy A12, Redmi 9A)

---

## 🌍 Multi-Language Support

### **Supported Languages (Phase 1)**
1. English (default)
2. Hindi (हिंदी)
3. Punjabi (ਪੰਜਾਬੀ)
4. Marathi (मराठी)
5. Gujarati (ગુજરાતી)

### **Translation Files**
```
assets/locales/
  en.json  # English
  hi.json  # Hindi
  pa.json  # Punjabi
  mr.json  # Marathi
  gu.json  # Gujarati
```

### **Example Translation**
```json
// assets/locales/hi.json
{
  "app_name": "हर्बलट्रेस",
  "login": "लॉग इन करें",
  "new_collection": "नया संग्रह",
  "species": "प्रजाति",
  "quantity": "मात्रा",
  "gps_location": "जीपीएस स्थान",
  "submit": "जमा करें",
  "verified": "सत्यापित",
  "pending": "लंबित"
}
```

---

## ✅ Testing Checklist

### **Authentication**
- [ ] Login with valid Login ID + password
- [ ] First-time password setup
- [ ] Offline login (cached credentials)
- [ ] Token refresh on expiry
- [ ] Logout clears all data

### **Collection Creation**
- [ ] GPS auto-capture works (±10m accuracy)
- [ ] Geo-fence validation passes for authorized zones
- [ ] Geo-fence validation fails for restricted zones
- [ ] Seasonal compliance check works
- [ ] Conservation limit check prevents over-harvesting
- [ ] Image compression works (<500KB)
- [ ] Offline capture saves to local database
- [ ] Auto-sync when network available
- [ ] Blockchain transaction ID returned

### **My Collections**
- [ ] List shows all farmer's collections
- [ ] Filters work (status, date, species)
- [ ] Pull-to-refresh updates list
- [ ] Collection details load correctly
- [ ] Status timeline shows all events
- [ ] Images display in gallery

### **Dashboard**
- [ ] Summary stats update in real-time
- [ ] Notifications display correctly
- [ ] Seasonal alerts show expiring seasons
- [ ] Harvest quotas update after new collection

### **Zones Map**
- [ ] Map loads authorized zones
- [ ] Current location shows on map
- [ ] Geo-fence validation indicator works
- [ ] Zone details popup shows on tap

### **Offline Mode**
- [ ] App works without internet
- [ ] Collections saved to local database
- [ ] Sync queue displays pending items
- [ ] Auto-sync on network reconnection
- [ ] No data loss after sync

### **Multi-Language**
- [ ] Language selector works
- [ ] All UI text translates correctly
- [ ] Species names show in selected language
- [ ] Date/time formats localized

### **Performance**
- [ ] App launches in <3 seconds
- [ ] GPS fix in <10 seconds
- [ ] Image upload in <30 seconds (4G)
- [ ] List scrolling smooth (60 fps)
- [ ] Battery drain <5% per hour

---

## 📞 Backend Integration Summary

### **Required Backend Endpoints**

1. **Authentication:**
   - `POST /api/v1/auth/verify-login-id`
   - `POST /api/v1/auth/complete-registration`
   - `POST /api/v1/auth/login`
   - `POST /api/v1/auth/refresh-token`

2. **Collections:**
   - `POST /api/v1/collections` (with auto-capture fields)
   - `GET /api/v1/collections` (with farmer filter)
   - `GET /api/v1/collections/:id`
   - `PUT /api/v1/collections/:id` (edit if pending_review)

3. **Farmer Dashboard:**
   - `GET /api/v1/farmers/dashboard`
   - `GET /api/v1/farmers/zones`
   - `GET /api/v1/farmers/profile`
   - `GET /api/v1/farmers/notifications`

4. **Payments:**
   - `GET /api/v1/farmers/payments`
   - `GET /api/v1/farmers/earnings-summary`

### **Required Blockchain Smart Contracts**

1. **Farmer Registration:**
   - `RegisterFarmer(farmerJSON)` → Stores farmer on blockchain
   - `GetFarmerByLoginID(loginID)` → Retrieves farmer details
   - `ValidateFarmerLogin(loginID)` → Checks if active

2. **Collection Events:**
   - `CreateCollection(collectionJSON)` → Records collection on blockchain
   - `GetCollection(collectionID)` → Retrieves collection details
   - `ValidateGeoFence(lat, lng, farmerID)` → Checks geo-fence
   - `CheckSeasonalWindow(species, date)` → Validates season
   - `CheckHarvestLimit(farmerID, species, quantityKg, date)` → Checks quota

3. **Statistics:**
   - `GetFarmerStatistics(farmerID)` → Returns aggregated stats
   - `GetFarmerZones(farmerID)` → Returns authorized zones

---

**Mobile App Ready for Development! 🚀**  
**Backend Endpoints:** Defined & Ready  
**Blockchain Smart Contracts:** Defined & Ready  
**Auto-Capture Fields:** GPS, Timestamp, Device Info, Weather  
**Manual Input Fields:** Species, Quantity, Quality Assessment  
**Offline Mode:** SQLite + Auto-Sync  
**Multi-Language:** Hindi, English, Regional Languages
