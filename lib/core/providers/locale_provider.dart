import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isHindi => _locale.languageCode == 'hi';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final languageCode =
        StorageService.getSetting('languageCode', defaultValue: 'en');
    _locale = Locale(languageCode);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    StorageService.saveSetting('languageCode', locale.languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = isHindi ? const Locale('en') : const Locale('hi');
    StorageService.saveSetting('languageCode', _locale.languageCode);
    notifyListeners();
  }

  String translate(String key) {
    // Simple translation system
    if (!isHindi) return _enTranslations[key] ?? key;
    return _hiTranslations[key] ?? _enTranslations[key] ?? key;
  }

  static const Map<String, String> _enTranslations = {
    // Auth
    'login': 'Login',
    'email': 'Email',
    'password': 'Password',
    'select_role': 'Select Role',
    'farmer': 'Farmer / Collector',
    'consumer': 'Consumer',

    // Farmer Dashboard
    'dashboard': 'Dashboard',
    'new_collection': 'New Collection',
    'submissions': 'Submissions',
    'profile': 'Profile',
    'payment_status': 'Payment Status',
    'sustainability_score': 'Sustainability Score',
    'rewards': 'Rewards',
    'synced': 'Synced',
    'pending': 'Pending',

    // Collection Event
    'species': 'Species',
    'weight': 'Weight (kg)',
    'moisture': 'Moisture %',
    'quality': 'Quality',
    'notes': 'Notes',
    'capture_image': 'Capture Image',
    'gps_location': 'GPS Location',
    'submit': 'Submit',

    // Consumer
    'scan_qr': 'Scan QR Code',
    'provenance': 'Provenance',
    'chain_of_custody': 'Chain of Custody',
    'quality_tests': 'Quality Tests',
    'sustainability_cert': 'Sustainability Certificate',

    // Common
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'settings': 'Settings',
    'logout': 'Logout',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
  };

  static const Map<String, String> _hiTranslations = {
    // Auth
    'login': 'लॉगिन',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'select_role': 'भूमिका चुनें',
    'farmer': 'किसान / संग्रहकर्ता',
    'consumer': 'उपभोक्ता',

    // Farmer Dashboard
    'dashboard': 'डैशबोर्ड',
    'new_collection': 'नया संग्रह',
    'submissions': 'सबमिशन',
    'profile': 'प्रोफ़ाइल',
    'payment_status': 'भुगतान स्थिति',
    'sustainability_score': 'स्थिरता स्कोर',
    'rewards': 'पुरस्कार',
    'synced': 'सिंक किया गया',
    'pending': 'लंबित',

    // Collection Event
    'species': 'प्रजाति',
    'weight': 'वजन (किलो)',
    'moisture': 'नमी %',
    'quality': 'गुणवत्ता',
    'notes': 'नोट्स',
    'capture_image': 'फोटो लें',
    'gps_location': 'जीपीएस स्थान',
    'submit': 'जमा करें',

    // Consumer
    'scan_qr': 'QR कोड स्कैन करें',
    'provenance': 'उत्पत्ति',
    'chain_of_custody': 'हिरासत की श्रृंखला',
    'quality_tests': 'गुणवत्ता परीक्षण',
    'sustainability_cert': 'स्थिरता प्रमाणपत्र',

    // Common
    'save': 'सहेजें',
    'cancel': 'रद्द करें',
    'delete': 'हटाएं',
    'settings': 'सेटिंग्स',
    'logout': 'लॉगआउट',
    'dark_mode': 'डार्क मोड',
    'language': 'भाषा',
  };
}
