# HerbalTrace - Quick Start Commands

## Installation

```powershell
# Navigate to project directory
cd d:\HerbalTrace

# Install dependencies
flutter pub get

# Generate code for Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running the App

```powershell
# Run on connected device/emulator
flutter run

# Run in debug mode
flutter run --debug

# Run in profile mode (for performance testing)
flutter run --profile

# Run in release mode
flutter run --release
```

## Testing

```powershell
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## Building

```powershell
# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build for Windows
flutter build windows --release
```

## Code Generation

```powershell
# Generate code (when models change)
flutter pub run build_runner build

# Watch for changes and auto-generate
flutter pub run build_runner watch

# Clean and regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

## Maintenance

```powershell
# Clean build files
flutter clean

# Update dependencies
flutter pub upgrade

# Check for issues
flutter doctor

# Analyze code
flutter analyze
```

## Useful Development Commands

```powershell
# Format all Dart files
flutter format .

# Check outdated packages
flutter pub outdated

# List all connected devices
flutter devices

# Open iOS simulator (macOS only)
open -a Simulator

# Install on specific device
flutter install -d <device_id>
```

## Environment Setup

```powershell
# Check Flutter version
flutter --version

# Check Dart version
dart --version

# Verify Flutter installation
flutter doctor -v
```

## Tips

1. **First time setup**: Always run `flutter pub get` after cloning
2. **After changing models**: Run build_runner to generate code
3. **Performance issues**: Try `flutter clean` then rebuild
4. **Hot reload**: Press `r` in terminal when app is running
5. **Hot restart**: Press `R` in terminal when app is running

## Common Issues

**Issue**: Package not found  
**Solution**: `flutter pub get`

**Issue**: Build fails  
**Solution**: `flutter clean` then `flutter pub get`

**Issue**: Hive errors  
**Solution**: `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: GPS not working  
**Solution**: Test on physical device, emulator GPS is unreliable

## Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Run `flutter pub run build_runner build`
3. ✅ Configure API URL in `lib/core/services/sync_service.dart`
4. ✅ Add Google Maps API key
5. ✅ Run `flutter run`
6. 🎉 Enjoy HerbalTrace!
