# QR Code API Documentation

## Overview
The HerbalTrace system now includes **Signed QR Code** generation and verification for Quality Control certificates. This ensures tamper-proof, blockchain-backed certificate verification.

---

## 🔐 Security Features

### Signed QR Codes
- **HMAC-SHA256 signature** prevents tampering
- **Blockchain transaction ID** for immutable verification
- **Offline-capable** - QR contains all necessary data
- **Consumer-friendly** - Simple scan for instant verification

### QR Code Payload Structure
```json
{
  "cert_id": "CERT-2025-001",
  "batch_id": "BATCH-789",
  "test_type": "Microbial Testing",
  "result": "Pass",
  "issued": "2025-12-02T16:45:00Z",
  "valid_until": "2026-12-02T16:45:00Z",
  "blockchain_tx": "abc123def456...",
  "issued_by": "HerbalTrace Lab",
  "species": "Ashwagandha",
  "signature": "314191430efeb707...",
  "verified": true
}
```

---

## 📋 API Endpoints

### 1. Generate QR Code for Certificate

**Endpoint:** `POST /api/v1/qc/certificates/:id/qr`

**Authentication:** Required (JWT token)

**Description:** Generates a signed QR code containing certificate data with cryptographic signature.

**Request:**
```http
POST /api/v1/qc/certificates/123/qr
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response:**
```json
{
  "success": true,
  "message": "QR code generated successfully",
  "data": {
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "certificate_number": "CERT-2025-001",
    "batch_id": "BATCH-789",
    "blockchain_tx": "abc123def456...",
    "payload": {
      "cert_id": "CERT-2025-001",
      "batch_id": "BATCH-789",
      "test_type": "Microbial Testing",
      "result": "Pass",
      "issued": "2025-12-02T16:45:00Z",
      "valid_until": "2026-12-02T16:45:00Z",
      "blockchain_tx": "abc123def456...",
      "issued_by": "HerbalTrace Lab",
      "species": "Ashwagandha",
      "signature": "314191430efeb707750a9ae89d6f1ba0f1cf53afae4e813d2835715fa2007fcd",
      "verified": true
    },
    "verification_url": "http://localhost:3000/verify/CERT-2025-001"
  }
}
```

**Usage:**
```javascript
// Generate QR code
const response = await fetch('http://localhost:3000/api/v1/qc/certificates/123/qr', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
const qrCodeImage = data.data.qrCode; // base64 data URL

// Display in HTML
document.getElementById('qrImage').src = qrCodeImage;
```

---

### 2. Verify QR Code

**Endpoint:** `POST /api/v1/qc/certificates/verify-qr`

**Authentication:** Not required (Public endpoint)

**Description:** Verifies the signature and authenticity of a scanned QR code.

**Request:**
```http
POST /api/v1/qc/certificates/verify-qr
Content-Type: application/json

{
  "qrData": "{\"cert_id\":\"CERT-2025-001\",\"batch_id\":\"BATCH-789\",\"signature\":\"314191430efeb...\"}"
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
    "cert_id": "CERT-2025-001",
    "batch_id": "BATCH-789",
    "test_type": "Microbial Testing",
    "result": "Pass",
    "issued": "2025-12-02T16:45:00Z",
    "valid_until": "2026-12-02T16:45:00Z",
    "blockchain_tx": "abc123def456...",
    "issued_by": "HerbalTrace Lab",
    "species": "Ashwagandha",
    "signature": "314191430efeb707...",
    "verified": true,
    "certificate": {
      "number": "CERT-2025-001",
      "batch_id": "BATCH-789",
      "species": "Ashwagandha",
      "test_type": "Microbial Testing",
      "result": "Pass",
      "issued": "2025-12-02T16:45:00Z",
      "blockchain_tx": "abc123def456..."
    }
  }
}
```

**Response (Invalid/Tampered QR):**
```json
{
  "success": false,
  "message": "QR code signature verification failed - This certificate may be tampered or counterfeit",
  "verified": false
}
```

**Usage:**
```javascript
// After scanning QR code
const scannedData = JSON.parse(qrCodeContent);

const response = await fetch('http://localhost:3000/api/v1/qc/certificates/verify-qr', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ qrData: qrCodeContent })
});

const result = await response.json();

