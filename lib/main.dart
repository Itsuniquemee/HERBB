import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/location_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/farmer/providers/collection_provider.dart';
import 'features/consumer/providers/scan_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await StorageService.init();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check developer mode before running app
  bool devModeEnabled = await DeveloperModeUtils.isDeveloperModeOn();
  if (devModeEnabled) {
    runApp(const DeveloperModeBlockedApp());
  } else {
    runApp(const HerbalTraceApp());
  }
}

// ------------------- Developer Mode Utils -------------------
class DeveloperModeUtils {
  static const MethodChannel _channel = MethodChannel('com.herbaltrace.dev_mode_check');

  static Future<bool> isDeveloperModeOn() async {
    if (Platform.isAndroid) return false;
    try {
      final bool result = await _channel.invokeMethod('isDeveloperModeOn');
      return result;
    } catch (e) {
      return false;
    }
  }
}

// ------------------- Developer Mode Blocked App -------------------
class DeveloperModeBlockedApp extends StatelessWidget {
  const DeveloperModeBlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerbalTrace',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.block, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Developer Mode is enabled.\nThe app cannot run.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- Main App -------------------
class HerbalTraceApp extends StatelessWidget {
  const HerbalTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        Provider(create: (_) => SyncService()),
        Provider(create: (_) => LocationService()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'HerbalTrace',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            onGenerateRoute: AppRouter.generateRoute,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
