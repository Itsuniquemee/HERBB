import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/routes/app_router.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.isHindi ? 'फोन लॉगिन' : 'Phone Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo
                Image.asset(
                  'assets/icons/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                Text(
                  localeProvider.isHindi
                      ? 'फोन नंबर से लॉगिन करें'
                      : 'Login with Phone Number',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  decoration: InputDecoration(
                    labelText: localeProvider.isHindi ? 'फोन नंबर' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                    hintText: '9876543210',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localeProvider.isHindi
                          ? 'कृपया फोन नंबर दर्ज करें'
                          : 'Please enter phone number';
                    }
                    if (value.length != 10) {
                      return localeProvider.isHindi
                          ? 'कृपया वैध 10 अंकों का फोन नंबर दर्ज करें'
                          : 'Please enter valid 10-digit phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // OTP Field (shown after OTP is sent)
                if (_otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: localeProvider.isHindi ? 'OTP' : 'OTP',
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: '123456',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localeProvider.isHindi
                            ? 'कृपया OTP दर्ज करें'
                            : 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return localeProvider.isHindi
                            ? 'कृपया 6 अंकों का OTP दर्ज करें'
                            : 'Please enter 6-digit OTP';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _handleResendOTP,
                    child: Text(
                      localeProvider.isHindi ? 'OTP पुन: भेजें' : 'Resend OTP',
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Error Message
                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                // Send OTP / Verify OTP Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _handleVerifyOTP : _handleSendOTP),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _otpSent
                              ? (localeProvider.isHindi ? 'OTP सत्यापित करें' : 'Verify OTP')
                              : (localeProvider.isHindi ? 'OTP भेजें' : 'Send OTP'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),

                const SizedBox(height: 24),

                // Back to Email Login
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localeProvider.isHindi
                        ? 'ईमेल से लॉगिन करें'
                        : 'Login with Email',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final phoneNumber = '+91${_phoneController.text.trim()}';
    final success = await authProvider.sendOTP(phoneNumber);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'OTP भेज दिया गया है'
                : 'OTP sent successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.verifyOTP(_otpController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Navigate to appropriate dashboard
      final user = authProvider.currentUser;
      if (user != null) {
        Navigator.of(context).pushReplacementNamed(
          user.role.toString().split('.').last == 'farmer'
              ? AppRouter.farmerDashboard
              : AppRouter.consumerDashboard,
        );
      }
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final phoneNumber = '+91${_phoneController.text.trim()}';
    final success = await authProvider.sendOTP(phoneNumber);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'OTP फिर से भेज दिया गया है'
                : 'OTP resent successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
