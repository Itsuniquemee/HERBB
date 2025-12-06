# 🔗 GitHub App Integration Guide for HerbalTrace Blockchain

## ✅ Current Status

### Blockchain Network: **OPERATIONAL** ✅
- **Network**: herbaltrace.com
- **Orderers**: 3 RAFT nodes running (orderer, orderer2, orderer3)
- **Peers**: 8 peers across 4 organizations
  - Farmers: peer0, peer1
  - Labs: peer0, peer1
  - Processors: peer0, peer1
  - Manufacturers: peer0, peer1
- **CLI Container**: Running for blockchain operations

### Required Setup Steps
1. ✅ Network containers running
2. ⏳ Channel creation needed
3. ⏳ Chaincode deployment needed
4. ⏳ Backend API integration
5. ⏳ Frontend app integration

---

## 📋 Step 1: Complete Blockchain Setup

### 1.1 Check Network Scripts
```powershell
cd d:\Trial\HerbalTrace\network
Get-ChildItem *.sh
```

### 1.2 Create Channel & Deploy Chaincode
If you have setup scripts:
```powershell
# From network directory
.\deploy-network.sh createChannel
.\deploy-network.sh deployChaincode
```

Or use the quick-start script:
```powershell
cd d:\Trial\HerbalTrace
.\quick-start.ps1
```

### 1.3 Test Blockchain Transaction
```powershell
docker exec cli peer chaincode invoke -o orderer.herbaltrace.com:7050 -C herbaltrace-channel -n herbaltrace --peerAddresses peer0.farmers.herbaltrace.com:7051 -c '{"function":"InitLedger","Args":[]}'
```

---

## 🌐 Step 2: Clone Your Web App from GitHub

### 2.1 Prepare Directory
```powershell
cd d:\Trial\HerbalTrace
# Your current structure:
# HerbalTrace/
# ├── web-portal/        (existing, needs replacement)
# ├── farmer-app/        (existing, needs replacement)
# ├── mobile-app/        (existing, might need replacement)
# └── backend/           (existing backend API)
```

### 2.2 Option A: Replace Existing Folders
```powershell
# Backup current apps
Rename-Item web-portal web-portal-old
Rename-Item farmer-app farmer-app-old
Rename-Item mobile-app mobile-app-old

# Clone your web app (provide your GitHub URL)
git clone <YOUR_WEB_APP_GITHUB_URL> web-app-new
git clone <YOUR_MOBILE_APP_GITHUB_URL> mobile-app-new
```

### 2.3 Option B: Clone to New Folders
```powershell
# Clone to separate folders for comparison
git clone <YOUR_WEB_APP_GITHUB_URL> github-web-app
git clone <YOUR_MOBILE_APP_GITHUB_URL> github-mobile-app
```

---

## 🔧 Step 3: Web App Integration

### 3.1 Identify App Type
Once cloned, check the structure:
```powershell
cd github-web-app
Get-ChildItem
```

**Common structures:**
- **React App**: package.json, src/, public/
- **Next.js**: next.config.js, pages/ or app/
- **Vue.js**: vue.config.js, src/
- **Angular**: angular.json, src/

### 3.2 Install Dependencies
```powershell
npm install
# or
yarn install
```

### 3.3 Configure Backend API URL
Find and update API configuration:
```javascript
// Common files to check:
// - src/config.js
// - .env
// - src/api/config.ts
// - src/constants/api.js

// Update to:
const API_BASE_URL = "http://localhost:3000/api";
// or
REACT_APP_API_URL=http://localhost:3000/api
```

### 3.4 Review Required API Endpoints
Your web app should call these backend endpoints:
```javascript
// Collection Events (Farmer)
POST   /api/collections              - Create harvest event
GET    /api/collections/:id          - Get harvest details
GET    /api/collections/farmer/:id   - Get farmer's harvests

// Quality Tests (Lab)
POST   /api/quality-tests            - Submit lab results
GET    /api/quality-tests/:id        - Get test details
GET    /api/quality-tests/collection/:id

// Processing Steps (Processor)
POST   /api/processing               - Record processing step
GET    /api/processing/:id
GET    /api/processing/batch/:id

// Products (Manufacturer)
POST   /api/products                 - Create product + QR
GET    /api/products/:id
GET    /api/products/qr/:qrcode      - Consumer scanning

// Provenance (Consumer)
GET    /api/provenance/:productId    - Full supply chain history
GET    /api/provenance/qr/:qrcode    - Scan QR for provenance
```

### 3.5 Start Web App
```powershell
npm start
# or
npm run dev
# or
yarn dev
```

---

## 📱 Step 4: Mobile App Integration

### 4.1 Identify Mobile Framework
```powershell
cd github-mobile-app
Get-ChildItem
```

**Common frameworks:**
- **React Native**: package.json, app.json, metro.config.js
- **Flutter**: pubspec.yaml, android/, ios/, lib/
- **Expo**: app.json with "expo" config

