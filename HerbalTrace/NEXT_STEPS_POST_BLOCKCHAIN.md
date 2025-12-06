# 🚀 HerbalTrace - Post-Blockchain Development Plan

> **Current Status:** ✅ Blockchain Layer Complete (Hyperledger Fabric with 38 functions deployed)  
> **Next Phase:** Backend → Hosting → Frontend → Testing → Production

---

## 📋 Table of Contents
1. [Project Flow Overview](#project-flow-overview)
2. [Phase 1: Backend Development](#phase-1-backend-development)
3. [Phase 2: Backend Deployment & Hosting](#phase-2-backend-deployment--hosting)
4. [Phase 3: Frontend Development](#phase-3-frontend-development)
5. [Phase 4: Integration & Testing](#phase-4-integration--testing)
6. [Phase 5: Production Deployment](#phase-5-production-deployment)
7. [Timeline & Milestones](#timeline--milestones)

---

## 🔄 Project Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     CURRENT STATUS                               │
│  ✅ Blockchain Layer Complete                                   │
│     - Hyperledger Fabric Network (8 peers, 3 orderers)         │
│     - Chaincode v2.1 (38 functions)                            │
│     - 7 CouchDB indexes                                        │
│     - All 4 organizations approved                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 1: BACKEND DEVELOPMENT (4 weeks)             │
│  🛠️  Build NestJS Backend API                                  │
│     Week 1-2: Core modules (Auth, Blockchain service)          │
│     Week 3-4: Business logic (Collections, Batches, Products)  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│        PHASE 2: BACKEND HOSTING & DEPLOYMENT (1 week)          │
│  ☁️  Deploy to Cloud (AWS/Azure/GCP)                           │
│     - Setup production database (PostgreSQL + Redis)           │
│     - Configure environment variables                          │
│     - Setup CI/CD pipeline                                     │
│     - Deploy with Docker                                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         PHASE 3: FRONTEND DEVELOPMENT (5 weeks)                 │
│  📱 Mobile App (Flutter) - Week 1-3                            │
│     - Farmer app (harvest tracking)                            │
│     - Consumer app (QR scanning)                               │
│  💻 Web Portal (React) - Week 4-5                              │
│     - Lab/Processor/Manufacturer portals                       │
│     - Admin dashboard                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│       PHASE 4: INTEGRATION & TESTING (2 weeks)                  │
│  🔗 Frontend ↔ Backend ↔ Blockchain Integration                │
│     Week 1: API integration + Unit testing                     │
│     Week 2: End-to-end testing + Bug fixes                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│          PHASE 5: PRODUCTION DEPLOYMENT (1 week)                │
│  🚀 Go Live                                                     │
│     - Security audit                                           │
│     - Performance optimization                                 │
│     - Production release                                       │
│     - User training                                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ✅ PRODUCTION READY
```

---

## 🛠️ Phase 1: Backend Development (4 Weeks)

### **Week 1: Foundation & Core Services**

#### **Day 1-2: Project Initialization**
```bash
# 1. Create NestJS project
cd d:\Trial\HerbalTrace
nest new backend --package-manager npm

# 2. Navigate to backend directory
cd backend

# 3. Install core dependencies
npm install @nestjs/config @nestjs/typeorm typeorm pg redis @nestjs/bull bull
npm install fabric-network fabric-ca-client fabric-common
npm install @nestjs/jwt @nestjs/passport passport passport-jwt bcrypt
npm install class-validator class-transformer

# 4. Install additional dependencies
npm install @nestjs/swagger swagger-ui-express
npm install winston nest-winston
npm install @aws-sdk/client-s3 multer
npm install axios

# 5. Setup project structure
mkdir -p src/blockchain src/auth src/users src/common/guards src/common/decorators src/common/filters
```

**Deliverables:**
- ✅ NestJS project initialized
- ✅ All dependencies installed
- ✅ Project structure created
- ✅ Environment configuration (.env file)

#### **Day 3-5: Blockchain Service Module**
```typescript
// src/blockchain/blockchain.service.ts
// Core functionality:
// - Connect to Hyperledger Fabric network
// - Load connection profiles from network/organizations/
// - Manage wallets (admin + user identities)
// - submitTransaction() - for write operations
// - evaluateTransaction() - for read operations
```

**Tasks:**
1. Create `blockchain.module.ts`
2. Implement `blockchain.service.ts` with Fabric SDK
3. Implement `wallet.service.ts` for identity management
4. Create `connection-profile.service.ts` to load network configs
5. Test connection to deployed chaincode

**Test Command:**
```bash
# Test blockchain connection
npm run test:e2e -- blockchain.service.spec.ts
```

**Deliverables:**
- ✅ Blockchain service with Fabric SDK integration
- ✅ Wallet management (create, import, export identities)
- ✅ Transaction submission working
- ✅ Transaction evaluation working
- ✅ Connection to chaincode v2.1 verified

#### **Day 6-7: Authentication Module**
```typescript
// src/auth/auth.service.ts
// Core functionality:
// - User registration with Fabric identity
// - JWT-based login (access + refresh tokens)
// - Role-based access control (Farmer, Lab, Processor, Manufacturer, Admin)
// - Password hashing with bcrypt
```

**Tasks:**
1. Create `auth.module.ts`
2. Implement `auth.controller.ts` (register, login, refresh, logout)
3. Implement `auth.service.ts` with JWT strategy
4. Create `users.module.ts` and `users.service.ts`
5. Create database schema for users table
6. Implement role-based guards (`farmer.guard.ts`, `admin.guard.ts`)

**Database Schema:**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL, -- 'farmer', 'lab', 'processor', 'manufacturer', 'admin'
  
  -- Organization details
  org_id VARCHAR(100) NOT NULL, -- 'FARM001', 'LAB001', etc.
  org_name VARCHAR(255) NOT NULL,
  org_type VARCHAR(50) NOT NULL, -- 'FarmersCoopMSP', 'TestingLabsMSP', etc.
  
  -- Fabric identity
  fabric_user_id VARCHAR(255) NOT NULL,
  wallet_registered BOOLEAN DEFAULT FALSE,
  
  -- Profile
  full_name VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE,
  kyc_verified BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_org_id ON users(org_id);
```

**Deliverables:**
- ✅ User registration with Fabric identity
- ✅ JWT authentication working
- ✅ Role-based guards implemented
- ✅ PostgreSQL database schema created
- ✅ User profile management APIs

---

### **Week 2: Core Business Logic - Part 1**

#### **Day 1-3: Collection Events Module**
```typescript
// src/collection-events/collection-events.service.ts
// Core functionality:
// - Create collection event with GPS, images, weather
// - Validate season window (with 15s delay handling)
// - Upload images to S3/IPFS
// - Submit transaction to blockchain
// - Cache in PostgreSQL
```

**Tasks:**
1. Create `collection-events.module.ts`
2. Implement `collection-events.controller.ts`
3. Implement `collection-events.service.ts`
4. Create image upload service with S3 integration
5. Integrate OpenWeatherMap API
6. Create cache table in PostgreSQL
7. Test end-to-end flow

**Database Schema:**
```sql
CREATE TABLE collection_events_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id VARCHAR(100) UNIQUE NOT NULL, -- From blockchain
  farmer_id VARCHAR(100) NOT NULL,
  farmer_name VARCHAR(255) NOT NULL,
  
  species VARCHAR(100) NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  
  latitude NUMERIC(10,7) NOT NULL,
  longitude NUMERIC(10,7) NOT NULL,
  altitude NUMERIC(8,2),
  
  harvest_date DATE NOT NULL,
  harvest_method VARCHAR(50),
  part_collected VARCHAR(50),
  
  weather_data JSONB,
  image_urls TEXT[], -- Array of S3 URLs
  
  blockchain_tx_id VARCHAR(255),
  synced BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_collection_farmer ON collection_events_cache(farmer_id);
CREATE INDEX idx_collection_species ON collection_events_cache(species);
CREATE INDEX idx_collection_date ON collection_events_cache(harvest_date);
```

**API Endpoints:**
```
POST   /api/v1/collections
GET    /api/v1/collections/:id
GET    /api/v1/collections/farmer/:farmerId
POST   /api/v1/collections/:id/images
```

**Deliverables:**
- ✅ Collection events creation working
- ✅ Image upload to S3 working
- ✅ Weather API integration working
- ✅ Season window validation working (with 15s delay)
- ✅ Blockchain submission working
- ✅ PostgreSQL caching working

#### **Day 4-5: Batches Module**
```typescript
// src/batches/batches.service.ts
// Core functionality:
// - Create batch from collection events
// - Assign batch to processor
// - Update batch status
// - Query batches by status/processor
```

**Tasks:**
1. Create `batches.module.ts`
2. Implement `batches.controller.ts`
3. Implement `batches.service.ts`
4. Create cache table in PostgreSQL
5. Test batch creation and assignment

**Database Schema:**
```sql
CREATE TABLE batches_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id VARCHAR(100) UNIQUE NOT NULL,
  
  collection_event_ids TEXT[] NOT NULL,
  species VARCHAR(100) NOT NULL,
  total_quantity NUMERIC(10,2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  
  status VARCHAR(50) NOT NULL, -- 'collected', 'assigned', 'testing', 'processing', 'manufactured'
  
  processor_id VARCHAR(100),
  processor_name VARCHAR(255),
  assigned_at TIMESTAMP,
  
  blockchain_tx_id VARCHAR(255),
  synced BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_batch_status ON batches_cache(status);
CREATE INDEX idx_batch_processor ON batches_cache(processor_id);
```

**API Endpoints:**
```
POST   /api/v1/batches
GET    /api/v1/batches/:id
PUT    /api/v1/batches/:id/assign
PUT    /api/v1/batches/:id/status
GET    /api/v1/batches/status/:status
GET    /api/v1/batches/processor/:processorId
```

**Deliverables:**
- ✅ Batch creation working
- ✅ Processor assignment working
- ✅ Status updates working
- ✅ Query APIs working

---

### **Week 3: Core Business Logic - Part 2**

#### **Day 1-2: Quality Tests Module**
```typescript
// src/quality-tests/quality-tests.service.ts
// Core functionality:
// - Create quality test with certificate upload
// - Store certificate in S3/IPFS
// - Submit to blockchain
// - Auto-update batch status
```

**Tasks:**
1. Create `quality-tests.module.ts`
2. Implement controller and service
3. Certificate upload integration
4. Test end-to-end

**API Endpoints:**
```
POST   /api/v1/quality-tests
GET    /api/v1/quality-tests/:id
GET    /api/v1/quality-tests/batch/:batchId
POST   /api/v1/quality-tests/:id/certificate
```

#### **Day 3-4: Processing Steps Module**
```typescript
// src/processing/processing.service.ts
// Core functionality:
// - Create processing step (drying, grinding, extraction, formulation)
// - Track input/output quantities
// - Record process parameters
// - Link to previous steps
```

**API Endpoints:**
```
POST   /api/v1/processing
GET    /api/v1/processing/:id
GET    /api/v1/processing/batch/:batchId
GET    /api/v1/processing/chain/:stepId
```

#### **Day 5: Products Module (Encrypted QR)**
```typescript
// src/products/products.service.ts
// src/products/qr.service.ts
// Core functionality:
// - Create product with encrypted QR
// - Generate QR code image
// - Link to collection events, tests, processing
// - Calculate sustainability score
```

**Encrypted QR Implementation:**
```typescript
import * as crypto from 'crypto';
import * as QRCode from 'qrcode';

async generateEncryptedQR(productData) {
  // 1. Generate AES-256 key
  const key = crypto.randomBytes(32);
  const iv = crypto.randomBytes(16);
  
  // 2. Prepare payload
  const payload = {
    productId: productData.id,
    timestamp: Date.now()
  };
  
  // 3. Encrypt
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(JSON.stringify(payload), 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  // 4. Create QR payload
  const qrPayload = {
    v: '1.0',
    d: encrypted,
    i: iv.toString('hex'),
    t: Date.now()
  };
  
  // 5. Generate QR image
  const qrCode = Buffer.from(JSON.stringify(qrPayload)).toString('base64');
  const qrImage = await QRCode.toDataURL(qrCode, { width: 300 });
  
  // 6. Store encryption key securely
  await this.storeEncryptionKey(productData.id, key.toString('hex'));
  
  return { qrCode, qrImage };
}
```

**API Endpoints:**
```
POST   /api/v1/products
GET    /api/v1/products/:id
GET    /api/v1/products/qr/:qrCode
POST   /api/v1/products/qr/decrypt
GET    /api/v1/products/:id/qr-image
```

**Deliverables:**
- ✅ Quality tests working
- ✅ Processing steps working
- ✅ Products with encrypted QR working
- ✅ QR encryption/decryption working

---

### **Week 4: Advanced Features & Testing**

#### **Day 1-2: Provenance & Consumer APIs**
```typescript
// src/provenance/provenance.service.ts
// Core functionality:
// - Decrypt QR code
// - Fetch complete supply chain history
// - Generate provenance bundle
```

**API Endpoints:**
```
GET    /api/v1/provenance/qr/:qrCode
GET    /api/v1/provenance/product/:productId
POST   /api/v1/provenance/decrypt-and-fetch
```

#### **Day 3: Season Windows & Harvest Limits**
```typescript
// src/season-windows/season-windows.service.ts
// - Pre-populate season windows with 15s delays
// - CRUD operations

// src/harvest-limits/harvest-limits.service.ts
// - Create harvest limits
// - Track quantities
// - Validate limits
```

#### **Day 4: Alerts & Notifications**
```typescript
// src/alerts/alerts.service.ts
// - Create alerts
// - Query active/critical alerts
// - Acknowledge/resolve

// src/notifications/notifications.service.ts
// - Push notifications (Firebase)
// - SMS (Twilio)
// - Email (SendGrid)
```

#### **Day 5: Analytics Dashboard**
```typescript
// src/analytics/analytics.service.ts
// - Role-based dashboards
// - Statistics queries
// - Export reports
```

#### **Day 6-7: Testing & Documentation**
```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Generate Swagger docs
# Access: http://localhost:3000/api/docs
```

**Deliverables:**
- ✅ All 40+ API endpoints implemented
- ✅ Unit tests written (>80% coverage)
- ✅ E2E tests written
- ✅ Swagger documentation complete
- ✅ Backend ready for deployment

---

## ☁️ Phase 2: Backend Deployment & Hosting (1 Week)

### **Option A: AWS Deployment (Recommended)**

#### **Day 1: Setup AWS Infrastructure**
```bash
# 1. Create EC2 instance (Ubuntu 22.04)
# - t3.medium (2 vCPU, 4GB RAM)
# - Storage: 50GB SSD

# 2. Create RDS PostgreSQL instance
# - db.t3.small
# - PostgreSQL 15.x
# - Multi-AZ for production

# 3. Create ElastiCache Redis
# - cache.t3.micro
# - Redis 7.x

# 4. Create S3 bucket for images
aws s3 mb s3://herbaltrace-images

# 5. Setup Security Groups
# - Allow ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3000 (Backend)
```

#### **Day 2-3: Deploy Backend**
```bash
# 1. SSH into EC2 instance
ssh -i herbaltrace-key.pem ubuntu@<EC2_PUBLIC_IP>

# 2. Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Install Docker & Docker Compose
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER

# 4. Clone repository
git clone https://github.com/kunaldubey10/Trail.git
cd Trail/backend

# 5. Create .env.production
cat > .env.production << EOF
NODE_ENV=production
PORT=3000

# Database
DATABASE_HOST=<RDS_ENDPOINT>
DATABASE_PORT=5432
DATABASE_NAME=herbaltrace_prod
DATABASE_USER=admin
DATABASE_PASSWORD=<SECURE_PASSWORD>

# Redis
REDIS_HOST=<ELASTICACHE_ENDPOINT>
REDIS_PORT=6379

# Blockchain Network
FABRIC_NETWORK_PATH=/root/Trail/network
FABRIC_CHANNEL_NAME=herbaltrace-channel
FABRIC_CHAINCODE_NAME=herbaltrace
FABRIC_MSP_ID=FarmersCoopMSP

# JWT
JWT_SECRET=<GENERATE_SECURE_SECRET>
JWT_EXPIRY=1h
JWT_REFRESH_EXPIRY=7d

# AWS S3
AWS_ACCESS_KEY_ID=<ACCESS_KEY>
AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
AWS_REGION=us-east-1
AWS_S3_BUCKET=herbaltrace-images

# External APIs
OPENWEATHER_API_KEY=<API_KEY>
TWILIO_ACCOUNT_SID=<SID>
TWILIO_AUTH_TOKEN=<TOKEN>
SENDGRID_API_KEY=<API_KEY>
EOF

# 6. Build Docker image
docker build -t herbaltrace-backend:latest .

# 7. Run with Docker Compose
docker-compose -f docker-compose.prod.yml up -d

# 8. Run database migrations
docker exec herbaltrace-backend npm run migration:run

# 9. Initialize season windows
docker exec herbaltrace-backend npm run seed:seasons
```

#### **Day 4: Setup Nginx Reverse Proxy**
```bash
# 1. Install Nginx
sudo apt-get install -y nginx certbot python3-certbot-nginx

# 2. Configure Nginx
sudo nano /etc/nginx/sites-available/herbaltrace-api

# Add:
server {
    listen 80;
    server_name api.herbaltrace.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# 3. Enable site
sudo ln -s /etc/nginx/sites-available/herbaltrace-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# 4. Setup SSL with Let's Encrypt
sudo certbot --nginx -d api.herbaltrace.com
```

#### **Day 5: Setup CI/CD with GitHub Actions**
```yaml
# .github/workflows/deploy-backend.yml
name: Deploy Backend to AWS

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to EC2
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ubuntu
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd /root/Trail/backend
            git pull origin main
            docker-compose -f docker-compose.prod.yml down
            docker build -t herbaltrace-backend:latest .
            docker-compose -f docker-compose.prod.yml up -d
            docker exec herbaltrace-backend npm run migration:run
```

#### **Day 6: Monitoring & Logging**
```bash
# 1. Setup PM2 for process management
npm install -g pm2
pm2 start npm --name "herbaltrace-backend" -- run start:prod
pm2 save
pm2 startup

# 2. Setup logging with Winston → CloudWatch
# Already configured in backend code

# 3. Setup monitoring with Prometheus + Grafana
docker-compose -f docker-compose.monitoring.yml up -d

# 4. Configure health checks
# Endpoint: GET /api/v1/health
```

#### **Day 7: Production Testing**
```bash
# 1. Test health endpoint
curl https://api.herbaltrace.com/api/v1/health

# 2. Test Swagger docs
# https://api.herbaltrace.com/api/docs

# 3. Test authentication
curl -X POST https://api.herbaltrace.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test@123","role":"farmer"}'

# 4. Performance testing
npm install -g autocannon
autocannon -c 100 -d 30 https://api.herbaltrace.com/api/v1/health
```

**Deliverables:**
- ✅ Backend deployed on AWS EC2
- ✅ PostgreSQL RDS configured
- ✅ Redis ElastiCache configured
- ✅ S3 bucket for images
- ✅ Nginx reverse proxy with SSL
- ✅ CI/CD pipeline configured
- ✅ Monitoring & logging setup
- ✅ Production URL: `https://api.herbaltrace.com`

---

## 📱 Phase 3: Frontend Development (5 Weeks)

### **Week 1-3: Mobile App (Flutter)**

#### **Week 1: Foundation & Authentication**
```bash
# Day 1-2: Project setup
cd d:\Trial\HerbalTrace\mobile-app

# Install dependencies
flutter pub get

# Day 3-5: Authentication screens
# - lib/features/auth/screens/login_screen.dart
# - lib/features/auth/screens/register_screen.dart
# - lib/features/auth/services/auth_service.dart
# - JWT token management
# - Secure storage (flutter_secure_storage)

# Day 6-7: User profile & settings
# - lib/features/profile/screens/profile_screen.dart
# - lib/features/settings/screens/settings_screen.dart
```

**Key Features:**
- Login/Register with JWT
- Biometric authentication (fingerprint/face ID)
- Token refresh logic
- Offline authentication (cached credentials)

#### **Week 2: Farmer Features**
```bash
# Day 1-3: Farmer dashboard
# - lib/features/farmer/screens/dashboard_screen.dart
# - Statistics cards (total collections, quantity, earnings)
# - Recent collections list
# - Pending tasks
# - Active alerts

# Day 4-7: Collection event creation
# - lib/features/collections/screens/create_collection_screen.dart
# - GPS auto-capture (geolocator package)
# - Camera integration (image_picker)
# - Multi-image upload
# - Weather display (auto-fetched from backend)
# - Species dropdown (searchable)
# - Quantity input with unit selection
# - Offline mode (SQLite cache)

# Database: lib/core/database/app_database.dart (sqflite)
```

**API Integration:**
```dart
// lib/features/collections/services/collections_service.dart
import 'package:dio/dio.dart';

class CollectionsService {
  final Dio _dio;
  final String baseUrl = 'https://api.herbaltrace.com/api/v1';
  
  Future<CollectionEvent> createCollection({
    required String species,
    required double quantity,
    required String unit,
    required double latitude,
    required double longitude,
    required DateTime harvestDate,
    List<File>? images,
  }) async {
    // 1. Upload images
    List<String> imageUrls = [];
    if (images != null) {
      for (var image in images) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(image.path),
        });
        final response = await _dio.post('$baseUrl/upload', data: formData);
        imageUrls.add(response.data['url']);
      }
    }
    
    // 2. Create collection event
    final response = await _dio.post(
      '$baseUrl/collections',
      data: {
        'species': species,
        'quantity': quantity,
        'unit': unit,
        'latitude': latitude,
        'longitude': longitude,
        'harvestDate': harvestDate.toIso8601String(),
        'imageUrls': imageUrls,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    
    return CollectionEvent.fromJson(response.data);
  }
}
```

#### **Week 3: Consumer Features (QR Scanning)**
```bash
# Day 1-3: QR Scanner
# - lib/features/consumer/screens/qr_scanner_screen.dart
# - Camera QR scanning (qr_code_scanner package)
# - Encrypted QR decryption (call backend API)

# Day 4-7: Provenance Journey
# - lib/features/consumer/screens/provenance_screen.dart
# - Timeline view (timeline_tile package)
# - Interactive map (google_maps_flutter)
# - Farmer profiles
# - Quality test results
# - Processing steps
# - Sustainability score (circular progress indicator)
# - Share functionality (share_plus package)
```

**QR Scanner Implementation:**
```dart
// lib/features/consumer/screens/qr_scanner_screen.dart
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
  
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      
      // Decrypt QR and fetch provenance
      try {
        final provenance = await ProvenanceService().decryptAndFetch(scanData.code!);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProvenanceScreen(provenance: provenance),
          ),
        );
      } catch (e) {
        _showError(e.toString());
        controller.resumeCamera();
      }
    });
  }
}
```

**Deliverables (Mobile App):**
- ✅ Authentication working (login, register, biometric)
- ✅ Farmer dashboard with statistics
- ✅ Collection event creation (GPS, camera, offline mode)
- ✅ QR scanner with encrypted QR decryption
- ✅ Provenance journey screen (timeline, map)
- ✅ Offline mode (SQLite caching)
- ✅ Push notifications (Firebase)

---

### **Week 4-5: Web Portal (React)**

#### **Week 4: Lab & Processor Portals**
```bash
# Day 1-2: Project setup
cd d:\Trial\HerbalTrace\web-portal

# Install dependencies
npm install axios react-router-dom @tanstack/react-query
npm install @mui/material @emotion/react @emotion/styled
npm install recharts react-map-gl
npm install qrcode react-qr-code

# Day 3-4: Lab portal
# - src/pages/lab/Dashboard.jsx
# - src/pages/lab/PendingTests.jsx
# - src/pages/lab/CreateQualityTest.jsx
# - src/pages/lab/TestHistory.jsx

# Day 5-7: Processor portal
# - src/pages/processor/Dashboard.jsx
# - src/pages/processor/AssignedBatches.jsx
# - src/pages/processor/CreateProcessingStep.jsx
# - src/pages/processor/ProcessingHistory.jsx
```

**Lab: Create Quality Test**
```jsx
// src/pages/lab/CreateQualityTest.jsx
import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { qualityTestsApi } from '@/api/quality-tests';

function CreateQualityTest() {
  const [formData, setFormData] = useState({
    batchId: '',
    activeCompounds: { value: '', unit: 'mg/g' },
    pesticides: 'Absent',
    heavyMetals: 'Within limits',
    microbial: 'Pass',
    dnaBarcoding: 'Confirmed',
    overallResult: 'Pass',
  });
  const [certificate, setCertificate] = useState(null);
  
  const createTestMutation = useMutation({
    mutationFn: qualityTestsApi.create,
    onSuccess: () => {
      alert('Quality test created successfully!');
      navigate('/lab/tests');
    },
  });
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // 1. Upload certificate
    const certificateUrl = await uploadCertificate(certificate);
    
    // 2. Submit quality test
    createTestMutation.mutate({
      ...formData,
      certificateUrl,
    });
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <h1>Create Quality Test</h1>
      
      <select value={formData.batchId} onChange={(e) => setFormData({...formData, batchId: e.target.value})}>
        <option value="">Select Batch</option>
        {/* Fetch pending batches */}
      </select>
      
      <input
        type="number"
        placeholder="Active Compounds (mg/g)"
        value={formData.activeCompounds.value}
        onChange={(e) => setFormData({...formData, activeCompounds: {...formData.activeCompounds, value: e.target.value}})}
      />
      
      <select value={formData.pesticides} onChange={(e) => setFormData({...formData, pesticides: e.target.value})}>
        <option value="Absent">Absent</option>
        <option value="Present">Present</option>
      </select>
      
      {/* More fields... */}
      
      <input
        type="file"
        accept="application/pdf"
        onChange={(e) => setCertificate(e.target.files[0])}
      />
      
      <button type="submit">Submit Quality Test</button>
    </form>
  );
}
```

#### **Week 5: Manufacturer & Admin Portals**
```bash
# Day 1-3: Manufacturer portal
# - src/pages/manufacturer/Dashboard.jsx
# - src/pages/manufacturer/CreateProduct.jsx
# - src/pages/manufacturer/ProductInventory.jsx
# - src/pages/manufacturer/QRManagement.jsx (Encrypted QR generation)

# Day 4-7: Admin portal
# - src/pages/admin/Dashboard.jsx (Network-wide statistics)
# - src/pages/admin/UserManagement.jsx
# - src/pages/admin/SeasonWindows.jsx
# - src/pages/admin/HarvestLimits.jsx
# - src/pages/admin/Alerts.jsx
# - src/pages/admin/Analytics.jsx (Charts with Recharts)
# - src/pages/admin/BlockchainExplorer.jsx
```

**Manufacturer: Create Product with Encrypted QR**
```jsx
// src/pages/manufacturer/CreateProduct.jsx
import { useState } from 'react';
import QRCode from 'react-qr-code';

function CreateProduct() {
  const [formData, setFormData] = useState({
    name: '',
    quantity: '',
    unit: '',
    batchId: '',
    collectionEventIds: [],
    qualityTestIds: [],
    processingStepIds: [],
    certificationIds: [],
  });
  const [qrData, setQrData] = useState(null);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Create product (backend generates encrypted QR)
    const response = await fetch('https://api.herbaltrace.com/api/v1/products', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(formData),
    });
    
    const product = await response.json();
    setQrData(product.qrCode);
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <h1>Create Product</h1>
      
      <input
        type="text"
        placeholder="Product Name"
        value={formData.name}
        onChange={(e) => setFormData({...formData, name: e.target.value})}
      />
      
      {/* More fields... */}
      
      <button type="submit">Create Product</button>
      
      {qrData && (
        <div>
          <h2>Encrypted QR Code Generated</h2>
          <QRCode value={qrData} size={300} />
          <button onClick={() => downloadQR(qrData)}>Download QR</button>
        </div>
      )}
    </form>
  );
}
```

**Deliverables (Web Portal):**
- ✅ Lab portal (pending tests, create test, certificate upload)
- ✅ Processor portal (assigned batches, processing steps)
- ✅ Manufacturer portal (create product, encrypted QR generation)
- ✅ Admin portal (user management, season windows, analytics, blockchain explorer)
- ✅ Responsive design (mobile-friendly)
- ✅ Role-based access control
- ✅ Real-time updates (WebSocket)

---

## 🔗 Phase 4: Integration & Testing (2 Weeks)

### **Week 1: API Integration & Unit Testing**

#### **Day 1-3: Frontend-Backend Integration**
```bash
# Test all API endpoints with frontend

# 1. Authentication
✅ Register user → Get JWT token
✅ Login → Get access + refresh tokens
✅ Protected routes → Verify token

# 2. Farmer flow
✅ Create collection event → Upload images → Submit to blockchain
✅ View collection history
✅ Check harvest limits

# 3. Lab flow
✅ View pending batches
✅ Create quality test → Upload certificate → Submit to blockchain
✅ Verify batch status updated

# 4. Processor flow
✅ View assigned batches
✅ Create processing step → Submit to blockchain

# 5. Manufacturer flow
✅ Create product → Generate encrypted QR
✅ Download QR image
✅ View product inventory

# 6. Consumer flow
✅ Scan encrypted QR → Decrypt → Fetch provenance
✅ View complete journey
✅ Share journey
```

#### **Day 4-5: Unit Testing**
```bash
# Backend tests
cd backend
npm run test -- --coverage

# Frontend tests (Mobile)
cd mobile-app
flutter test

# Frontend tests (Web)
cd web-portal
npm run test
```

#### **Day 6-7: Fix Integration Issues**
- Fix any CORS issues
- Fix authentication errors
- Fix image upload issues
- Fix QR encryption/decryption issues

---

### **Week 2: End-to-End Testing & Bug Fixes**

#### **Day 1-5: E2E Testing (Complete Workflow)**

**Test Scenario 1: Farmer to Consumer Journey**
```
1. Farmer registers and logs in
2. Farmer creates collection event (GPS, images, weather)
3. Admin assigns collection events to batch
4. Lab receives batch, creates quality test, uploads certificate
5. Processor receives batch, creates processing steps
6. Manufacturer creates product with encrypted QR
7. Consumer scans QR code
8. Consumer views complete provenance journey
✅ Verify all data matches
✅ Verify blockchain transactions recorded
✅ Verify GPS coordinates on map
```

**Test Scenario 2: Season Window Validation**
```
1. Admin creates season window (Ashwagandha, Nov-Feb, Madhya Pradesh)
2. Wait 15 seconds (CouchDB indexing delay)
3. Farmer tries to create collection in March → Rejected
4. Farmer creates collection in December → Accepted
✅ Verify season window validation working
```

**Test Scenario 3: Harvest Limit Validation**
```
1. Admin sets harvest limit (FARM001, Ashwagandha, 500kg)
2. Farmer harvests 400kg → Accepted
3. Farmer harvests 150kg → Rejected (exceeds limit)
4. Alert generated for limit exceeded
✅ Verify harvest limit validation working
✅ Verify alert created
```

**Test Scenario 4: Encrypted QR Security**
```
1. Manufacturer creates product → Gets encrypted QR
2. Consumer scans QR → Decrypts successfully
3. Attacker tries to modify QR data → Decryption fails (tamper detection)
4. Attacker tries to use old QR (>1 year) → Rejected (expiry)
✅ Verify QR encryption secure
✅ Verify tamper detection working
```

#### **Day 6-7: Bug Fixes & Performance Optimization**
- Fix any remaining bugs
- Optimize API response times
- Optimize database queries
- Optimize frontend rendering
- Test on different devices (iOS, Android, Desktop)

**Deliverables:**
- ✅ All API integrations working
- ✅ Unit tests passing (>80% coverage)
- ✅ E2E tests passing (all scenarios)
- ✅ No critical bugs
- ✅ Performance optimized (<500ms API response time)
- ✅ Tested on multiple devices

---

## 🚀 Phase 5: Production Deployment (1 Week)

### **Day 1-2: Security Audit**
```bash
# 1. Backend security audit
npm audit fix
npm run lint

# 2. Check for vulnerabilities
npm install -g snyk
snyk test

# 3. SSL certificate verification
curl -I https://api.herbaltrace.com

# 4. API rate limiting test
autocannon -c 1000 -d 10 https://api.herbaltrace.com/api/v1/health

# 5. Database security
# - Enable SSL for PostgreSQL
# - Rotate passwords
# - Setup backup strategy

# 6. Penetration testing
# - Test SQL injection
# - Test XSS vulnerabilities
# - Test CSRF protection
# - Test authentication bypass
```

### **Day 3-4: Mobile App Release**

#### **Android Release**
```bash
cd mobile-app

# 1. Update version in pubspec.yaml
version: 1.0.0+1

# 2. Build APK
flutter build apk --release

# 3. Build App Bundle (for Play Store)
flutter build appbundle --release

# 4. Sign APK
keytool -genkey -v -keystore ~/herbaltrace-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias herbaltrace

# 5. Upload to Google Play Console
# - Create app listing
# - Upload app bundle
# - Fill app details
# - Submit for review
```

#### **iOS Release**
```bash
# 1. Update version in pubspec.yaml
version: 1.0.0+1

# 2. Build iOS app
flutter build ios --release

# 3. Open Xcode
open ios/Runner.xcworkspace

# 4. Archive app in Xcode
# Product → Archive

# 5. Upload to App Store Connect
# Window → Organizer → Upload

# 6. Submit for review
```

### **Day 5: Web Portal Deployment**
```bash
cd web-portal

# 1. Build production bundle
npm run build

# 2. Deploy to AWS S3 + CloudFront
aws s3 sync build/ s3://herbaltrace-web --delete
aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"

# 3. Configure custom domain
# - Route 53 DNS: portal.herbaltrace.com → CloudFront
# - SSL certificate from ACM

# 4. Test production URL
curl https://portal.herbaltrace.com
```

### **Day 6: User Training & Documentation**
```bash
# 1. Create user manuals
# - Farmer guide (PDF)
# - Lab guide (PDF)
# - Processor guide (PDF)
# - Manufacturer guide (PDF)
# - Admin guide (PDF)
# - Consumer guide (PDF)

# 2. Create video tutorials
# - How to create collection event
# - How to scan QR code
# - How to view provenance
# - Admin panel walkthrough

# 3. Conduct training sessions
# - Train farmers (on-site)
# - Train lab technicians
# - Train processors
# - Train manufacturers
# - Train admins

# 4. Setup support system
# - Help desk email: support@herbaltrace.com
# - WhatsApp support group
# - Phone support hotline
```

### **Day 7: Go Live! 🚀**
```bash
# 1. Final health checks
curl https://api.herbaltrace.com/api/v1/health
curl https://api.herbaltrace.com/api/v1/health/blockchain
curl https://api.herbaltrace.com/api/v1/health/database

# 2. Monitor for first 24 hours
# - Watch server logs
# - Monitor error rates
# - Track API response times
# - Check database queries
# - Monitor blockchain transactions

# 3. Announce launch
# - Press release
# - Social media posts
# - Email to stakeholders
# - Website banner

# 4. Collect feedback
# - User feedback form
# - Bug report form
# - Feature request form
```

**Deliverables:**
- ✅ Security audit passed
- ✅ Mobile apps published (Android + iOS)
- ✅ Web portal deployed
- ✅ User training completed
- ✅ Documentation ready
- ✅ Support system setup
- ✅ Production monitoring active
- ✅ **SYSTEM LIVE! 🎉**

---

## 📅 Timeline & Milestones

| Phase | Duration | Start Date | End Date | Milestone |
|-------|----------|------------|----------|-----------|
| **Phase 1: Backend Development** | 4 weeks | Week 1 | Week 4 | Backend APIs ready |
| **Phase 2: Backend Deployment** | 1 week | Week 5 | Week 5 | Backend hosted on AWS |
| **Phase 3: Frontend Development** | 5 weeks | Week 6 | Week 10 | Mobile app + Web portal ready |
| **Phase 4: Integration & Testing** | 2 weeks | Week 11 | Week 12 | All systems integrated |
| **Phase 5: Production Deployment** | 1 week | Week 13 | Week 13 | **PRODUCTION LAUNCH 🚀** |

**Total Duration: 13 Weeks (~3 months)**

---

## ✅ Success Criteria

### **Backend Success Metrics**
- ✅ All 40+ API endpoints working
- ✅ <500ms average API response time
- ✅ >99% uptime
- ✅ >80% unit test coverage
- ✅ Zero critical security vulnerabilities
- ✅ Swagger documentation complete

### **Frontend Success Metrics**
- ✅ Mobile app published on Play Store + App Store
- ✅ Web portal accessible at portal.herbaltrace.com
- ✅ <2s page load time
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Offline mode working (mobile)
- ✅ Push notifications working

### **Integration Success Metrics**
- ✅ Farmer can create collection event
- ✅ Lab can submit quality test
- ✅ Manufacturer can generate encrypted QR
- ✅ Consumer can scan QR and view provenance
- ✅ All blockchain transactions recorded
- ✅ Real-time updates working

### **Production Success Metrics**
- ✅ System live and accessible
- ✅ 100+ active users in first month
- ✅ 500+ collection events in first month
- ✅ 50+ products with QR codes
- ✅ 1000+ QR scans by consumers
- ✅ <1% error rate
- ✅ 24/7 monitoring active

---

## 🎯 Next Immediate Action

```bash
# START HERE! 👇

# 1. Create backend project
cd d:\Trial\HerbalTrace
nest new backend --package-manager npm

# 2. Install dependencies
cd backend
npm install @nestjs/config @nestjs/typeorm typeorm pg redis @nestjs/bull bull
npm install fabric-network fabric-ca-client
npm install @nestjs/jwt @nestjs/passport passport passport-jwt bcrypt
npm install class-validator class-transformer
npm install @nestjs/swagger swagger-ui-express

# 3. Start development
npm run start:dev

# 4. Access Swagger docs
# http://localhost:3000/api/docs
```

---

**LET'S BUILD! 🚀**

Blockchain is complete ✅  
Roadmap is clear ✅  
Team is ready ✅  
Time to code! 💪