if (result.verified && result.signature_valid) {
  console.log('✅ Certificate is authentic!');
  console.log('Blockchain TX:', result.data.blockchain_tx);
} else {
  console.log('❌ Certificate may be counterfeit!');
}
```

---

## 🔄 Complete Workflow

### Step 1: Create QC Test
```bash
POST /api/v1/qc/tests
{
  "batch_id": 1,
  "test_type": "Microbial Testing",
  "lab_name": "HerbalTrace Lab"
}
```

### Step 2: Generate Certificate (with Blockchain)
```bash
POST /api/v1/qc/tests/:testId/certificate
{
  "valid_until": "2026-12-02"
}
```
✅ Certificate recorded on blockchain automatically

### Step 3: Generate QR Code
```bash
POST /api/v1/qc/certificates/:certId/qr
```
✅ Returns signed QR code image (base64 PNG)

### Step 4: Consumer Scans QR
- Consumer scans QR code with mobile app
- App extracts JSON payload from QR

### Step 5: Verify Certificate
```bash
POST /api/v1/qc/certificates/verify-qr
{
  "qrData": "<scanned-qr-content>"
}
```
✅ Returns verification result with blockchain proof

---

## 🛡️ Security Implementation

### Signature Generation
```javascript
const crypto = require('crypto');

const qrPayload = {
  cert_id: 'CERT-2025-001',
  batch_id: 'BATCH-789',
  // ... other fields
};

const secret = process.env.QR_SIGNING_SECRET;
const dataToSign = JSON.stringify(qrPayload);
const signature = crypto
  .createHmac('sha256', secret)
  .update(dataToSign)
  .digest('hex');

const signedPayload = { ...qrPayload, signature };
```

### Signature Verification
```javascript
const { signature, ...dataWithoutSignature } = scannedPayload;

const dataToVerify = JSON.stringify(dataWithoutSignature);
const expectedSignature = crypto
  .createHmac('sha256', secret)
  .update(dataToVerify)
  .digest('hex');

const isValid = signature === expectedSignature;
```

---

## 🎨 QR Code Specifications

- **Format:** PNG image (base64 data URL)
- **Size:** 400x400 pixels
- **Error Correction:** High (30% recovery)
- **Margin:** 2 modules
- **Colors:** Black on white
- **Encoding:** JSON string with signature

---

## 🧪 Testing

### Test QR Generation
```bash
cd backend
node test-qr-generation.js
```

### Test via cURL
```bash
# Generate QR
curl -X POST http://localhost:3000/api/v1/qc/certificates/1/qr \
  -H "Authorization: Bearer <token>" \
  | jq '.data.qrCode' > qr.txt

# Verify QR
curl -X POST http://localhost:3000/api/v1/qc/certificates/verify-qr \
  -H "Content-Type: application/json" \
  -d '{"qrData": "<scanned-content>"}' \
  | jq .
```

---

## ⚙️ Configuration

### Environment Variables
```env
# QR Code Signing Secret (CHANGE IN PRODUCTION!)
QR_SIGNING_SECRET=herbaltrace-qr-secret-key-change-in-production

# Public URL for verification links
PUBLIC_URL=https://herbaltrace.com
```

**⚠️ IMPORTANT:** Change `QR_SIGNING_SECRET` in production to a strong random key!

---

## 📱 Consumer Verification UI

### Recommended Flow
1. **Scan QR** - Consumer scans with mobile camera
2. **Parse Data** - Extract JSON payload
3. **Verify Signature** - Call `/verify-qr` endpoint
4. **Display Results** - Show certificate details + blockchain proof
5. **Show Map** - Display supply chain journey

### UI Elements to Show
- ✅ **Certificate Status** (Valid/Invalid/Expired)
- 📋 **Certificate Number**
- 🌿 **Species & Batch Info**
- 🔬 **Test Results**
- ⛓️ **Blockchain Transaction** (clickable link)
- 📅 **Issue & Expiry Dates**
- 🗺️ **Supply Chain Map** (next feature)

---

## 🚀 Next Steps

### Frontend Integration Tasks
1. **Web Portal Consumer Page**
   - QR scanner component (use `html5-qrcode` library)
   - Verification result display
   - Certificate detail view

2. **Mobile App Integration**
   - Integrate QR scanner (Flutter `qr_code_scanner`)
   - Call verification API
   - Show blockchain transaction link

3. **Interactive Supply Chain Map**
   - Leaflet/Google Maps integration
   - Show journey: Farm → Lab → Processor → Manufacturer
   - Timeline view with GPS coordinates

4. **Print Label Generation**
   - Generate printable labels with QR codes
   - Include batch info + QR
   - Export as PDF

---

## ✅ Implementation Complete

**Backend QR Features:** ✅ DONE
- [x] Signed QR code generation
- [x] HMAC-SHA256 signature
- [x] Blockchain transaction reference
- [x] Public verification endpoint
- [x] Tamper detection
- [x] Expiry checking
- [x] Database validation

**Next Phase:** Frontend Integration (Web Portal + Mobile App)