### 4.2 React Native / Expo Setup
```powershell
# Install dependencies
npm install

# Update API URL in config
# Find: src/config.js or app.config.js
# Update:
export const API_BASE_URL = "http://YOUR_IP:3000/api";  # Not localhost!
```

**Important**: Mobile apps can't use `localhost` - use your machine's IP:
```powershell
# Get your IP address
ipconfig | Select-String "IPv4"
# Example: 192.168.1.100
```

### 4.3 Flutter Setup
```powershell
# Get dependencies
flutter pub get

# Update API URL
# Find: lib/config/api_config.dart or similar
# Update:
const String API_BASE_URL = "http://YOUR_IP:3000/api";
```

### 4.4 Run Mobile App

**For React Native/Expo:**
```powershell
# Web version (for testing)
npx expo start --web

# Or Android
npx expo start
# Then scan QR code with Expo Go app

# Or iOS
npx expo start --ios
```

**For Flutter:**
```powershell
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 🔌 Step 5: Backend API Integration

### 5.1 Check Existing Backend
```powershell
cd d:\Trial\HerbalTrace\backend
Get-ChildItem src/
```

Your backend should have:
- ✅ Fabric SDK integration (`src/fabric/fabricClient.ts`)
- ✅ API routes for all endpoints
- ⏳ Needs TypeScript errors fixed

### 5.2 Fix Backend Issues (if needed)
```powershell
cd d:\Trial\HerbalTrace\backend

# Check for errors
npm run build

# If errors exist, review:
# - src/routes/auth.routes.ts
# - src/routes/collection.routes.ts
```

### 5.3 Update Fabric Connection Config
Check blockchain connection settings:
```typescript
// File: backend/src/fabric/fabricClient.ts

// Verify paths match your network:
const ccpPath = path.join(__dirname, '../../../network/organizations/peerOrganizations');
const channelName = 'herbaltrace-channel';
const chaincodeName = 'herbaltrace';
```

### 5.4 Start Backend API
```powershell
cd d:\Trial\HerbalTrace\backend
npm start
# Should run on http://localhost:3000
```

---

## 🧪 Step 6: Test Complete Integration

### 6.1 Test Backend → Blockchain
```powershell
# Test collection event creation
curl -X POST http://localhost:3000/api/collections `
  -H "Content-Type: application/json" `
  -d '{
    "farmerId": "FARMER001",
    "species": "Ashwagandha",
    "quantity": 50,
    "latitude": 28.6139,
    "longitude": 77.2090
  }'
```

