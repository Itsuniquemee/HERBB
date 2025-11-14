# ✅ HerbalTrace - Setup Checklist

Use this checklist to ensure your app is properly configured and ready to run!

---

## 🔧 Prerequisites

- [ ] Flutter SDK 3.0+ installed
- [ ] Dart 3.0+ installed  
- [ ] VS Code or Android Studio installed
- [ ] Android SDK / iOS SDK installed
- [ ] Git installed (optional)
- [ ] Device/Emulator ready

**Verify:** Run `flutter doctor` and fix any issues marked with ❌

---

## 📦 Initial Setup

- [ ] Navigate to project: `cd d:\HerbalTrace`
- [ ] Install dependencies: `flutter pub get`
- [ ] Generate Hive adapters: `flutter pub run build_runner build`
- [ ] Verify no errors in terminal

---

## 🗺️ Google Maps Setup (Optional for Demo)

### Android
- [ ] Get Google Maps API key from Google Cloud Console
- [ ] Enable Maps SDK for Android
- [ ] Open `android/app/src/main/AndroidManifest.xml`
- [ ] Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual key

### iOS (if building for iOS)
- [ ] Enable Maps SDK for iOS
- [ ] Add API key to `ios/Runner/AppDelegate.swift`
- [ ] Add: `GMSServices.provideAPIKey("YOUR_KEY")`

**Note:** Maps will show placeholder until configured

---

## 🔌 Backend API Setup (Optional for Demo)

- [ ] Open `lib/core/services/sync_service.dart`
- [ ] Replace API URL:
  ```dart
  static const String apiBaseUrl = 'https://your-api-url.com';
  ```
- [ ] Implement authentication endpoint
- [ ] Implement collection events endpoint
- [ ] Implement provenance endpoint
- [ ] Implement scan recording endpoint

**Note:** App works in demo mode without backend

---

## 🎨 Font Setup (Optional Enhancement)

- [ ] Download Poppins font family from Google Fonts
- [ ] Create `assets/fonts/` directory
- [ ] Add Poppins font files:
  - Poppins-Regular.ttf
  - Poppins-Medium.ttf
  - Poppins-SemiBold.ttf
  - Poppins-Bold.ttf
- [ ] Fonts already declared in `pubspec.yaml`

**Note:** App will use system font if Poppins not available

---

## 📱 Platform Configuration

### Android
- [ ] Check `android/app/src/main/AndroidManifest.xml` permissions
- [ ] Verify package name: `com.herbaltrace.app`
- [ ] Check minSdkVersion: 21
- [ ] Check targetSdkVersion: 34

### iOS
- [ ] Check `ios/Runner/Info.plist` permissions
- [ ] Verify bundle identifier
- [ ] Check deployment target: iOS 12.0+

---

## 🧪 Testing

- [ ] Connect device or start emulator
- [ ] Run: `flutter devices` (verify device detected)
- [ ] Run: `flutter run`
- [ ] Wait for app to build and install

### Test Farmer Flow
- [ ] Login with any email/password
- [ ] Select "Farmer" role
- [ ] Dashboard loads correctly
- [ ] Click "New Collection"
- [ ] GPS captures location (wait 5-10 seconds)
- [ ] Tap "Capture Image"
- [ ] Grant camera permission
- [ ] Take photo successfully
- [ ] Select species (try autocomplete)
- [ ] Fill in weight, moisture, quality
- [ ] Submit event
- [ ] See success acknowledgement
- [ ] Return to dashboard
- [ ] Event appears in "Recent Submissions"
- [ ] Navigate to "Submission History"
- [ ] Event shows with "Pending" badge

### Test Consumer Flow
- [ ] Logout (from profile)
- [ ] Login again
- [ ] Select "Consumer" role
- [ ] Dashboard loads correctly
- [ ] Click "Scan QR" (or FAB button)
- [ ] Grant camera permission
- [ ] Scanner opens with frame overlay
- [ ] (Skip actual scan for now)
- [ ] Test dark mode toggle (top right)
- [ ] Test language toggle (top right)

---

## 🌙 Theme Testing

- [ ] Open any screen
- [ ] Tap moon/sun icon in app bar
- [ ] Theme switches to dark/light
- [ ] All screens look good in both themes
- [ ] Preference persists after app restart

---

## 🌍 Language Testing

- [ ] Tap language icon (🌍)
- [ ] UI switches to Hindi (हिंदी)
- [ ] All labels translate correctly
- [ ] Tap again to switch back to English
- [ ] Preference persists after app restart

