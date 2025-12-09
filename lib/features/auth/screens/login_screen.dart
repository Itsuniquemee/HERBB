import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/models/user.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Email/Password controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Phone/OTP controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _isLoading = false;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Reset OTP state when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _otpSent = false;
          _isLoading = false;
        });
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                  ]
                : [
                    const Color(0xFF2D5F3F),
                    const Color(0xFFF5F5DC),
                  ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/leaf_pattern.png'),
              repeat: ImageRepeat.repeat,
              opacity: themeProvider.isDarkMode ? 0.05 : 0.1,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo and Title
                  _buildHeader(localeProvider),

                  const SizedBox(height: 40),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: themeProvider.isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(localeProvider.isHindi ? 'ईमेल' : 'Email'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(localeProvider.isHindi ? 'फोन' : 'Phone'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Email/Password Tab
                    _buildEmailLoginTab(localeProvider, authProvider),
                    
                    // Phone/OTP Tab
                    _buildPhoneLoginTab(localeProvider, authProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailLoginTab(LocaleProvider localeProvider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                suffixIcon: Semantics(
                  label: _obscurePassword
                      ? localeProvider.translate('a11y_password_show')
                      : localeProvider.translate('a11y_password_hide'),
                  button: true,
                  child: IconButton(
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localeProvider.isHindi
                      ? 'कृपया अपना पासवर्ड दर्ज करें'
                      : 'Please enter your password';
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  authProvider.errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailLogin,
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
                      localeProvider.translate('login'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: 24),

            // Language Toggle
            _buildLanguageToggle(localeProvider),

            const SizedBox(height: 24),

            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localeProvider.isHindi
                      ? 'खाता नहीं है?'
                      : "Don't have an account?",
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(isSignup: true),
                      ),
                    );
                  },
                  child: Text(
                    localeProvider.isHindi ? 'साइन अप' : 'Sign Up',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLoginTab(LocaleProvider localeProvider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleResendOTP,
                  child: Text(
                    localeProvider.isHindi ? 'OTP पुन: भेजें' : 'Resend OTP',
                  ),
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

            // Language Toggle
            _buildLanguageToggle(localeProvider),

            const SizedBox(height: 24),

            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localeProvider.isHindi
                      ? 'खाता नहीं है?'
                      : "Don't have an account?",
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(isSignup: true),
                      ),
                    );
                  },
                  child: Text(
                    localeProvider.isHindi ? 'साइन अप' : 'Sign Up',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Email Login Handler
  Future<void> _handleEmailLogin() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    bool success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // If login failed and error is about missing user data, ask for role
    if (!success && authProvider.errorMessage?.contains('User data not found') == true) {
      final role = await showDialog<UserRole>(
        context: context,
        builder: (context) => _RoleSelectionDialog(
          localeProvider: context.read<LocaleProvider>(),
        ),
      );

      if (role == null || !mounted) return;

      setState(() => _isLoading = true);

      success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        role,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
    }

    if (success) {
      final role = authProvider.userRole;
      final route = role == UserRole.farmer
          ? AppRouter.farmerDashboard
          : AppRouter.consumerDashboard;

      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  // Phone Login Handlers
  Future<void> _handleSendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;

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
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String otpCode = _otpController.text.trim();

    bool success = await authProvider.verifyOTP(otpCode);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // User is authenticated, navigate to appropriate dashboard
      final role = authProvider.userRole;
      if (role != null) {
        final route = role == UserRole.farmer
            ? AppRouter.farmerDashboard
            : AppRouter.consumerDashboard;
        Navigator.of(context).pushReplacementNamed(route);
      } else {
        // No user data found, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not found. Please sign up first.'),
            backgroundColor: AppTheme.error,
          ),
        );
        // Reset to phone input
        setState(() {
          _otpSent = false;
          _otpController.clear();
        });
      }
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

  Widget _buildHeader(LocaleProvider localeProvider) {
    return Column(
      children: [
        // App Logo
        Image.asset(
          'assets/icons/logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          'Herbal Trace',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localeProvider.isHindi
              ? 'जड़ी-बूटियों की ट्रेसेबिलिटी'
              : 'Botanical Traceability',
          style: const TextStyle(
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
}

// Role Selection Dialog (only shown for web users without Firestore data)
class _RoleSelectionDialog extends StatefulWidget {
  final LocaleProvider localeProvider;

  const _RoleSelectionDialog({required this.localeProvider});

  @override
  State<_RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<_RoleSelectionDialog> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.localeProvider.isHindi 
            ? 'अपनी भूमिका चुनें' 
            : 'Select Your Role',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.localeProvider.isHindi
                ? 'कृपया अपनी भूमिका चुनें'
                : 'Please select your role to complete login',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildRoleOption(
            role: UserRole.farmer,
            title: widget.localeProvider.translate('farmer'),
            icon: Icons.agriculture,
          ),
          const SizedBox(height: 12),
          _buildRoleOption(
            role: UserRole.consumer,
            title: widget.localeProvider.translate('consumer'),
            icon: Icons.qr_code_scanner,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.localeProvider.isHindi ? 'रद्द करें' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRole == null
              ? null
              : () => Navigator.pop(context, _selectedRole),
          child: Text(widget.localeProvider.isHindi ? 'जारी रखें' : 'Continue'),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : (context.watch<ThemeProvider>().isDarkMode
                          ? Colors.white
                          : Colors.black87),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }
}

