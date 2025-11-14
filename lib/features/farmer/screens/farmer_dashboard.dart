import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/collection_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/routes/app_router.dart';
import '../widgets/stat_card.dart';
import '../widgets/submission_card.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final collectionProvider = context.watch<CollectionProvider>();

    final stats = collectionProvider.getStatistics();

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
      body: RefreshIndicator(
        onRefresh: () => collectionProvider.loadEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(authProvider, localeProvider),

              const SizedBox(height: 24),

              // Statistics Cards
              _buildStatsSection(stats, localeProvider),

              const SizedBox(height: 24),

              // Recent Submissions
              _buildRecentSubmissions(stats, localeProvider),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(localeProvider),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.newCollection);
        },
        icon: const Icon(Icons.add),
        label: Text(localeProvider.translate('new_collection')),
      ),
      bottomNavigationBar: _buildBottomNav(localeProvider),
    );
  }

  Widget _buildWelcomeHeader(
      AuthProvider authProvider, LocaleProvider localeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: Text(
                authProvider.currentUser?.name.substring(0, 1).toUpperCase() ??
                    'F',
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.name ?? 'Farmer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 16, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text(
                    '85',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
      Map<String, dynamic> stats, LocaleProvider localeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localeProvider.isHindi ? 'सांख्यिकी' : 'Statistics',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: localeProvider.translate('synced'),
                value: stats['syncedCount'].toString(),
                icon: Icons.cloud_done,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: localeProvider.translate('pending'),
                value: stats['pendingCount'].toString(),
                icon: Icons.cloud_upload,
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: localeProvider.isHindi ? 'कुल वजन' : 'Total Weight',
                value: '${stats['totalWeight'].toStringAsFixed(1)} kg',
                icon: Icons.scale,
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: localeProvider.translate('rewards'),
                value: '1,240',
                icon: Icons.star,
                color: AppTheme.earthBrown,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSubmissions(
      Map<String, dynamic> stats, LocaleProvider localeProvider) {
    final recentSubmissions = stats['recentSubmissions'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localeProvider.isHindi ? 'हाल के सबमिशन' : 'Recent Submissions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.submissionHistory);
              },
              child: Text(localeProvider.isHindi ? 'सभी देखें' : 'View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentSubmissions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localeProvider.isHindi
                          ? 'कोई सबमिशन नहीं'
                          : 'No submissions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentSubmissions.map((event) => SubmissionCard(
                event: event,
                localeProvider: localeProvider,
              )),
      ],
    );
  }

  Widget _buildQuickActions(LocaleProvider localeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localeProvider.isHindi ? 'त्वरित क्रियाएं' : 'Quick Actions',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: localeProvider.translate('profile'),
                icon: Icons.person,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.farmerProfile);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: localeProvider.translate('settings'),
                icon: Icons.settings,
                onTap: () {
                  // Navigate to settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(LocaleProvider localeProvider) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryGreen,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: localeProvider.translate('dashboard'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list),
          label: localeProvider.translate('submissions'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: localeProvider.translate('profile'),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            Navigator.of(context).pushNamed(AppRouter.submissionHistory);
            break;
          case 2:
            Navigator.of(context).pushNamed(AppRouter.farmerProfile);
            break;
        }
      },
    );
  }
}
