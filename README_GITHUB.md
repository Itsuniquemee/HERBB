# 🌿 HerbalTrace - Blockchain-Based Botanical Traceability App

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Android](https://img.shields.io/badge/Android-21+-3DDC84?logo=android)
![iOS](https://img.shields.io/badge/iOS-12.0+-000000?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)

A modern, offline-first Flutter application for tracking Ayurvedic herbs from farm to consumer using blockchain technology. Features dual user roles (Farmer & Consumer) with beautiful nature-inspired UI design.

## 📱 Screenshots

*Coming soon - Add screenshots of your app here*

## ✨ Features

### 🌾 Farmer Features
- **GPS Auto-Capture**: Automatically records harvest location coordinates
- **Multi-Image Capture**: Take 1-3 photos of harvested herbs
- **Species Selection**: Autocomplete for 8 common Ayurvedic herbs
- **Quality Metrics**: Record weight, moisture content, and quality grade
- **Offline-First**: All data saved locally and synced when online
- **Dashboard**: View statistics, pending syncs, and earnings
- **Submission History**: Track all collection events with sync status
- **Blockchain Verification**: Each event gets a unique blockchain hash

### 👤 Consumer Features
- **QR Code Scanner**: Modern mobile scanner for product verification
- **Complete Provenance**: View full product journey from harvest to packaging
- **Interactive Maps**: See exact harvest location on Google Maps
- **Timeline View**: Visual timeline of collection → processing → quality tests
- **Quality Reports**: View all laboratory test results
- **Sustainability Certs**: Check organic and sustainability certifications
- **Chain of Custody**: Track every transfer and handler
- **Reward Points**: Earn points for each scan

### 🎨 UI/UX Features
- **Nature-Inspired Design**: Muted earth tones and soft shadows
- **Dark Mode**: Seamless light/dark theme switching
- **Bilingual Support**: English and Hindi (हिंदी)
- **Smooth Animations**: Beautiful transitions and micro-interactions
- **Material Design 3**: Modern UI components
- **Responsive Layout**: Optimized for all screen sizes

### 🔧 Technical Features
- **Offline-First Architecture**: Works completely offline
- **Background Sync**: Auto-sync when internet returns
- **Local Storage**: Hive NoSQL database for fast, encrypted storage
- **REST API Ready**: Production-ready API integration structure
- **State Management**: Provider for reactive state
- **Network Monitoring**: Real-time connectivity detection
- **Caching Layer**: Smart caching with TTL for API responses

## 🏗️ Architecture

```
lib/
├── core/
│   ├── models/          # Data models (User, CollectionEvent, ProvenanceData)
│   ├── services/        # Business logic (Storage, Sync, Location)
│   ├── providers/       # State management (Theme, Locale, Auth)
│   ├── routes/          # Navigation and routing
│   └── theme/           # App theme and styling
├── features/
│   ├── auth/           # Authentication (Login, Role Selection)
│   ├── farmer/         # Farmer features (Dashboard, Collection, History)
│   └── consumer/       # Consumer features (QR Scanner, Provenance Viewer)
└── main.dart           # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android SDK (API 21+) or iOS 12.0+
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/HerbalTrace.git
cd HerbalTrace
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code (Hive adapters)**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**
```bash
flutter run
```

## 🔧 Configuration

### Google Maps API (Optional for Demo)

1. Get API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### Backend API (Optional for Production)

Update the API base URL in `lib/core/services/sync_service.dart`:
```dart
static const String apiBaseUrl = 'https://your-api-url.com';
```

## 📦 Dependencies

### Core
- **provider** (^6.1.1) - State management
- **hive** (^2.2.3) - Local NoSQL database
- **http** (^1.1.0) - HTTP client

### Features
- **geolocator** (^10.1.0) - GPS location
- **google_maps_flutter** (^2.5.0) - Maps integration
- **mobile_scanner** (^3.5.2) - QR code scanning
- **image_picker** (^1.0.4) - Camera integration
- **connectivity_plus** (^5.0.2) - Network monitoring

### UI
- **cached_network_image** (^3.3.0) - Image caching
- **shimmer** (^3.0.0) - Loading effects
- **lottie** (^2.7.0) - Animations

## 🧪 Testing

### Login (Demo Mode)
- Email: Any email (e.g., `farmer@test.com`)
- Password: Any password (e.g., `test123`)

### Test Flows

**Farmer:**
1. Login → Select "Farmer"
2. Dashboard → Click "New Collection" (+)
3. Wait for GPS (5-10 sec)
4. Tap "Capture Image" → Take photo
5. Select species → Enter metrics
6. Submit → Check history

**Consumer:**
1. Login → Select "Consumer"
2. Dashboard → Click "Scan QR"
3. Grant camera permission
4. Scan or mock scan
5. View provenance data

## 🛠️ Build

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📚 API Endpoints (For Backend Integration)

```
POST   /api/auth/login
POST   /api/collection-events
GET    /api/provenance/:batchId
POST   /api/scans
```

See `SETUP.md` for detailed API specifications.

## 🎨 Color Palette

- **Primary Green**: `#6B9080` - Nature, growth
- **Secondary Brown**: `#A4AC86` - Earth, stability  
- **Accent Sage**: `#87A878` - Herbs, freshness
- **Warm Beige**: `#F2E8CF` - Comfort, natural
- **Earth Brown**: `#BC8B62` - Roots, tradition

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work*

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Ayurvedic herb farmers for inspiration
- Material Design for UI guidelines
- Open source community

## 📞 Support

For support, email your-email@example.com or open an issue.

## 🗺️ Roadmap

- [ ] Real blockchain integration (Ethereum/Polygon)
- [ ] Push notifications for sync events
- [ ] Advanced analytics dashboard
- [ ] Multi-language support (more languages)
- [ ] Farmer community features
- [ ] Payment integration
- [ ] AI-based herb identification
- [ ] Export reports (PDF/Excel)

## 📊 Project Statistics

- **Total Files**: 37+
- **Lines of Code**: 5000+
- **Screens**: 9
- **Features**: 25+
- **Supported Languages**: 2 (English, Hindi)
- **Min Android SDK**: 21 (Android 5.0)
- **Target Android SDK**: 36 (Android 14+)

---

**Made with ❤️ and Flutter**
