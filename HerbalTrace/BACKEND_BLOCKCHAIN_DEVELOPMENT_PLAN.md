# Backend + Blockchain Development Plan

## 🎯 Your Role: Backend API + Blockchain Only

You build and expose APIs → Frontend team integrates with your APIs

---

## 📋 Development Workflow

### Phase 1: Deploy Enhanced Chaincode ✅ (Week 1)
**Goal:** Get all 24 new blockchain functions running on network

**Tasks:**
1. Package enhanced chaincode
2. Install on all peer nodes (Org1, Org2, Org3)
3. Approve and commit to channel
4. Test using `peer chaincode invoke` commands
5. Verify batch management, alerts, season/harvest validations work

**Deliverable:** Working blockchain with 24 new functions

---

### Phase 2: Build Backend API Layer (Week 2-3)
**Goal:** Create REST APIs that call chaincode functions

**Backend Structure:**
```
backend/src/
├── routes/
│   ├── batches.ts           (8 endpoints)
│   ├── seasonWindows.ts     (4 endpoints)
│   ├── harvestLimits.ts     (6 endpoints)
│   ├── alerts.ts            (10 endpoints)
│   ├── collections.ts       (enhanced)
│   ├── qualityTests.ts      (enhanced)
│   ├── processingSteps.ts   (enhanced)
│   └── products.ts          (enhanced)
│
├── controllers/
│   ├── BatchController.ts
│   ├── SeasonWindowController.ts
│   ├── HarvestLimitController.ts
│   ├── AlertController.ts
│   └── ... (for existing endpoints)
│
├── services/
│   ├── FabricService.ts     (Hyperledger Fabric connection)
│   ├── BatchService.ts
│   ├── AlertService.ts
│   └── ValidationService.ts
│
├── middleware/
│   ├── auth.ts              (JWT authentication)
│   ├── rbac.ts              (Role-based access control)
│   ├── errorHandler.ts
│   └── validator.ts         (Request validation)
│
└── utils/
    ├── fabricConnection.ts
    ├── walletManager.ts
    └── responseFormatter.ts
```

**API Endpoints to Build (30+ total):**

#### Batch Management (8 endpoints)
```
POST   /api/batches                    - Create batch
GET    /api/batches/:batchId           - Get batch details
GET    /api/batches/:batchId/history   - Get batch history
POST   /api/batches/:batchId/assign    - Assign to processor (Admin)
PATCH  /api/batches/:batchId/status    - Update status
GET    /api/batches/status/:status     - Query by status
GET    /api/batches/processor/:id      - Query by processor
GET    /api/batches/pending             - Get pending batches (Admin)
```

#### Season Windows (4 endpoints)
```
POST   /api/admin/season-windows       - Create season window (Admin)
GET    /api/season-windows/:species    - Get season windows
PUT    /api/admin/season-windows/:id   - Update season window (Admin)
POST   /api/season-windows/validate    - Validate harvest date
```

#### Harvest Limits (6 endpoints)
```
POST   /api/admin/harvest-limits       - Create limit (Admin)
GET    /api/harvest-limits/statistics  - Get statistics
GET    /api/harvest-limits/alerts      - Get limit alerts
POST   /api/admin/harvest-limits/reset - Reset seasonal limits (Admin)
```

#### Alerts (10 endpoints)
```
POST   /api/alerts                     - Create alert
GET    /api/alerts                     - Get all alerts
GET    /api/alerts/active              - Get active alerts
GET    /api/alerts/critical            - Get critical alerts
GET    /api/alerts/type/:type          - Get by type
GET    /api/alerts/severity/:severity  - Get by severity
GET    /api/alerts/entity/:id          - Get by entity
PATCH  /api/alerts/:id/acknowledge     - Acknowledge alert
PATCH  /api/alerts/:id/resolve         - Resolve alert
GET    /api/alerts/statistics          - Get statistics
```

#### Enhanced Existing APIs
```
POST   /api/collections                - Now with 8-step validation
POST   /api/quality-tests              - Now with batch status update
POST   /api/processing-steps           - Now with batch status update
POST   /api/products                   - Now with batch status update
```

---

### Phase 3: Authentication & Authorization (Week 4)
**Goal:** Secure APIs with role-based access