---

## 💾 Offline Testing

### Farmer Offline
- [ ] Enable airplane mode
- [ ] Create new collection event
- [ ] Submit successfully
- [ ] Event saved locally
- [ ] Shows "Pending" sync status
- [ ] Disable airplane mode
- [ ] Wait for auto-sync (or trigger manually)
- [ ] Event updates to "Synced" (in demo mode, may stay pending)

### Consumer Offline
- [ ] Scan a QR once (while online)
- [ ] View provenance data
- [ ] Enable airplane mode
- [ ] Navigate away and back
- [ ] Cached data still loads
- [ ] Offline indicator shows (if implemented)

---

## 🔍 Error Handling Testing

- [ ] Try invalid form submission (empty fields)
- [ ] See validation errors
- [ ] Try submitting without GPS
- [ ] See error message
- [ ] Try submitting without images
- [ ] See error message
- [ ] Test with poor network
- [ ] See appropriate loading states

---

## 📊 Performance Testing

- [ ] Run in profile mode: `flutter run --profile`
- [ ] Navigate between screens
- [ ] Check animations are smooth (60fps)
- [ ] Test with multiple events in history
- [ ] Scroll performance is good
- [ ] Images load efficiently

---

## 🏗️ Build Testing

### Android APK
- [ ] Run: `flutter build apk --release`
- [ ] Check `build/app/outputs/flutter-apk/`
- [ ] Install APK on device
- [ ] Test all features
- [ ] App works offline
- [ ] No debug banner

### Android App Bundle
- [ ] Run: `flutter build appbundle --release`
- [ ] Check `build/app/outputs/bundle/release/`
- [ ] Bundle created successfully

---

## 🐛 Common Issues Checklist

If build fails:
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Try again

If camera doesn't work:
- [ ] Check permissions in manifest
- [ ] Test on physical device
- [ ] Grant permission when prompted
- [ ] Restart app

If GPS doesn't capture:
- [ ] Enable location services
- [ ] Test on physical device
- [ ] Grant location permission
- [ ] Check LocationService implementation

If maps don't show:
- [ ] Add Google Maps API key
- [ ] Enable Maps SDK
- [ ] Rebuild app
- [ ] Check internet connection

---

## ✨ Optional Enhancements

- [ ] Add app icon (`flutter_launcher_icons` package)
- [ ] Add splash screen (`flutter_native_splash` package)
- [ ] Set up Firebase (for backend)
- [ ] Add analytics
- [ ] Configure CI/CD
- [ ] Add more tests
- [ ] Implement push notifications
- [ ] Add biometric authentication

---

## 📝 Before Deployment

- [ ] Update app name in `pubspec.yaml`
- [ ] Update package name/bundle ID
- [ ] Add proper app icon
- [ ] Add splash screen
- [ ] Configure proper signing (Android)
- [ ] Configure proper provisioning (iOS)
- [ ] Test on multiple devices
- [ ] Test both orientations
- [ ] Test different screen sizes
- [ ] Review privacy policy
- [ ] Update README with your info

---

## 🎉 Final Checks

- [ ] All features working
- [ ] No console errors
- [ ] Smooth animations
- [ ] Beautiful UI
- [ ] Dark mode working
- [ ] Language toggle working
- [ ] Offline mode working
- [ ] Camera working
- [ ] GPS working
- [ ] Forms validating
- [ ] Navigation smooth

---

## ✅ Ready to Launch!

Once all boxes are checked, your HerbalTrace app is ready!

### Next Steps:
1. **Demo Mode**: Use as-is for demos and testing
2. **Backend Integration**: Connect to real API
3. **Store Deployment**: Publish to Play Store / App Store
4. **User Testing**: Get feedback from real users
5. **Iterate**: Improve based on feedback

---

## 💡 Tips

- **Save this checklist** - Use it each time you set up on a new machine
- **Test frequently** - Don't wait until the end
- **Read error messages** - They usually tell you exactly what's wrong
- **Check documentation** - README.md, SETUP.md have detailed info
- **Ask for help** - Create GitHub issue if stuck

---

## 🆘 Getting Help

If you're stuck:
1. Check error message carefully
2. Search error in documentation
3. Try `flutter clean` and rebuild
4. Check SETUP.md for detailed instructions
5. Review code comments
6. Create GitHub issue with details

---

**Happy building! 🚀**

---

*Last updated: 2024*
*HerbalTrace v1.0.0*
