import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../../../core/routes/app_router.dart';

class ConsumerDashboard extends StatelessWidget {
  const ConsumerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final scanProvider = context.watch<ScanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate('dashboard')),
        actions: [
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => localeProvider.toggleLanguage(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                      child: Text(
                        authProvider.currentUser?.name
                                .substring(0, 1)
                                .toUpperCase() ??
                            'C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeProvider.isHindi ? 'नमस्ते' : 'Welcome',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            authProvider.currentUser?.name ?? 'Consumer',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scan QR Card
            _buildScanCard(context, localeProvider),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: localeProvider.isHindi ? 'कुल स्कैन' : 'Total Scans',
                    value: scanProvider.totalScans.toString(),
                    icon: Icons.qr_code_scanner,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: localeProvider.translate('rewards'),
                    value: scanProvider.rewardPoints.toString(),
                    icon: Icons.star,
                    color: AppTheme.earthBrown,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Scans Section
            Text(
              localeProvider.isHindi ? 'हाल के स्कैन' : 'Recent Scans',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localeProvider.isHindi
                            ? 'कोई स्कैन नहीं'
                            : 'No scans yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.qrScanner);
                        },
                        child: Text(localeProvider.isHindi
                            ? 'अभी स्कैन करें'
                            : 'Scan Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.qrScanner);
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(localeProvider.translate('scan_qr')),
      ),
    );
  }

  Widget _buildScanCard(BuildContext context, LocaleProvider localeProvider) {
    return Card(
      color: AppTheme.primaryGreen,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.qrScanner);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localeProvider.translate('scan_qr'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localeProvider.isHindi
                          ? 'उत्पत्ति देखने के लिए स्कैन करें'
                          : 'Scan to view provenance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
