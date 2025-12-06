# HerbalTrace - Testing Guide with USB Debugging

**Date:** November 25, 2025  
**Setup:** Physical Android phone via USB debugging

---

## 🚀 STEP-BY-STEP STARTUP GUIDE

### Prerequisites Check ✅

1. **Android Phone Requirements:**
   - USB Debugging enabled in Developer Options
   - USB cable connected to computer
   - Allow file transfer/USB debugging when prompted on phone

2. **Computer Requirements:**
   - Node.js installed (for backend & web portal)
   - Flutter SDK installed
   - Android SDK platform tools installed

---

## 📱 STEP 1: Prepare Your Android Phone

### Enable USB Debugging:

1. **Enable Developer Options:**
   ```
   Settings → About Phone → Tap "Build Number" 7 times
   ```

2. **Enable USB Debugging:**
   ```
   Settings → System → Developer Options → USB Debugging (ON)
   ```

3. **Connect Phone via USB:**
   - Plug USB cable into phone and computer
   - On phone: Select "File Transfer" or "MTP" mode
   - Allow USB debugging when prompted (tap "Always allow from this computer")

4. **Verify Connection:**
   ```powershell
   # Open PowerShell and run:
   flutter devices
   ```
   You should see your phone listed (e.g., "SM-G998B" or similar)

---

## 🎯 STEP 2: Start Backend API Server

```powershell
# Terminal 1 - Backend
cd d:\Trial\HerbalTrace\backend

# Start the backend server
npm run dev
```

**Expected Output:**
```
Server running on http://localhost:3000
Connected to Hyperledger Fabric network
Wallet loaded with 4 admin identities
```

**Troubleshooting:**
- If `npm run dev` doesn't exist, use: `node src/index.js` or `npm start`
- If port 3000 is busy: Kill the process or change port in `.env`

**Keep this terminal running!** ✅

---

## 🌐 STEP 3: Start Web Portal (React)

```powershell
# Terminal 2 - Web Portal
cd d:\Trial\HerbalTrace\web-portal

# Install qrcode package if not installed
npm install qrcode

# Start the web portal
npm run dev
```

**Expected Output:**
```
VITE v5.4.21  ready in 1234 ms

➜  Local:   http://localhost:5173/
➜  Network: http://192.168.x.x:5173/
```

**Note:** Port might be 5173, 3001, or similar. Check the terminal output!

**Keep this terminal running!** ✅

---

## 📱 STEP 4: Configure & Run Flutter App on Phone

### A. Update API URL to Match Your Computer's IP

**Why?** Your phone can't access `localhost` - it needs your computer's actual IP address.

1. **Find Your Computer's IP Address:**
   ```powershell
   # In PowerShell:
   ipconfig
   
   # Look for "IPv4 Address" under your active network adapter
   # Example: 192.168.1.100
   ```

2. **Update Flutter API Config:**
   ```powershell
   # Open the file:
   code d:\Trial\HerbalTrace\mobile-app\lib\core\config\api_config.dart
   ```

3. **Change Line 4:**
   ```dart
   // BEFORE:
   static const String baseUrl = 'http://localhost:3000';
   
   // AFTER (use YOUR computer's IP):
   static const String baseUrl = 'http://192.168.1.100:3000';
   ```
   **Replace `192.168.1.100` with your actual IP from ipconfig!**

### B. Run Flutter App on Phone

```powershell
# Terminal 3 - Flutter App
cd d:\Trial\HerbalTrace\mobile-app

# Verify phone is connected
flutter devices

# Run app on connected phone
flutter run
```

**Expected Output:**
```
Launching lib\main.dart on SM-G998B in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk
Installing app...
Syncing files to device...
```

**The app will automatically install and launch on your phone!** 📱

**Keep this terminal running for hot reload!** ✅

---

## 🧪 STEP 5: Test the Complete Flow

### Test 1: Farmer Creates Collection (Mobile App)

1. **Open App on Your Phone**
2. **Login or Register as Farmer**
   - Email: farmer1@test.com
   - Password: password123
   - Or create new account

3. **Create New Collection:**
   - Tap "New Collection" button
   - Wait for GPS to capture location
   - Tap "Capture Image" (take 1-3 photos)
   - Select species (e.g., "Ashwagandha")
   - Enter weight (e.g., 50 kg)
   - Enter moisture (e.g., 12%)
   - Select quality (e.g., "Grade A")
   - Add notes (optional)
   - Tap "Submit"

4. **Verify Success:**
   - ✅ Success dialog appears with Event ID
   - ✅ Check Terminal 1 (backend) - should show POST request
   - ✅ Go to "Submission History" - collection appears with sync status

### Test 2: Laboratory Tests Collection (Web Portal)

1. **Open Web Browser:**
   ```
   http://localhost:5173
   ```
   (Use the port from Terminal 2 output)

2. **Login as Lab Technician:**
   - Navigate to Laboratory Dashboard
   - Login credentials (check backend for test users)

3. **Create Quality Test:**
   - View "Pending Tests" section
   - Select a farmer's collection
   - Fill quality test form:
     - Purity: 98%
     - Moisture: 11%
     - Contamination: 0.5%
     - Grade: A
   - Submit test

4. **Verify:**
   - ✅ Blockchain TX hash displays
   - ✅ Test appears in "Completed Tests"

### Test 3: Processor Creates Processing Step (Web Portal)

1. **Login as Processor**
2. **Navigate to Processor Dashboard**
3. **View Ready Batches:**
   - See quality-tested collections (Grade A/B/C only)
   
4. **Create Processing Step:**
   - Select a batch
   - Choose process type: "Drying"
   - Temperature: 45°C
   - Duration: 24 hours
   - Humidity: 30%
   - Equipment: "Industrial Dryer #2"
   - Submit

