import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/models/user.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class PhoneSignupScreen extends StatefulWidget {
  final UserRole role;

  const PhoneSignupScreen({super.key, required this.role});

  @override
  State<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends State<PhoneSignupScreen> {
  final _loginIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedState;
  bool _otpSent = false;
  bool _isLoading = false;

  final List<String> _statesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  @override
  void dispose() {
    _loginIdController.dispose();
    _nameController.dispose();
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
        title: Text(localeProvider.isHindi ? 'फोन साइन अप' : 'Phone Sign Up'),
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

                // Header
                _buildHeader(localeProvider),

                const SizedBox(height: 40),

                // Login ID Field (only for farmers)
                if (widget.role == UserRole.farmer) ...[
                  TextFormField(
                    controller: _loginIdController,
                    keyboardType: TextInputType.text,
                    enabled: !_otpSent,
                    decoration: InputDecoration(
                      labelText: localeProvider.isHindi ? 'लॉगिन आईडी' : 'Login ID',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localeProvider.isHindi
                            ? 'कृपया लॉगिन आईडी दर्ज करें'
                            : 'Please enter login ID';
                      }
                      if (value.length < 4) {
                        return localeProvider.isHindi
                            ? 'लॉगिन आईडी कम से कम 4 अक्षर की होनी चाहिए'
                            : 'Login ID must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Name Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_otpSent,
                  decoration: InputDecoration(
                    labelText: localeProvider.isHindi ? 'नाम' : 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localeProvider.isHindi
                          ? 'कृपया अपना नाम दर्ज करें'
                          : 'Please enter your name';
                    }
                    if (value.length < 3) {
                      return localeProvider.isHindi
                          ? 'नाम कम से कम 3 अक्षर का होना चाहिए'
                          : 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

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

                // State and Union Territory Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  onChanged: _otpSent ? null : (String? newValue) {
                    setState(() {
                      _selectedState = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: localeProvider.isHindi 
                        ? 'राज्य / केंद्र शासित प्रदेश' 
                        : 'State / Union Territory',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  menuMaxHeight: 300,
                  items: _statesAndUTs.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(
                        state,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localeProvider.isHindi
                          ? 'कृपया राज्य / केंद्र शासित प्रदेश चुनें'
                          : 'Please select state / union territory';
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

                // Send OTP / Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _handleSignup : _handleSendOTP),
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
                              ? (localeProvider.isHindi ? 'साइन अप करें' : 'Sign Up')
                              : (localeProvider.isHindi ? 'OTP भेजें' : 'Send OTP'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),

                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localeProvider.isHindi
                          ? 'पहले से खाता है?'
                          : 'Already have an account?',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        localeProvider.translate('login'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LocaleProvider localeProvider) {
    String roleText;
    IconData roleIcon;

    if (widget.role == UserRole.farmer) {
      roleText = localeProvider.isHindi ? 'किसान पंजीकरण' : 'Farmer Registration';
      roleIcon = Icons.agriculture;
    } else {
      roleText = localeProvider.isHindi ? 'उपभोक्ता पंजीकरण' : 'Consumer Registration';
      roleIcon = Icons.person;
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            roleIcon,
            size: 40,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          roleText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          localeProvider.isHindi
              ? 'फोन नंबर से नया खाता बनाएं'
              : 'Create account with phone number',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
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

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signUpWithPhone(
      phoneNumber: '+91${_phoneController.text.trim()}',
      otp: _otpController.text.trim(),
      name: _nameController.text.trim(),
      role: widget.role,
      loginId: widget.role == UserRole.farmer && _loginIdController.text.trim().isNotEmpty
          ? _loginIdController.text.trim()
          : null,
      state: _selectedState,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Logout after signup to force user to login
      await authProvider.logout();
      
      // Show success message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'साइन अप सफल रहा! कृपया लॉगिन करें'
                : 'Signup successful! Please login',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
