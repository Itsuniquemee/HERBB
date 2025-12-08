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
  int _selectedIndex = 0;
  bool _toggleNewCollection = false;


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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D5F3F),
              Color(0xFFF5F5DC),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/leaf_pattern.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.1,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Header
                _buildTopHeader(themeProvider, localeProvider),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => collectionProvider.loadEvents(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Welcome Card
                          _buildWelcomeCard(authProvider, localeProvider),

                          const SizedBox(height: 24),
                          // _buildFriendCard(authProvider, localeProvider),
                          _buildFriendCard(authProvider, localeProvider, context),


                          const SizedBox(height: 24),

                          // Content area with cream background
                          Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 252, 252, 252),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Statistics Section
                                  _buildStatsSection(stats, localeProvider),

                                  const SizedBox(height: 32),

                                  // Recent Submissions
                                  _buildRecentSubmissions(stats, localeProvider, context),

                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(localeProvider),
    );
  }

  Widget _buildTopHeader(
      ThemeProvider themeProvider, LocaleProvider localeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 255, 255, 255),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              localeProvider.translate('Dashboard'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 255, 255, 255),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),




            // Switch(
            //   value: _toggleNewCollection,
            //   activeColor: Colors.white,
            //   onChanged: (value) {
            //     setState(() {
            //       _toggleNewCollection = value;
            //     });
            //
            //     if (value) {
            //       Navigator.of(context).pushNamed(AppRouter.newCollection).then((_) {
            //         setState(() {
            //           _toggleNewCollection = false; // Reset toggle after return
            //         });
            //       });
            //     }
            //   },
            // ),




            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode_outlined,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.language,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: () => localeProvider.toggleLanguage(),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
      AuthProvider authProvider, LocaleProvider localeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  authProvider.currentUser?.name.substring(0, 1).toUpperCase() ??
                      'A',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F3F),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Welcome text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localeProvider.isHindi ? 'नमस्ते' : 'Welcome',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.currentUser?.name ?? 'Farmer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco,
                    size: 16,
                    color: Color(0xFF2D5F3F),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '85',
                    style: TextStyle(
                      color: Color(0xFF2D5F3F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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


  Widget _buildFriendCard(
      AuthProvider authProvider, LocaleProvider localeProvider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(AppRouter.farmerfreind);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          // Only a text in the center
          child: Center(
            child: Text(
              localeProvider.isHindi ? "किसान मित्र" : "Farmer Friend",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5F3F),
              ),
            ),
          ),
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
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 20),
        // 2x2 Grid of stat cards
        Row(
          children: [
            Expanded(
              child: _buildStatCardNew(
                title: localeProvider.translate('synced'),
                value: stats['syncedCount'].toString(),
                mainIcon: Icons.cloud_done_rounded,
                trendIcon: Icons.trending_up,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCardNew(
                title: localeProvider.translate('pending'),
                value: stats['pendingCount'].toString(),
                mainIcon: Icons.cloud_upload_rounded,
                trendIcon: Icons.trending_flat,
                color: const Color(0xFFFFA726),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCardNew(
                title: localeProvider.isHindi ? 'कुल वजन' : 'Total Weight',
                value: '${stats['totalWeight'].toStringAsFixed(1)} kg',
                mainIcon: Icons.scale_rounded,
                trendIcon: Icons.trending_up,
                color: const Color(0xFF29B6F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCardNew(
                title: localeProvider.translate('rewards'),
                value: '1,240',
                mainIcon: Icons.star_rounded,
                trendIcon: Icons.trending_up,
                color: const Color(0xFFFFB74D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCardNew({
    required String title,
    required String value,
    required IconData mainIcon,
    required IconData trendIcon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mainIcon,
                  color: color,
                  size: 28,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  trendIcon,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSubmissions(
      Map<String, dynamic> stats, LocaleProvider localeProvider, BuildContext context) {
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
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.submissionHistory);
              },
              child: Text(
                localeProvider.isHindi ? 'सभी देखें' : 'View All',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5F3F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            if (recentSubmissions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 72,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localeProvider.isHindi
                          ? 'कोई सबमिशन नहीं'
                          : 'No submissions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentSubmissions.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SubmissionCard(
                      event: event,
                      localeProvider: localeProvider,
                    ),
                  )),
            // Floating Action Button
            Positioned(
              bottom: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                shadowColor: const Color(0xFF2D5F3F).withOpacity(0.4),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRouter.newCollection);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D5F3F), Color(0xFF3D7F5F)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localeProvider.translate('new_collection'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildBottomNav(LocaleProvider localeProvider) {
    double width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 70,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom bar background
          Container(
            height: 70,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT SECTION (2 items)
                  Row(
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard_rounded,
                        label: localeProvider.translate('dashboard'),
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _buildNavItem(
                        icon: Icons.list_alt_rounded,
                        label: localeProvider.translate('submissions'),
                        isSelected: _selectedIndex == 1,
                        onTap: () {
                          setState(() => _selectedIndex = 1);
                          Navigator.pushNamed(
                              context, AppRouter.submissionHistory);
                        },
                      ),
                    ],
                  ),

                  // RIGHT SECTION (2 items)
                  Row(
                    children: [
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: localeProvider.translate('profile'),
                        isSelected: _selectedIndex == 3,
                        onTap: () {
                          setState(() => _selectedIndex = 3);
                          Navigator.pushNamed(
                              context, AppRouter.farmerProfile);
                        },
                      ),
                      _buildNavItem(
                        icon: Icons.report_problem_rounded,
                        label: localeProvider.translate('Complaint'),
                        isSelected: _selectedIndex == 4,
                        onTap: () {
                          setState(() => _selectedIndex = 4);
                          Navigator.pushNamed(
                              context, AppRouter.registercomplaint);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Floating CENTER BUTTON (Always Centered)
          // Floating CENTER BUTTON (Always Centered)
          Positioned(
            top: -28,
            left: 20,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pushNamed(context, AppRouter.newCollection);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.add, size: 34, color: Colors.white),
                ),
              ),
            ),
          ),

// Floating Button Label (Exactly under Button)
          Positioned(
            top: 46,  // sits just under the button
            left: 20,
            right: 0,
            child: Center(
              child: Text(
                // localeProvider.translate('New Collection'),
                localeProvider.isHindi ? "नया संग्रह" : "New Collection",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _selectedIndex == 2
                      ? AppTheme.primaryGreen
                      : Colors.grey[600],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D5F3F).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF2D5F3F)
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2D5F3F)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
