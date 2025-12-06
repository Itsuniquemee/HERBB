# Web Portal Requirements - HerbalTrace Platform

**Project:** HerbalTrace - Blockchain-Based Ayurvedic Herb Traceability  
**Target Users:** Admin, Lab, Processor, Manufacturer, Consumer (Public)  
**Platform:** Web Application (React/Next.js)  
**Date:** December 2, 2025

---

## 🌐 Portal Overview

**Purpose:** Comprehensive web platform for all non-farmer stakeholders to manage the complete supply chain, from batch creation to consumer verification.

**User Roles:**
1. **Admin** - System management, farmer registration, compliance monitoring
2. **Lab Technician** - QC testing, certificate generation, QR code creation
3. **Processor** - Batch creation, processing steps, status updates
4. **Manufacturer** - Formulation, finished products, packaging
5. **Consumer (Public)** - QR code verification, provenance viewing (no login)

---

## 📋 Module 1: Public Landing Page

### **Features**
- Hero section explaining HerbalTrace system
- How it works (illustrated steps)
- NMPB compliance & blockchain benefits
- Download mobile app section:
  - QR code for APK download
  - Play Store link (when available)
  - "For Farmers & Collectors" message
- Consumer verification section:
  - "Verify Your Product" button → QR scanner
  - "Scan QR code to see full provenance"
- Farmer testimonials & success stories
- Supply chain partners logos
- Contact information & support

### **No Backend Required** (Static Pages)

---

## 📋 Module 2: Admin Dashboard

### **2.1 User Management**

#### **Create Farmer Login ID**

**Endpoint:**
```
POST /api/v1/auth/register
```

