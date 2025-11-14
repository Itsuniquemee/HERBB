import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/location_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/farmer/providers/collection_provider.dart';
import 'features/consumer/providers/scan_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await StorageService.init();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HerbalTraceApp());
}

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
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
