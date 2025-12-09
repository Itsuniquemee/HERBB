import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import '../farmer/screens/farmer_dashboard.dart';
import '../consumer/screens/consumer_dashboard.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate after delay
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Prevent multiple navigation attempts
    if (_hasNavigated) return;
    
    // Wait for animation + additional delay
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted || _hasNavigated) return;
    
    _hasNavigated = true;

    final authProvider = context.read<AuthProvider>();
    
    // Check if user was using camera - if so, wait for session restoration
    final cameraActive = await StorageService.getData('camera_active');
    if (cameraActive == 'true') {
      print('DEBUG: Camera was active, waiting for session restoration...');
      // Wait up to 3 seconds for auth to restore
      for (int i = 0; i < 30 && !authProvider.isAuthenticated; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print('DEBUG: Session restoration wait complete, authenticated: ${authProvider.isAuthenticated}');
    }
    
    // Check if user is already logged in
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      // Navigate to appropriate home screen based on role
      final user = authProvider.currentUser!;
      Widget homeScreen;
      
      switch (user.role.toString().split('.').last) {
        case 'farmer':
          homeScreen = const FarmerDashboard();
          break;
        case 'consumer':
          homeScreen = const ConsumerDashboard();
          break;
        default:
          homeScreen = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => homeScreen),
      );
    } else {
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/icons/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                
                const SizedBox(height: 24),
                
                // App Name
                const Text(
                  'Herbal Trace',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline (optional)
                Text(
                  'Track. Verify. Trust.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