5. **Verify:**
   - ✅ Blockchain TX hash displays
   - ✅ Processed batch appears in history

### Test 4: Manufacturer Creates Product & QR (Web Portal)

1. **Login as Manufacturer**
2. **Navigate to Manufacturer Dashboard**
3. **Create Product:**
   - Product Name: "Organic Ashwagandha Powder"
   - Batch ID: BATCH-001
   - Quantity: 100
   - Certifications: "Organic, GMP"
   - Submit

4. **Generate & Download QR:**
   - ✅ QR code auto-generates
   - Click "Download QR Code"
   - ✅ QR PNG file downloads

### Test 5: Consumer Scans QR (Mobile App)

1. **On Your Phone:**
   - Open HerbalTrace app
   - Navigate to QR Scanner (consumer section)
   - Or tap menu → "Scan Product QR"

2. **Scan QR Code:**
   - Point camera at downloaded QR code (display on computer screen or print)
   - Wait for scan

3. **Verify Provenance:**
   - ✅ Product details display
   - ✅ Full supply chain history shows:
     - Farmer collection
     - Lab quality test
     - Processor step
     - Manufacturer product
   - ✅ Blockchain TX hashes visible

### Test 6: Admin Views Analytics (Web Portal)

1. **Login as Admin**
2. **Navigate to Admin Dashboard**
3. **Check Metrics:**
   - ✅ Total collections, tests, products
   - ✅ Network status (8 peers, 3 orderers online)
   - ✅ Transaction history
   - ✅ Stakeholder analytics

---

## 🔥 Hot Reload for Flutter Development

**While Flutter app is running on phone:**

1. Make changes to Flutter code
2. Press `r` in Terminal 3 for hot reload
3. Press `R` for hot restart
4. Press `q` to quit

**Changes appear instantly on your phone!** 🎉

---

## 🌐 Access Web Portal from Phone (Optional)

If you want to test web portal on your phone browser:

1. **Find computer IP** (from ipconfig): e.g., 192.168.1.100
2. **Note web portal port** (from Terminal 2): e.g., 5173
3. **On phone browser, go to:**
   ```
   http://192.168.1.100:5173
   ```

**Both phone and computer must be on same WiFi network!**

---

## ❌ Troubleshooting Common Issues

### Issue 1: Phone Not Detected by Flutter

**Solution:**
```powershell
# Kill and restart adb server
adb kill-server
adb start-server
adb devices

# Should show your phone
```

### Issue 2: App Can't Connect to Backend

**Problem:** API calls failing, "Network Error"

**Solution:**
1. Verify backend is running (Terminal 1)
2. Check `api_config.dart` has correct IP (not localhost)
3. Ensure phone and computer on same WiFi network
4. Disable Windows Firewall temporarily for testing
5. Restart backend server

### Issue 3: Web Portal Won't Start

**Solution:**
```powershell
cd web-portal

# Clear node modules and reinstall
rm -r node_modules
rm package-lock.json
npm install

# Try again
npm run dev
```

### Issue 4: Backend Can't Connect to Blockchain

**Solution:**
```powershell
# Check if Fabric network is running
cd d:\Trial\HerbalTrace\network
docker ps

# Should show 8 peers, 3 orderers, 1 CA

# If not running, start network:
.\network.sh up
```

### Issue 5: Flutter Build Errors

**Solution:**
```powershell
cd mobile-app

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📊 Monitoring in Real-Time

### Terminal 1 (Backend):
Watch for:
- `POST /api/collections` (farmer creates collection)
- `POST /api/quality-tests` (lab test)
- `POST /api/processing` (processor)
- `POST /api/products` (manufacturer)
- Blockchain TX IDs in responses

### Terminal 2 (Web Portal):
- Shows file changes and hot module replacement
- No need to refresh browser!

### Terminal 3 (Flutter):
- Shows build progress
- Prints app console logs
- Hot reload ready

---

## 🎯 Quick Command Reference

```powershell
# Find Computer IP
ipconfig

# Check Phone Connection
flutter devices
adb devices

# Start Backend
cd d:\Trial\HerbalTrace\backend
npm run dev

# Start Web Portal
cd d:\Trial\HerbalTrace\web-portal
npm run dev

# Run Flutter App on Phone
cd d:\Trial\HerbalTrace\mobile-app
flutter run

# Hot Reload (in Flutter terminal)
r      # Hot reload
R      # Hot restart
q      # Quit

# Kill ADB and Restart
adb kill-server
adb start-server
```

---

## ✅ Success Checklist

Before testing, verify:

- [ ] Phone connected via USB
- [ ] USB debugging enabled
- [ ] `flutter devices` shows phone
- [ ] Backend running on Terminal 1 (port 3000)
- [ ] Web portal running on Terminal 2 (port 5173)
- [ ] Flutter app running on phone (Terminal 3)
- [ ] `api_config.dart` has computer's IP (not localhost)
- [ ] Phone and computer on same WiFi

---

## 🚀 You're Ready to Test!

All three components should be running:
1. ✅ Backend API (localhost:3000)
2. ✅ Web Portal (localhost:5173)
3. ✅ Flutter App (on your phone via USB)

**Happy Testing!** 🎉

---

## 📞 Quick Reference URLs

- **Backend API:** http://localhost:3000
- **Web Portal:** http://localhost:5173 (or check Terminal 2)
- **API from Phone:** http://YOUR_IP:3000 (e.g., http://192.168.1.100:3000)
- **Web from Phone:** http://YOUR_IP:5173 (optional)

**Need Help?** Check the troubleshooting section above!
