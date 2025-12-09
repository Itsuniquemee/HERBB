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
    'Complaint' : 'Complaint',

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

    // Accessibility - Icon Buttons
    'a11y_theme_toggle_light': 'Switch to dark mode',
    'a11y_theme_toggle_dark': 'Switch to light mode',
    'a11y_language_toggle_en': 'Switch to Hindi',
    'a11y_language_toggle_hi': 'Switch to English',
    'a11y_voice_input': 'Start voice input',
    'a11y_voice_listening': 'Listening...',
    'a11y_voice_input_for': 'Start voice input for',
    'a11y_delete_image': 'Delete image',
    'a11y_refresh_location': 'Refresh GPS location',
    'a11y_refresh_weather': 'Refresh weather data',
    'a11y_nav_back': 'Navigate back',
    'a11y_password_show': 'Show password',
    'a11y_password_hide': 'Hide password',
    'a11y_flash_on': 'Turn flash on',
    'a11y_flash_off': 'Turn flash off',

    // Accessibility - Status & Indicators
    'a11y_synced_status': 'Synced to cloud',
    'a11y_pending_status': 'Pending upload',
    'a11y_gps_accuracy': 'GPS accuracy',
    'a11y_altitude': 'Altitude',
    'a11y_weather_condition': 'Weather condition',
    'a11y_temperature': 'Temperature',
    'a11y_humidity': 'Humidity',

    // Accessibility - Navigation
    'a11y_nav_selected': 'selected',
    'a11y_nav_not_selected': 'not selected',
    'a11y_nav_button': 'navigation button',
    'a11y_fab_new_collection': 'Add new collection, floating action button',

    // Accessibility - Images & Avatars
    'a11y_profile_avatar': 'Profile picture',
    'a11y_app_logo': 'HerbalTrace application logo',
    'a11y_video_thumbnail': 'Video thumbnail',
    'a11y_tap_to_play': 'Tap to play video',
    'a11y_kishan_mitra_icon': 'Farmer assistance icon',

    // Accessibility - Cards & Actions
    'a11y_stat_card': 'Statistic card',
    'a11y_action_button': 'Action button',
    'a11y_trending_up': 'trending up',
    'a11y_trending_down': 'trending down',
    'a11y_tap_to_open': 'Tap to open',
    'a11y_scan_qr_button': 'Scan QR code button',

    // Accessibility - Form Elements
    'a11y_dropdown_hint': 'Dropdown selector',
    'a11y_required_field': 'Required field',
    'a11y_optional_field': 'Optional field',
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
    'Complaint' : 'शिकायत करो',

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

    // Accessibility - Icon Buttons
    'a11y_theme_toggle_light': 'डार्क मोड में स्विच करें',
    'a11y_theme_toggle_dark': 'लाइट मोड में स्विच करें',
    'a11y_language_toggle_en': 'हिंदी में स्विच करें',
    'a11y_language_toggle_hi': 'अंग्रेज़ी में स्विच करें',
    'a11y_voice_input': 'वॉयस इनपुट शुरू करें',
    'a11y_voice_listening': 'सुन रहे हैं...',
    'a11y_voice_input_for': 'वॉयस इनपुट शुरू करें',
    'a11y_delete_image': 'फोटो हटाएं',
    'a11y_refresh_location': 'जीपीएस लोकेशन रिफ्रेश करें',
    'a11y_refresh_weather': 'मौसम डेटा रिफ्रेश करें',
    'a11y_nav_back': 'वापस जाएं',
    'a11y_password_show': 'पासवर्ड दिखाएं',
    'a11y_password_hide': 'पासवर्ड छुपाएं',
    'a11y_flash_on': 'फ्लैश चालू करें',
    'a11y_flash_off': 'फ्लैश बंद करें',

    // Accessibility - Status & Indicators
    'a11y_synced_status': 'क्लाउड में सिंक किया गया',
    'a11y_pending_status': 'अपलोड लंबित',
    'a11y_gps_accuracy': 'जीपीएस सटीकता',
    'a11y_altitude': 'ऊंचाई',
    'a11y_weather_condition': 'मौसम की स्थिति',
    'a11y_temperature': 'तापमान',
    'a11y_humidity': 'नमी',

    // Accessibility - Navigation
    'a11y_nav_selected': 'चयनित',
    'a11y_nav_not_selected': 'चयनित नहीं',
    'a11y_nav_button': 'नेविगेशन बटन',
    'a11y_fab_new_collection': 'नया संग्रह जोड़ें, फ्लोटिंग एक्शन बटन',

    // Accessibility - Images & Avatars
    'a11y_profile_avatar': 'प्रोफाइल फोटो',
    'a11y_app_logo': 'हर्बल ट्रेस एप्लिकेशन लोगो',
    'a11y_video_thumbnail': 'वीडियो थंबनेल',
    'a11y_tap_to_play': 'वीडियो चलाने के लिए टैप करें',
    'a11y_kishan_mitra_icon': 'किसान सहायता आइकन',

    // Accessibility - Cards & Actions
    'a11y_stat_card': 'सांख्यिकी कार्ड',
    'a11y_action_button': 'एक्शन बटन',
    'a11y_trending_up': 'बढ़ रहा है',
    'a11y_trending_down': 'घट रहा है',
    'a11y_tap_to_open': 'खोलने के लिए टैप करें',
    'a11y_scan_qr_button': 'QR कोड स्कैन बटन',

    // Accessibility - Form Elements
    'a11y_dropdown_hint': 'ड्रॉपडाउन चयनकर्ता',
    'a11y_required_field': 'आवश्यक फ़ील्ड',
    'a11y_optional_field': 'वैकल्पिक फ़ील्ड',
  };
}