**Roles:**
- **Admin** - Full access, manage season windows, harvest limits, assign batches
- **Farmer** - Create collections, view their batches, check limits
- **Processor** - View assigned batches, create processing steps
- **Lab** - Create quality tests
- **Manufacturer** - Create products
- **Regulator** - View all data, manage alerts

**Auth Flow:**
1. User logs in → Backend issues JWT token
2. Frontend includes token in `Authorization: Bearer <token>` header
3. Backend validates token and checks role permissions
4. API responds with data or 403 Forbidden

---

### Phase 4: API Documentation (Week 4)
**Goal:** Generate comprehensive API docs for frontend team

**Tools:**
- Swagger/OpenAPI 3.0
- Postman Collection
- API Blueprint

**Documentation Includes:**
1. Base URL (e.g., `https://api.herbaltrace.com`)
2. Authentication method (JWT)
3. All endpoint details:
   - Method, Path, Description
   - Request headers
   - Request body schemas
   - Response schemas
   - Example requests/responses
   - Error codes
4. Role-based access matrix
5. Event streaming (WebSocket/SSE) for real-time alerts

**Example Documentation:**

```yaml
openapi: 3.0.0
info:
  title: HerbalTrace API
  version: 1.0.0
  description: Blockchain-based herbal supply chain traceability API

servers:
  - url: https://api.herbaltrace.com/v1
    description: Production server

paths:
  /batches:
    post:
      summary: Create a new batch
      tags: [Batch Management]
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [species, totalQuantity, unit, createdBy]
              properties:
                species:
                  type: string
                  example: "Ashwagandha"
                totalQuantity:
                  type: number
                  example: 150.5
                unit:
                  type: string
                  example: "kg"
                collectionEventIds:
                  type: array
                  items:
                    type: string
                  example: ["event_001", "event_002"]
      responses:
        201:
          description: Batch created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: 
                    type: boolean
                  data:
                    $ref: '#/components/schemas/Batch'
        400:
          description: Invalid request
        401:
          description: Unauthorized
        403:
          description: Forbidden
```

---

### Phase 5: Deployment & Handoff (Week 5)
**Goal:** Deploy backend and provide access to frontend team

**Deployment Steps:**

1. **Deploy Backend to Cloud**
   ```bash
   # Option 1: Azure App Service
   az webapp up --name herbaltrace-api --resource-group herbaltrace-rg
   
   # Option 2: AWS EC2 + Docker
   docker build -t herbaltrace-backend .
   docker run -p 3000:3000 herbaltrace-backend
   
   # Option 3: DigitalOcean Droplet
   npm run build
   pm2 start dist/index.js --name herbaltrace-api
   ```

2. **Configure CORS**
   ```typescript
   // Allow frontend domains
   app.use(cors({
     origin: [
       'http://localhost:3001',           // Local development
       'https://app.herbaltrace.com',     // Production web app
       'https://admin.herbaltrace.com'    // Admin portal
     ],
     credentials: true
   }));
   ```

3. **Provide to Frontend Team:**
   - ✅ Base URL: `https://api.herbaltrace.com`
   - ✅ Swagger docs: `https://api.herbaltrace.com/docs`
   - ✅ Postman collection (import into Postman)
   - ✅ Test credentials for each role
   - ✅ WebSocket URL for real-time alerts: `wss://api.herbaltrace.com`

---

## 📦 What Frontend Team Gets

### 1. API Base URL
```
Production:  https://api.herbaltrace.com
Staging:     https://staging-api.herbaltrace.com
Development: http://localhost:3000
```

### 2. Authentication
```bash
POST /api/auth/login
{
  "username": "farmer1",
  "password": "password123"
}

Response:
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "farmer1",
      "name": "Ramesh Kumar",
      "role": "farmer",
      "organization": "FarmersCoop"
    }
  }
}
```

### 3. Example API Call
```javascript
// Frontend code
const response = await fetch('https://api.herbaltrace.com/api/batches', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  },
  body: JSON.stringify({
    species: 'Ashwagandha',
    totalQuantity: 100,
    unit: 'kg',
    createdBy: 'farmer1'
  })
});

const data = await response.json();
console.log(data);
```

