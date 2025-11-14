import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and Title
                  _buildHeader(localeProvider),

                  const SizedBox(height: 60),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate('email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localeProvider.translate('login'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language Toggle
                  _buildLanguageToggle(localeProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleProvider localeProvider) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco,
            size: 50,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'HerbalTrace',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localeProvider.isHindi
              ? 'जड़ी-बूटियों की ट्रेसेबिलिटी'
              : 'Botanical Traceability',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageToggle(LocaleProvider localeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => localeProvider.toggleLanguage(),
          icon: const Icon(Icons.language),
          label: Text(localeProvider.isHindi ? 'English' : 'हिंदी'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(),
        ),
      );
    }
  }
}
