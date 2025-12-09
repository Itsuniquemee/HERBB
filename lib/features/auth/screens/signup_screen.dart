import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/models/user.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final UserRole role;

  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _loginIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedState;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _phoneVerified = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Indian States and Union Territories
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
    
    // Add listener to phone controller to rebuild UI when phone is entered
    _phoneController.addListener(() {
      setState(() {});
    });
    
    // Add listener to OTP controller to rebuild UI when OTP is entered
    _otpController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.isHindi ? 'साइन अप' : 'Sign Up'),
      ),
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
                  const SizedBox(height: 20),

                  // Header
                  _buildHeader(localeProvider),

                  const SizedBox(height: 40),

                  // Login ID Field (only for farmers/collectors)
                  if (widget.role == UserRole.farmer) 
                    TextFormField(
                      controller: _loginIdController,
                      keyboardType: TextInputType.text,
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
                  
                  if (widget.role == UserRole.farmer) 
                    const SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
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
                        return localeProvider.isHindi
                            ? 'कृपया अपना ईमेल दर्ज करें'
                            : 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return localeProvider.isHindi
                            ? 'कृपया एक मान्य ईमेल दर्ज करें'
                            : 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Phone Field with Verify Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_phoneVerified,
                          decoration: InputDecoration(
                            labelText: localeProvider.isHindi ? 'फ़ोन नंबर' : 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            prefixText: '+91 ',
                            suffixIcon: _phoneVerified
                                ? const Icon(Icons.verified, color: AppTheme.primaryGreen)
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localeProvider.isHindi
                                  ? 'कृपया अपना फ़ोन नंबर दर्ज करें'
                                  : 'Please enter your phone number';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return localeProvider.isHindi
                                  ? 'कृपया एक मान्य फ़ोन नंबर दर्ज करें'
                                  : 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!_phoneVerified)
                        SizedBox(
                          width: 100,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _phoneController.text.trim().length != 10) 
                                ? null 
                                : _handleSendOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _otpSent ? Colors.grey : AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading && !_otpSent
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _otpSent 
                                        ? (localeProvider.isHindi ? 'भेजा गया' : 'Sent')
                                        : (localeProvider.isHindi ? 'ओटीपी' : 'Verify'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // OTP Field (shown after OTP is sent)
                  if (_otpSent && !_phoneVerified) ...[
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: localeProvider.isHindi ? 'ओटीपी दर्ज करें' : 'Enter OTP',
                              prefixIcon: const Icon(Icons.lock_outline),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (!_phoneVerified && (value == null || value.isEmpty)) {
                                return localeProvider.isHindi
                                    ? 'कृपया ओटीपी दर्ज करें'
                                    : 'Please enter OTP';
                              }
                              if (!_phoneVerified && value!.length != 6) {
                                return localeProvider.isHindi
                                    ? 'ओटीपी 6 अंकों का होना चाहिए'
                                    : 'OTP must be 6 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _otpController.text.trim().length != 6)
                                ? null
                                : _handleVerifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    localeProvider.isHindi ? 'सत्यापित' : 'Confirm',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleResendOTP,
                        child: Text(
                          localeProvider.isHindi ? 'ओटीपी पुनः भेजें' : 'Resend OTP',
                          style: const TextStyle(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                  ],

                  if (_phoneVerified) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            localeProvider.isHindi 
                                ? 'फ़ोन नंबर सत्यापित' 
                                : 'Phone number verified',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // State and Union Territory Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    isExpanded: true,
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
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedState = newValue;
                      });
                    },
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
                        return localeProvider.isHindi
                            ? 'कृपया पासवर्ड दर्ज करें'
                            : 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return localeProvider.isHindi
                            ? 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए'
                            : 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: localeProvider.isHindi
                          ? 'पासवर्ड की पुष्टि करें'
                          : 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localeProvider.isHindi
                            ? 'कृपया पासवर्ड की पुष्टि करें'
                            : 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return localeProvider.isHindi
                            ? 'पासवर्ड मेल नहीं खाते'
                            : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Error Message
                  if (authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            localeProvider.isHindi ? 'साइन अप' : 'Sign Up',
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
              ? 'नया खाता बनाएं'
              : 'Create a new account',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSendOTP() async {
    // Validate phone number field only
    if (_phoneController.text.trim().isEmpty || _phoneController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'कृपया मान्य फ़ोन नंबर दर्ज करें'
                : 'Please enter valid phone number',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String phoneNumber = '+91${_phoneController.text.trim()}';

    bool success = await authProvider.sendOTP(phoneNumber);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
      }
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: AppTheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'ओटीपी भेजा गया'
                : 'OTP sent successfully',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'कृपया 6 अंकों का ओटीपी दर्ज करें'
                : 'Please enter 6-digit OTP',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String otpCode = _otpController.text.trim();

    // Use verifyOTPForSignup instead of verifyOTP
    bool success = await authProvider.verifyOTPForSignup(otpCode);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Phone verified successfully
      setState(() {
        _phoneVerified = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'फ़ोन नंबर सत्यापित'
                : 'Phone number verified',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Invalid OTP'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    await _handleSendOTP();
  }

  Future<void> _handleSignup() async {
    // Check if phone is verified
    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().isHindi
                ? 'कृपया पहले अपना फ़ोन नंबर सत्यापित करें'
                : 'Please verify your phone number first',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = context.read<AuthProvider>();
      authProvider.clearError();

      // Use email/password signup with verified phone
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: '+91${_phoneController.text.trim()}',
        role: widget.role,
        loginId: widget.role == UserRole.farmer && _loginIdController.text.trim().isNotEmpty
            ? _loginIdController.text.trim()
            : null,
        state: _selectedState,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Logout after signup to force user to login
        await authProvider.logout();
        
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LocaleProvider>().isHindi
                  ? 'साइनअप सफल! कृपया लॉगिन करें'
                  : 'Signup successful! Please login',
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
      // Error is already shown in the UI through authProvider.errorMessage
    }
  }
}