### 4. Real-Time Alerts (WebSocket)
```javascript
const ws = new WebSocket('wss://api.herbaltrace.com');

ws.onmessage = (event) => {
  const alert = JSON.parse(event.data);
  if (alert.type === 'over_harvest') {
    showNotification('Warning: Harvest limit approaching 80%');
  }
};
```

### 5. Interactive API Documentation
```
https://api.herbaltrace.com/docs

Frontend devs can:
- Browse all endpoints
- See request/response schemas
- Try API calls directly from browser
- Copy code examples (JavaScript, Python, cURL)
```

---

## 🎯 Your Deliverables to Frontend Team

### Week 5 Handoff Package:

1. **API Documentation** (Swagger)
   - All 30+ endpoints documented
   - Request/response schemas
   - Authentication guide
   - Error codes

2. **Postman Collection**
   - Pre-configured API calls
   - Environment variables (dev, staging, prod)
   - Test data examples

3. **Access Credentials**
   - Test accounts for each role:
     - `farmer1` / password
     - `processor1` / password
     - `lab1` / password
     - `manufacturer1` / password
     - `admin1` / password
     - `regulator1` / password

4. **Base URLs**
   - Production API URL
   - Staging API URL
   - WebSocket URL

5. **Integration Guide**
   - Authentication flow
   - Error handling
   - Rate limiting info
   - Best practices

6. **Sample Code**
   ```javascript
   // JavaScript/React example
   import axios from 'axios';
   
   const api = axios.create({
     baseURL: 'https://api.herbaltrace.com',
     headers: {
       'Authorization': `Bearer ${token}`
     }
   });
   
   // Create batch
   const createBatch = async (batchData) => {
     const response = await api.post('/api/batches', batchData);
     return response.data;
   };
   
   // Get active alerts
   const getAlerts = async () => {
     const response = await api.get('/api/alerts/active');
     return response.data;
   };
   ```

---

## 🚀 Next Steps (Priority Order)

### Step 1: Deploy Enhanced Chaincode ⏭️ START HERE
```bash
cd d:\Trial\HerbalTrace\network
./deploy-herbaltrace-network.sh
```

### Step 2: Test Chaincode Functions
```bash
# Test batch creation
peer chaincode invoke -C herbaltrace-channel -n herbaltrace \
  -c '{"function":"CreateBatch","Args":[...]}'

# Test all 24 new functions
```

### Step 3: Build Backend API Layer
```bash
cd d:\Trial\HerbalTrace\backend
npm install express cors dotenv jsonwebtoken swagger-ui-express

# Create route files, controllers, services
```

### Step 4: Add Authentication
```bash
npm install bcrypt jsonwebtoken express-validator
# Implement JWT auth middleware
```

### Step 5: Generate API Documentation
```bash
npm install swagger-jsdoc swagger-ui-express
# Add Swagger annotations to routes
```

### Step 6: Deploy Backend
```bash
# Deploy to cloud
# Configure CORS
# Test all endpoints
```

### Step 7: Share with Frontend Team
- Provide base URL
- Share Swagger docs
- Share Postman collection
- Provide test credentials

---

## 📊 Timeline Summary

| Week | Focus | Deliverable |
|------|-------|-------------|
| Week 1 | Deploy chaincode | 24 new functions on blockchain |
| Week 2 | Build APIs (Part 1) | Batch, Season, Harvest endpoints |
| Week 3 | Build APIs (Part 2) | Alerts + enhanced existing endpoints |
| Week 4 | Auth + Docs | Secured APIs + Swagger documentation |
| Week 5 | Deploy + Handoff | Live API + Frontend team integration |

---

## ✅ Success Criteria

**Your job is complete when:**
1. ✅ Enhanced chaincode deployed and tested
2. ✅ All 30+ API endpoints working
3. ✅ Authentication/authorization implemented
4. ✅ API documentation generated (Swagger)
5. ✅ Backend deployed to cloud
6. ✅ CORS configured for frontend access
7. ✅ Test credentials provided
8. ✅ Postman collection shared
9. ✅ Frontend team can successfully make API calls

**Frontend team builds:**
- Mobile app (Flutter)
- Web portal (React)
- Admin dashboard (React)
- Consumer portal (React)

They just call your APIs! 🎉

---

Ready to start with **Step 1: Deploy Enhanced Chaincode**?