### 6.2 Test Web App → Backend
1. Open web app (e.g., http://localhost:3001)
2. Login with test credentials
3. Try creating a harvest/collection event
4. Check browser console for API calls
5. Verify data appears in blockchain

### 6.3 Test Mobile App → Backend
1. Start mobile app on device/emulator
2. Update API URL to your machine's IP
3. Test farmer harvest submission
4. Check if data reaches backend and blockchain

### 6.4 Test End-to-End Flow
```
FARMER (Mobile) → Submit Harvest
     ↓
BACKEND API → Store in Blockchain
     ↓
LAB (Web) → View Pending Collections → Submit Quality Test
     ↓
PROCESSOR (Web) → View Quality-Passed Materials → Process
     ↓
MANUFACTURER (Web) → Create Product → Generate QR Code
     ↓
CONSUMER (Web/Mobile) → Scan QR → View Provenance
```

---

## 🎨 Step 7: UI/UX Customization

### 7.1 Review Current Layouts
Your GitHub apps should have better layouts than the existing ones. Compare:

**Existing Web Portal:**
- `d:\Trial\HerbalTrace\web-portal\src\`

**Your GitHub Web App:**
- `d:\Trial\HerbalTrace\github-web-app\src\`

### 7.2 Merge Features
If you want to keep some features from existing apps:

**Option 1: Component-by-component**
- Copy specific React components from old → new
- Update imports and styling

**Option 2: API integration only**
- Keep your GitHub app's UI completely
- Just update API calls to match backend

### 7.3 Common Customizations

**Branding:**
- Logo: Replace in `public/` or `assets/`
- Colors: Update theme in `tailwind.config.js` or `styles/theme.ts`
- Typography: Update font imports and CSS

**New Features to Add:**
If your blockchain supports them, add:
- Real-time notifications (WebSocket)
- Map visualization of farms
- QR code scanner component
- Analytics dashboard
- Export reports (PDF/Excel)

---

## 📊 Step 8: Verify Blockchain Data Flow

### 8.1 Check Chaincode Functions Available
```powershell
# Review what transactions are supported
Get-Content d:\Trial\HerbalTrace\chaincode\herbaltrace\main.go | Select-String "func.*Contract"
```

Available functions (from your chaincode):
- `CreateCollectionEvent`
- `GetCollectionEvent`
- `QueryCollectionsByFarmer`
- `QueryCollectionsBySpecies`
- `CreateQualityTest`
- `GetQualityTest`
- `CreateProcessingStep`
- `GetProcessingStep`
- `CreateProduct`
- `GetProduct`
- `GetProductByQRCode`
- `GenerateProvenance`
- `GetProvenanceByQRCode`

### 8.2 Ensure Frontend Matches Backend
Your web/mobile apps should call endpoints that invoke these chaincode functions through the backend API.

### 8.3 Test Each Role's Workflow

**Farmer App:**
```javascript
// Should call:
POST /api/collections → CreateCollectionEvent
GET /api/collections/farmer/:id → QueryCollectionsByFarmer
```

**Lab Dashboard:**
```javascript
// Should call:
POST /api/quality-tests → CreateQualityTest
GET /api/quality-tests/:id → GetQualityTest
```

**Processor Dashboard:**
```javascript
// Should call:
POST /api/processing → CreateProcessingStep
GET /api/processing/:id → GetProcessingStep
```

**Manufacturer Dashboard:**
```javascript
// Should call:
POST /api/products → CreateProduct
GET /api/products/qr/:qrcode → GetProductByQRCode
```

---

## 🚀 Step 9: Production Deployment Prep

### 9.1 Environment Variables
Create `.env` files for each app:

**Backend:**
```env
PORT=3000
NODE_ENV=production
BLOCKCHAIN_CHANNEL=herbaltrace-channel
BLOCKCHAIN_CHAINCODE=herbaltrace
```

**Web App:**
```env
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_ENV=production
```

**Mobile App:**
```env
API_BASE_URL=https://api.yourdomain.com
ENV=production
```

### 9.2 Build for Production

**Backend:**
```powershell
cd backend
npm run build
npm run start:prod
```

**Web App:**
```powershell
cd github-web-app
npm run build
# Output in build/ or dist/
```

**Mobile App (React Native):**
```powershell
# Android
cd android
.\gradlew assembleRelease

# iOS
cd ios
pod install
xcodebuild -workspace App.xcworkspace -scheme App -configuration Release
```

**Mobile App (Flutter):**
```powershell
flutter build apk --release
flutter build ios --release
```

---

## 🔍 Troubleshooting

### Issue 1: "Cannot connect to blockchain"
**Solution:**
```powershell
# Check if all containers are running
docker ps | Select-String herbaltrace

# Check CLI container logs
docker logs cli

# Restart network
cd d:\Trial\HerbalTrace\network\docker
docker-compose -f docker-compose-herbaltrace.yaml restart
```

### Issue 2: "API returning 404"
**Solution:**
- Check backend is running: `http://localhost:3000/health`
- Verify API routes in backend code
- Check CORS settings in backend

### Issue 3: "Mobile app can't reach API"
**Solution:**
- Use machine IP, not localhost
- Check firewall allows port 3000
- Ensure mobile device on same network

### Issue 4: "Chaincode not found"
**Solution:**
```powershell
# Check chaincode installation
docker exec cli peer chaincode list --installed

# Reinstall if needed
cd d:\Trial\HerbalTrace\network
.\deploy-network.sh deployChaincode
```

### Issue 5: "Frontend shows old data"
**Solution:**
- Clear browser cache
- Check if API is returning updated data
- Verify blockchain transaction was committed

---

## 📝 Next Steps Checklist

- [ ] Blockchain network fully operational (channel + chaincode)
- [ ] Backend API compiling without errors
- [ ] Backend successfully connects to blockchain
- [ ] Web app cloned from GitHub
- [ ] Web app dependencies installed
- [ ] Web app API URLs configured
- [ ] Web app running successfully
- [ ] Mobile app cloned from GitHub
- [ ] Mobile app dependencies installed
- [ ] Mobile app API URLs configured (using IP, not localhost)
- [ ] Mobile app running successfully
- [ ] Test: Farmer submits harvest → appears in blockchain
- [ ] Test: Lab submits quality test → links to harvest
- [ ] Test: Processor creates processing step
- [ ] Test: Manufacturer creates product + QR code
- [ ] Test: Consumer scans QR → sees provenance
- [ ] UI/UX reviewed and customized as needed
- [ ] All roles tested end-to-end
- [ ] Production deployment plan ready

---

## 📞 Ready to Integrate?

**Provide me with:**
1. ✅ Your GitHub repository URLs (web app + mobile app)
2. ✅ What framework they use (React, Flutter, etc.)
3. ✅ Any specific features you want to add/modify

**I will:**
1. Clone and analyze your apps
2. Configure API integration
3. Test blockchain connectivity
4. Ensure end-to-end workflow works
5. Suggest UI/UX improvements

**Let's get your beautiful GitHub apps integrated with this working blockchain! 🚀**