**Request:**
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
  "license_number": "NMPB/2025/FARM/001",
  "authorized_species": ["Withania somnifera", "Ocimum sanctum"],
  "harvesting_zones": ["ZONE-HP-001"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Farmer registered successfully on blockchain",
  "data": {
    "id": 15,
    "username": "FARMER-HP-2025-001",
    "blockchain_identity": "0x1a2b3c4d5e6f...",
    "blockchain_txid": "tx_farmer_reg_abc123",
    "status": "approved",
    "sms_sent": true
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
  "geoFencedZones": ["ZONE-HP-001"],
  "status": "active",
  "registeredAt": "2025-12-02T10:00:00Z",
  "registeredBy": "admin1"
}
```

---

#### **List All Users**

**Endpoint:**
```
GET /api/v1/users?role=Farmer&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 15,
        "username": "FARMER-HP-2025-001",
        "full_name": "Rajesh Kumar",
        "role": "Farmer",
        "organization": "FarmersCoop Himachal",
        "status": "approved",
        "license_number": "NMPB/2025/FARM/001",
        "blockchain_identity": "0x1a2b3c4d5e6f...",
        "created_at": "2025-12-02T10:00:00Z",
        "last_login": "2025-12-02T14:30:00Z",
        "total_collections": 15
      }
    ],
    "pagination": {
      "total": 50,
      "page": 1,
      "pages": 3,
      "limit": 20
    }
  }
}
```

---

#### **Revoke User Access**

**Endpoint:**
```
PUT /api/v1/users/:userId/revoke
```

**Request:**
```json
{
  "reason": "License expired",
  "revoked_by": "admin1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User access revoked on blockchain",
  "data": {
    "user_id": 15,
    "status": "revoked",
    "blockchain_txid": "tx_revoke_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: RevokeFarmerAccess(loginID, reason)
```

---

### **2.2 Geo-Fenced Zone Management**

#### **Create Harvesting Zone**

**Endpoint:**
```
POST /api/v1/admin/zones
```

**Request:**
```json
{
  "zone_id": "ZONE-HP-001",
  "name": "Shimla District - Zone A",
  "coordinates": [
    [28.6139, 77.2090],
    [28.7041, 77.1025],
    [28.6500, 77.1500],
    [28.6139, 77.2090]
  ],
  "authorized_species": ["Withania somnifera", "Ocimum sanctum"],
  "max_daily_harvest_kg": 100,
  "conservation_status": "sustainable",
  "created_by": "admin1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Harvesting zone created on blockchain",
  "data": {
    "zone_id": "ZONE-HP-001",
    "blockchain_txid": "tx_zone_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: CreateGeoFencedZone(zoneJSON)
```

---

#### **List All Zones**

**Endpoint:**
```
GET /api/v1/zones
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
        "coordinates": [[28.6139, 77.2090], [28.7041, 77.1025]],
        "authorized_species": ["Withania somnifera"],
        "max_daily_harvest_kg": 100,
        "conservation_status": "sustainable",
        "active_farmers": 25,
        "created_at": "2025-11-01T10:00:00Z"
      }
    ],
    "total": 10
  }
}
```

---

### **2.3 Seasonal Window Configuration**

#### **Create Season Window**

**Endpoint:**
```
POST /api/v1/admin/season-windows
```

**Request:**
```json
{
  "id": "season_ashwagandha_north",
  "species": "Withania somnifera",
  "start_month": 10,
  "end_month": 3,
  "region": "North India",
  "created_by": "admin1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Season window created on blockchain",
  "data": {
    "id": "season_ashwagandha_north",
    "blockchain_txid": "tx_season_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: CreateSeasonWindow(windowJSON)
```

---

#### **Get Season Windows**

**Endpoint:**
```
GET /api/v1/season-windows?species=Withania somnifera
```

**Response:**
```json
{
  "success": true,
  "data": {
    "season_windows": [
      {
        "id": "season_ashwagandha_north",
        "species": "Withania somnifera",
        "start_month": 10,
        "end_month": 3,
        "region": "North India",
        "status": "active"
      }
    ]
  }
}
```

---

### **2.4 Harvest Limit Configuration**

#### **Set Harvest Limit**

**Endpoint:**
```
POST /api/v1/admin/harvest-limits
```

**Request:**
```json
{
  "species": "Withania somnifera",
  "zone_id": "ZONE-HP-001",
  "daily_limit_kg": 100,
  "weekly_limit_kg": 500,
  "monthly_limit_kg": 2000,
  "per_farmer_daily_limit_kg": 50,
  "created_by": "admin1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Harvest limit set on blockchain",
  "data": {
    "id": 1,
    "blockchain_txid": "tx_limit_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: SetHarvestLimit(limitJSON)
```

---

### **2.5 System Monitoring**

#### **Dashboard Statistics**

**Endpoint:**
```
GET /api/v1/admin/dashboard
```

**Response:**
```json
{
  "success": true,
  "data": {
    "overview": {
      "total_farmers": 250,
      "active_farmers": 230,
      "total_collections": 1520,
      "total_batches": 85,
      "total_certificates": 65,
      "blockchain_txs_today": 45
    },
    "this_month": {
      "new_farmers": 12,
      "total_collections": 350,
      "total_quantity_kg": 12500,
      "batches_created": 15,
      "certificates_issued": 12
    },
    "blockchain_health": {
      "status": "UP",
      "connected": true,
      "last_block": 12345,
      "avg_tx_time_ms": 850
    },
    "alerts": [
      {
        "type": "harvest_limit_warning",
        "message": "Zone ZONE-HP-001 approaching daily harvest limit",
        "severity": "warning"
      }
    ],
    "recent_activity": [
      {
        "type": "collection_created",
        "farmer": "FARMER-HP-2025-001",
        "collection_number": "COL-2025-456",
        "timestamp": "2025-12-02T08:31:00Z"
      }
    ]
  }
}
```

---

## 📋 Module 3: Processor Dashboard

### **3.1 Batch Management**

#### **Create Batch**

**Endpoint:**
```
POST /api/v1/batches
```

**Request:**
```json
{
  "species": "Withania somnifera",
  "collection_ids": [456, 457, 458, 459, 460],
  "processor_id": 5,
  "notes": "High quality roots, uniform size"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Batch created and recorded on blockchain",
  "data": {
    "id": 789,
    "batch_number": "BATCH-2025-789",
    "species": "Withania somnifera",
    "total_weight_kg": 250.5,
    "status": "created",
    "processor_id": 5,
    "collection_count": 5,
    "blockchain_txid": "tx_batch_abc123",
    "created_at": "2025-12-02T10:00:00Z"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: CreateBatch(batchJSON)
{
  "batchID": "BATCH-2025-789",
  "species": "Withania somnifera",
  "totalQuantityKg": 250.5,
  "collectionIDs": ["COL-2025-456", "COL-2025-457", ...],
  "processorID": "processor1",
  "status": "created",
  "createdAt": "2025-12-02T10:00:00Z"
}
```

---

#### **List Batches**

**Endpoint:**
```
GET /api/v1/batches?status=processing&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "batches": [
      {
        "id": 789,
        "batch_number": "BATCH-2025-789",
        "species": "Withania somnifera",
        "total_weight_kg": 250.5,
        "status": "processing",
        "processor": {
          "id": 5,
          "name": "Processing Unit A"
        },
        "collection_count": 5,
        "created_at": "2025-12-02T10:00:00Z",
        "updated_at": "2025-12-03T14:00:00Z"
      }
    ],
    "pagination": {
      "total": 85,
      "page": 1,
      "pages": 5
    }
  }
}
```

---

#### **Update Batch Status**

**Endpoint:**
```
PUT /api/v1/batches/:batchId/status
```

**Request:**
```json
{
  "status": "quality_testing",
  "notes": "Processing complete, sent to lab"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Batch status updated on blockchain",
  "data": {
    "batch_number": "BATCH-2025-789",
    "status": "quality_testing",
    "blockchain_txid": "tx_status_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: UpdateBatchStatus(batchID, newStatus)
```

---

### **3.2 Processing Steps**

#### **Record Processing Step**

**Endpoint:**
```
POST /api/v1/batches/:batchId/processing-steps
```

**Request:**
```json
{
  "step_type": "drying",
  "step_number": 1,
  "description": "Root drying in controlled environment",
  "temperature_c": 40,
  "humidity_percent": 30,
  "duration_hours": 24,
  "start_time": "2025-12-02T10:00:00Z",
  "end_time": "2025-12-03T10:00:00Z",
  "operator_name": "John Doe",
  "notes": "Uniform drying, no discoloration"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Processing step recorded on blockchain",
  "data": {
    "id": 1,
    "batch_number": "BATCH-2025-789",
    "step_type": "drying",
    "blockchain_txid": "tx_step_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: RecordProcessingStep(stepJSON)
```

---

#### **Get Processing History**

**Endpoint:**
```
GET /api/v1/batches/:batchId/processing-steps
```

**Response:**
```json
{
  "success": true,
  "data": {
    "batch_number": "BATCH-2025-789",
    "processing_steps": [
      {
        "id": 1,
        "step_type": "drying",
        "step_number": 1,
        "description": "Root drying in controlled environment",
        "temperature_c": 40,
        "duration_hours": 24,
        "start_time": "2025-12-02T10:00:00Z",
        "end_time": "2025-12-03T10:00:00Z",
        "blockchain_txid": "tx_step_abc123"
      }
    ]
  }
}
```

---

## 📋 Module 4: Lab Dashboard

### **4.1 QC Test Management**

#### **Create QC Test**

**Endpoint:**
```
POST /api/v1/qc/tests
```

**Request:**
```json
{
  "batch_id": 789,
  "test_type": "Microbial Testing",
  "lab_name": "HerbalTrace Lab",
  "test_date": "2025-12-04",
  "parameters": {
    "total_bacterial_count": 1000,
    "yeast_mold_count": 50,
    "ecoli": "absent",
    "salmonella": "absent"
  },
  "result": "Pass",
  "tested_by": "Dr. Smith",
  "notes": "All parameters within acceptable limits"
}
```

**Response:**
```json
{
  "success": true,
  "message": "QC test recorded on blockchain",
  "data": {
    "id": 123,
    "test_number": "TEST-2025-123",
    "batch_id": 789,
    "test_type": "Microbial Testing",
    "result": "Pass",
    "blockchain_txid": "tx_test_abc123",
    "created_at": "2025-12-04T10:00:00Z"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: RecordQCTest(testJSON)
{
  "testID": "TEST-2025-123",
  "batchID": "BATCH-2025-789",
  "testType": "Microbial Testing",
  "result": "Pass",
  "parameters": {...},
  "testedBy": "Dr. Smith",
  "labName": "HerbalTrace Lab",
  "testDate": "2025-12-04",
  "recordedAt": "2025-12-04T10:00:00Z"
}
```

---

#### **List QC Tests**

**Endpoint:**
```
GET /api/v1/qc/tests?batch_id=789
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tests": [
      {
        "id": 123,
        "test_number": "TEST-2025-123",
        "batch_id": 789,
        "batch_number": "BATCH-2025-789",
        "test_type": "Microbial Testing",
        "result": "Pass",
        "test_date": "2025-12-04",
        "status": "completed",
        "has_certificate": false
      }
    ],
    "total": 3
  }
}
```

---

### **4.2 Certificate Generation**

#### **Generate Certificate**

**Endpoint:**
```
POST /api/v1/qc/tests/:testId/certificate
```

**Request:**
```json
{
  "valid_until": "2026-12-04"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Certificate generated and recorded on blockchain",
  "data": {
    "id": 456,
    "certificate_number": "CERT-2025-456",
    "test_id": 123,
    "batch_id": 789,
    "overall_result": "Pass",
    "issued_date": "2025-12-04T10:00:00Z",
    "valid_until": "2026-12-04T10:00:00Z",
    "blockchain_txid": "tx_cert_abc123"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: GenerateCertificate(certJSON)
{
  "certificateNumber": "CERT-2025-456",
  "testID": "TEST-2025-123",
  "batchID": "BATCH-2025-789",
  "overallResult": "Pass",
  "issuedDate": "2025-12-04T10:00:00Z",
  "validUntil": "2026-12-04T10:00:00Z",
  "issuedBy": "lab_user1",
  "issuedAt": "2025-12-04T10:00:00Z"
}
```

---

### **4.3 QR Code Generation**

#### **Generate QR Code for Certificate**

**Endpoint:**
```
POST /api/v1/qc/certificates/:certId/qr
```

**Response:**
```json
{
  "success": true,
  "message": "QR code generated successfully",
  "data": {
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "certificate_number": "CERT-2025-456",
    "batch_id": "BATCH-2025-789",
    "blockchain_tx": "tx_cert_abc123",
    "verification_url": "https://herbaltrace.com/verify/CERT-2025-456",
    "qr_payload": {
      "cert_id": "CERT-2025-456",
      "batch_id": "BATCH-2025-789",
      "test_type": "Microbial Testing",
      "result": "Pass",
      "issued": "2025-12-04T10:00:00Z",
      "valid_until": "2026-12-04T10:00:00Z",
      "blockchain_tx": "tx_cert_abc123",
      "signature": "hmac_sha256_signature_here"
    }
  }
}
```

**No Blockchain Transaction** (QR generation is off-chain)

---

### **4.4 Print Labels**

#### **Generate Printable Label**

**Endpoint:**
```
GET /api/v1/qc/certificates/:certId/label
```

**Response:**
```json
{
  "success": true,
  "data": {
    "label_pdf_url": "/downloads/labels/CERT-2025-456.pdf",
    "certificate_number": "CERT-2025-456",
    "batch_number": "BATCH-2025-789",
    "qr_code_base64": "data:image/png;base64,...",
    "label_data": {
      "product_name": "Organic Ashwagandha Root Powder",
      "batch_number": "BATCH-2025-789",
      "certificate_number": "CERT-2025-456",
      "species": "Withania somnifera",
      "net_weight": "250.5 kg",
      "test_date": "2025-12-04",
      "expiry_date": "2026-12-04",
      "qr_instructions": "Scan to verify authenticity"
    }
  }
}
```

---

## 📋 Module 5: Consumer Verification (Public)

### **5.1 QR Code Scanner**

**Frontend Implementation:**
```javascript
// Using html5-qrcode library
const html5QrCode = new Html5Qrcode("qr-reader");

html5QrCode.start(
  { facingMode: "environment" },
  { fps: 10, qrbox: 250 },
  (decodedText, decodedResult) => {
    // Parse QR code payload
    const payload = JSON.parse(decodedText);
    
    // Call verification API
    verifyQRCode(payload);
  }
);
```

---

### **5.2 Verify QR Code**

**Endpoint:**
```
POST /api/v1/qc/certificates/verify-qr
```

**Request:**
```json
{
  "qrData": "{\"cert_id\":\"CERT-2025-456\",\"batch_id\":\"BATCH-2025-789\",\"signature\":\"hmac_sha256...\"}"
}
```

**Response (Valid QR):**
```json
{
  "success": true,
  "message": "QR code verified successfully",
  "verified": true,
  "signature_valid": true,
  "database_match": true,
  "expired": false,
  "data": {
    "certificate": {
      "number": "CERT-2025-456",
      "batch_id": "BATCH-2025-789",
      "species": "Withania somnifera",
      "local_name": "Ashwagandha",
      "test_type": "Microbial Testing",
      "result": "Pass",
      "issued": "2025-12-04T10:00:00Z",
      "valid_until": "2026-12-04T10:00:00Z",
      "blockchain_tx": "tx_cert_abc123"
    },
    "batch": {
      "number": "BATCH-2025-789",
      "species": "Withania somnifera",
      "total_weight_kg": 250.5,
      "processor": "Processing Unit A",
      "created_at": "2025-12-02T10:00:00Z"
    },
    "collections": [
      {
        "collection_number": "COL-2025-456",
        "farmer": {
          "name": "Rajesh Kumar",
          "cooperative": "FarmersCoop Himachal"
        },
        "location": {
          "lat": 28.6139,
          "lng": 77.2090,
          "name": "Village Kharkhoda"
        },
        "quantity_kg": 50.5,
        "collection_date": "2025-12-02T08:30:15Z",
        "sustainability_score": 95
      }
    ],
    "processing_steps": [
      {
        "step_type": "drying",
        "description": "Root drying in controlled environment",
        "duration_hours": 24
      }
    ],
    "qc_tests": [
      {
        "test_type": "Microbial Testing",
        "result": "Pass",
        "test_date": "2025-12-04"
      }
    ],
    "blockchain_verification": {
      "certificate_exists": true,
      "batch_exists": true,
      "collections_verified": true,
      "total_transactions": 8,
      "blockchain_explorer_url": "https://explorer.herbaltrace.com/tx/tx_cert_abc123"
    },
    "sustainability": {
      "score": 95,
      "geo_fence_compliant": true,
      "seasonal_compliant": true,
      "conservation_compliant": true,
      "fair_trade_certified": true
    }
  }
}
```

**Response (Invalid/Tampered QR):**
```json
{
  "success": false,
  "verified": false,
  "signature_valid": false,
  "message": "QR code has been tampered with",
  "error_code": "SIGNATURE_MISMATCH"
}
```

---

### **5.3 Provenance Timeline**

**Endpoint:**
```
GET /api/v1/provenance/:certNumber
```

**Response:**
```json
{
  "success": true,
  "data": {
    "certificate_number": "CERT-2025-456",
    "product_name": "Organic Ashwagandha Root Powder",
    "timeline": [
      {
        "stage": "Collection",
        "timestamp": "2025-12-02T08:30:15Z",
        "location": {
          "lat": 28.6139,
          "lng": 77.2090,
          "name": "Village Kharkhoda, Haryana"
        },
        "actor": {
          "type": "farmer",
          "name": "Rajesh Kumar",
          "cooperative": "FarmersCoop Himachal"
        },
        "details": {
          "species": "Withania somnifera",
          "quantity_kg": 50.5,
          "quality_score": 95
        },
        "blockchain_tx": "tx_collection_abc123"
      },
      {
        "stage": "Batch Creation",
        "timestamp": "2025-12-02T10:00:00Z",
        "location": {
          "name": "Processing Unit A, Shimla"
        },
        "actor": {
          "type": "processor",
          "name": "Processing Unit A"
        },
        "details": {
          "batch_number": "BATCH-2025-789",
          "total_collections": 5,
          "total_weight_kg": 250.5
        },
        "blockchain_tx": "tx_batch_abc123"
      },
      {
        "stage": "Processing",
        "timestamp": "2025-12-02T10:00:00Z",
        "location": {
          "name": "Processing Unit A, Shimla"
        },
        "actor": {
          "type": "processor",
          "name": "Processing Unit A"
        },
        "details": {
          "step_type": "drying",
          "duration_hours": 24,
          "temperature_c": 40
        },
        "blockchain_tx": "tx_process_abc123"
      },
      {
        "stage": "Quality Testing",
        "timestamp": "2025-12-04T10:00:00Z",
        "location": {
          "name": "HerbalTrace Lab, Delhi"
        },
        "actor": {
          "type": "lab",
          "name": "Dr. Smith",
          "organization": "HerbalTrace Lab"
        },
        "details": {
          "test_type": "Microbial Testing",
          "result": "Pass",
          "parameters": {
            "total_bacterial_count": 1000,
            "ecoli": "absent"
          }
        },
        "blockchain_tx": "tx_test_abc123"
      },
      {
        "stage": "Certification",
        "timestamp": "2025-12-04T10:00:00Z",
        "location": {
          "name": "HerbalTrace Lab, Delhi"
        },
        "actor": {
          "type": "lab",
          "name": "HerbalTrace Lab"
        },
        "details": {
          "certificate_number": "CERT-2025-456",
          "valid_until": "2026-12-04"
        },
        "blockchain_tx": "tx_cert_abc123"
      }
    ],
    "supply_chain_map": {
      "markers": [
        {
          "type": "collection",
          "lat": 28.6139,
          "lng": 77.2090,
          "label": "Collection Point - Village Kharkhoda"
        },
        {
          "type": "processing",
          "lat": 31.1048,
          "lng": 77.1734,
          "label": "Processing Unit A - Shimla"
        },
        {
          "type": "lab",
          "lat": 28.7041,
          "lng": 77.1025,
          "label": "HerbalTrace Lab - Delhi"
        }
      ],
      "route": [
        [28.6139, 77.2090],
        [31.1048, 77.1734],
        [28.7041, 77.1025]
      ]
    }
  }
}
```

**Blockchain Query:**
```javascript
// Smart Contract: GetProvenance(certificateNumber)
// Returns complete supply chain history from blockchain
```

---

## 📋 Module 6: Manufacturer Dashboard

### **6.1 Finished Product Creation**

#### **Create Finished Product**

**Endpoint:**
```
POST /api/v1/products
```

**Request:**
```json
{
  "product_name": "Organic Ashwagandha Capsules - 60 Count",
  "product_code": "PROD-ASH-60CAP",
  "batch_ids": [789, 790],
  "formulation": {
    "primary_ingredient": "Withania somnifera root powder",
    "percentage": 100,
    "capsule_type": "vegetarian",
    "dosage_mg": 500
  },
  "manufacturing_date": "2025-12-05",
  "expiry_date": "2027-12-05",
  "batch_size": 1000,
  "manufacturer": "Ayurvedic Products Ltd",
  "manufacturing_license": "MFG-2025-001"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Finished product recorded on blockchain",
  "data": {
    "id": 1,
    "product_code": "PROD-ASH-60CAP",
    "product_name": "Organic Ashwagandha Capsules - 60 Count",
    "batch_ids": [789, 790],
    "blockchain_txid": "tx_product_abc123",
    "created_at": "2025-12-05T10:00:00Z"
  }
}
```

**Blockchain Transaction:**
```javascript
// Smart Contract: CreateFinishedProduct(productJSON)
{
  "productCode": "PROD-ASH-60CAP",
  "productName": "Organic Ashwagandha Capsules - 60 Count",
  "batchIDs": ["BATCH-2025-789", "BATCH-2025-790"],
  "formulation": {...},
  "manufacturingDate": "2025-12-05",
  "expiryDate": "2027-12-05",
  "manufacturer": "Ayurvedic Products Ltd",
  "createdAt": "2025-12-05T10:00:00Z"
}
```

---

### **6.2 Product QR Code Generation**

#### **Generate Product QR Code**

**Endpoint:**
```
POST /api/v1/products/:productId/qr
```

**Response:**
```json
{
  "success": true,
  "message": "Product QR code generated successfully",
  "data": {
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "product_code": "PROD-ASH-60CAP",
    "certificate_numbers": ["CERT-2025-456", "CERT-2025-457"],
    "verification_url": "https://herbaltrace.com/verify/PROD-ASH-60CAP"
  }
}
```

---

## 📋 Module 7: Analytics & Reporting

### **7.1 Supply Chain Dashboard**

**Endpoint:**
```
GET /api/v1/analytics/dashboard
```

**Response:**
```json
{
  "success": true,
  "data": {
    "real_time_metrics": {
      "active_collections_today": 45,
      "batches_in_processing": 12,
      "pending_qc_tests": 8,
      "certificates_generated_today": 5
    },
    "harvest_volume_by_species": [
      {
        "species": "Withania somnifera",
        "total_kg": 5200,
        "collections": 85
      },
      {
        "species": "Ocimum sanctum",
        "total_kg": 3400,
        "collections": 60
      }
    ],
    "harvest_volume_by_region": [
      {
        "region": "Himachal Pradesh",
        "total_kg": 6500,
        "collections": 95
      },
      {
        "region": "Haryana",
        "total_kg": 2100,
        "collections": 50
      }
    ],
    "quality_metrics": {
      "avg_sustainability_score": 92,
      "pass_rate_percent": 98,
      "fail_rate_percent": 2
    },
    "compliance_rates": {
      "geo_fence_compliance": 99,
      "seasonal_compliance": 97,
      "conservation_compliance": 100
    },
    "blockchain_metrics": {
      "total_transactions": 12450,
      "transactions_today": 45,
      "avg_block_time_ms": 850,
      "network_health": "excellent"
    }
  }
}
```

---

### **7.2 Export Compliance Report**

**Endpoint:**
```
GET /api/v1/analytics/compliance-report?start_date=2025-11-01&end_date=2025-12-01
```

**Response:**
```json
{
  "success": true,
  "data": {
    "report_period": {
      "start": "2025-11-01",
      "end": "2025-12-01"
    },
    "nmpb_compliance": {
      "total_collections": 350,
      "compliant_collections": 345,
      "compliance_rate": 98.6,
      "violations": [
        {
          "type": "geo_fence",
          "count": 3,
          "collections": ["COL-2025-100", "COL-2025-120"]
        },
        {
          "type": "seasonal",
          "count": 2,
          "collections": ["COL-2025-150"]
        }
      ]
    },
    "sustainability_metrics": {
      "avg_score": 93,
      "high_quality_percent": 85,
      "conservation_compliant": 100
    },
    "export_readiness": {
      "certified_batches": 25,
      "pending_certification": 5,
      "export_ready_kg": 5500
    },
    "pdf_url": "/reports/compliance/2025-11-01_2025-12-01.pdf"
  }
}
```

---

## 🎨 Web Portal UI/UX Requirements

### **Tech Stack Recommendation**
- **Frontend:** React with Next.js (SSR for SEO)
- **UI Library:** Tailwind CSS + shadcn/ui components
- **Charts:** Recharts or Chart.js
- **Maps:** Leaflet or Google Maps API
- **QR Scanner:** html5-qrcode
- **State Management:** Zustand or Redux Toolkit
- **API Client:** Axios with interceptors

### **Responsive Design**
- Desktop: 1920x1080 (primary)
- Tablet: 768x1024
- Mobile: 375x667 (public verification page only)

### **Authentication**
- JWT token stored in httpOnly cookies
- Automatic token refresh
- Role-based access control (RBAC)
- Session timeout: 24 hours

### **Performance**
- Lazy load routes (code splitting)
- Image optimization (Next.js Image component)
- API response caching (React Query)
- Virtual scrolling for large lists

---

## ✅ Integration Testing Checklist

### **Admin Module**
- [ ] Create farmer Login ID → Saves to blockchain
- [ ] SMS sent to farmer with Login ID
- [ ] Farmer can login on mobile app
- [ ] Revoke farmer access → Blockchain updated
- [ ] Create geo-fenced zone → Saves to blockchain
- [ ] Create season window → Saves to blockchain
- [ ] Set harvest limits → Saves to blockchain
- [ ] Dashboard stats update in real-time

### **Processor Module**
- [ ] Create batch from collections → Blockchain TX
- [ ] Update batch status → Blockchain TX
- [ ] Record processing steps → Blockchain TX
- [ ] View batch history → Shows all blockchain events

### **Lab Module**
- [ ] Create QC test → Blockchain TX
- [ ] Generate certificate → Blockchain TX
- [ ] Generate QR code → Returns signed QR
- [ ] Print label → PDF with QR code
- [ ] QR code scannable and verifiable

### **Consumer Verification**
- [ ] Scan QR code → Signature verified
- [ ] View full provenance → All stages shown
- [ ] Interactive map → Shows collection points
- [ ] Timeline visualization → Correct order
- [ ] Blockchain links → Open explorer (future)

### **Manufacturer Module**
- [ ] Create finished product → Blockchain TX
- [ ] Link multiple batches → References stored
- [ ] Generate product QR → Combines all certificates

### **Analytics**
- [ ] Dashboard loads statistics
- [ ] Charts render correctly
- [ ] Export compliance report → PDF generated
- [ ] Real-time updates (WebSocket or polling)

---

## 📞 Backend & Blockchain Integration Summary

### **All Required Backend Endpoints**

**Authentication & User Management:**
- `POST /api/v1/auth/register` (Admin creates farmer)
- `POST /api/v1/auth/login`
- `GET /api/v1/users`
- `PUT /api/v1/users/:id/revoke`

**Admin Configuration:**
- `POST /api/v1/admin/zones`
- `GET /api/v1/zones`
- `POST /api/v1/admin/season-windows`
- `GET /api/v1/season-windows`
- `POST /api/v1/admin/harvest-limits`
- `GET /api/v1/admin/dashboard`

**Batch Management:**
- `POST /api/v1/batches`
- `GET /api/v1/batches`
- `GET /api/v1/batches/:id`
- `PUT /api/v1/batches/:id/status`
- `POST /api/v1/batches/:id/processing-steps`
- `GET /api/v1/batches/:id/processing-steps`

**QC & Certification:**
- `POST /api/v1/qc/tests`
- `GET /api/v1/qc/tests`
- `POST /api/v1/qc/tests/:id/certificate`
- `POST /api/v1/qc/certificates/:id/qr`
- `POST /api/v1/qc/certificates/verify-qr` (Public)
- `GET /api/v1/qc/certificates/:id/label`

**Provenance & Verification:**
- `GET /api/v1/provenance/:certNumber` (Public)

**Products:**
- `POST /api/v1/products`
- `GET /api/v1/products`
- `POST /api/v1/products/:id/qr`

**Analytics:**
- `GET /api/v1/analytics/dashboard`
- `GET /api/v1/analytics/compliance-report`

### **All Required Blockchain Smart Contracts**

**Farmer Management:**
- `RegisterFarmer(farmerJSON)`
- `GetFarmerByLoginID(loginID)`
- `ValidateFarmerLogin(loginID)`
- `RevokeFarmerAccess(loginID, reason)`

**Geo-Fencing & Compliance:**
- `CreateGeoFencedZone(zoneJSON)`
- `GetFarmerZones(farmerID)`
- `ValidateGeoFence(lat, lng, farmerID)`
- `CreateSeasonWindow(windowJSON)`
- `CheckSeasonalWindow(species, date)`
- `SetHarvestLimit(limitJSON)`
- `CheckHarvestLimit(farmerID, species, quantityKg, date)`

**Batch Management:**
- `CreateBatch(batchJSON)`
- `GetBatch(batchID)`
- `UpdateBatchStatus(batchID, newStatus)`
- `RecordProcessingStep(stepJSON)`

**QC & Certification:**
- `RecordQCTest(testJSON)`
- `GenerateCertificate(certJSON)`
- `VerifyCertificate(certificateNumber)`

**Products:**
- `CreateFinishedProduct(productJSON)`

**Provenance:**
- `GetProvenance(certificateNumber)` → Returns full supply chain history

---

**Web Portal Ready for Development! 🌐**  
**Backend Endpoints:** Complete & Documented  
**Blockchain Smart Contracts:** Complete & Documented  
**User Roles:** Admin, Lab, Processor, Manufacturer, Consumer  
**Public Features:** Landing Page, QR Verification, Provenance Timeline  
**Integration:** Seamless with Mobile App & Blockchain
