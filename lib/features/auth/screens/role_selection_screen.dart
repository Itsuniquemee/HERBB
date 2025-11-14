import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/routes/app_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate('select_role')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Text(
                localeProvider.isHindi
                    ? 'आप किस भूमिका में हैं?'
                    : 'What is your role?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Farmer Role
              _buildRoleCard(
                role: UserRole.farmer,
                title: localeProvider.translate('farmer'),
                subtitle: localeProvider.isHindi
                    ? 'जड़ी-बूटियों का संग्रह करें'
                    : 'Collect and submit herbs',
                icon: Icons.agriculture,
                localeProvider: localeProvider,
              ),

              const SizedBox(height: 20),

              // Consumer Role
              _buildRoleCard(
                role: UserRole.consumer,
                title: localeProvider.translate('consumer'),
                subtitle: localeProvider.isHindi
                    ? 'उत्पत्ति की जानकारी देखें'
                    : 'View product provenance',
                icon: Icons.qr_code_scanner,
                localeProvider: localeProvider,
              ),

              const Spacer(),

              // Continue Button
              ElevatedButton(
                onPressed: _selectedRole == null ? null : _handleContinue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        localeProvider.isHindi ? 'जारी रखें' : 'Continue',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required LocaleProvider localeProvider,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();

    // Simulate login with selected role
    final success = await authProvider.login(
      'demo@herbaltrace.com',
      'password',
      _selectedRole!,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate based on role
      final route = _selectedRole == UserRole.farmer
          ? AppRouter.farmerDashboard
          : AppRouter.consumerDashboard;

      Navigator.of(context).pushReplacementNamed(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
