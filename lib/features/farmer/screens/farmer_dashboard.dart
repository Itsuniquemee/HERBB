import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
              image: const AssetImage('assets/images/leaf_pattern.png'),
              repeat: ImageRepeat.repeat,
              opacity: themeProvider.isDarkMode ? 0.05 : 0.1,
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
                          _buildWelcomeCard(authProvider, localeProvider, themeProvider),

                          const SizedBox(height: 24),
                          
                          // Farmer Friend Card
                          _buildFriendCard(authProvider, localeProvider, context, themeProvider),

                          const SizedBox(height: 24),

                          // Content area with cream background
                          Container(
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFF1A1A1A)
                                  : const Color.fromARGB(255, 252, 252, 252),
                              borderRadius: const BorderRadius.only(
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
                                  _buildStatsSection(stats, localeProvider, themeProvider),

                                  const SizedBox(height: 32),

                                  // Recent Submissions
                                  _buildRecentSubmissions(stats, localeProvider, context, themeProvider),

                                  const SizedBox(height: 32),

                                  // Demo Videos
                                  _buildDemoVideos(localeProvider, themeProvider),

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
      bottomNavigationBar: _buildBottomNav(localeProvider, themeProvider),
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
              child: Semantics(
                label: themeProvider.isDarkMode
                    ? localeProvider.translate('a11y_theme_toggle_dark')
                    : localeProvider.translate('a11y_theme_toggle_light'),
                button: true,
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
            ),
            const SizedBox(width: 10),
            Semantics(
              label: localeProvider.isHindi
                  ? localeProvider.translate('a11y_language_toggle_hi')
                  : localeProvider.translate('a11y_language_toggle_en'),
              button: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => localeProvider.toggleLanguage(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.language,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localeProvider.isHindi ? "English" : "हिन्दी",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildWelcomeCard(
      AuthProvider authProvider, LocaleProvider localeProvider, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? const Color(0xFF2D2D2D)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Semantics(
              label: '${localeProvider.translate('a11y_profile_avatar')}, ${authProvider.currentUser?.name ?? 'Farmer'}',
              image: true,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF3D3D3D)
                      : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      authProvider.currentUser?.name.substring(0, 1).toUpperCase() ??
                          'A',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : const Color(0xFF2D5F3F),
                      ),
                    ),
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
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
                color: themeProvider.isDarkMode
                    ? const Color(0xFF3D3D3D)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco,
                    size: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.green
                        : const Color(0xFF2D5F3F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '85',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.green
                          : const Color(0xFF2D5F3F),
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
      AuthProvider authProvider, LocaleProvider localeProvider, BuildContext context, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Semantics(
        label: localeProvider.isHindi ? "किशन मित्र, ${localeProvider.translate('a11y_action_button')}" : "Kishan Mitra, ${localeProvider.translate('a11y_action_button')}",
        hint: localeProvider.translate('a11y_tap_to_open'),
        button: true,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(AppRouter.farmerfreind);
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: localeProvider.translate('a11y_kishan_mitra_icon'),
                  image: true,
                  child: Image.asset(
                    'assets/images/Kishan Mitra.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.people,
                        size: 40,
                        color: Color(0xFF2D5F3F),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ExcludeSemantics(
                  child: Text(
                    localeProvider.isHindi ? "किशन मित्र" : "Kishan Mitra",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : const Color(0xFF2D5F3F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }













  Widget _buildStatsSection(
      Map<String, dynamic> stats, LocaleProvider localeProvider, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localeProvider.isHindi ? 'सांख्यिकी' : 'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode
                ? Colors.white
                : Colors.black87,
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
                themeProvider: themeProvider,
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
                themeProvider: themeProvider,
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
                themeProvider: themeProvider,
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
                themeProvider: themeProvider,
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
    required ThemeProvider themeProvider,
  }) {
    final localeProvider = context.watch<LocaleProvider>();
    
    return Semantics(
      label: '${localeProvider.translate('a11y_stat_card')}, $title, $value',
      readOnly: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? const Color(0xFF2D2D2D)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.05),
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
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF3D3D3D)
                      : Colors.grey.shade100,
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
          ExcludeSemantics(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecentSubmissions(
      Map<String, dynamic> stats, LocaleProvider localeProvider, BuildContext context, ThemeProvider themeProvider) {
    final recentSubmissions = stats['recentSubmissions'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localeProvider.isHindi ? 'हाल के सबमिशन' : 'Recent Submissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.submissionHistory);
              },
              child: Text(
                localeProvider.isHindi ? 'सभी देखें' : 'View All',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.isDarkMode
                      ? Colors.green
                      : const Color(0xFF2D5F3F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentSubmissions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48.0),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.05),
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
      ],
    );
  }

  Widget _buildDemoVideos(LocaleProvider localeProvider, ThemeProvider themeProvider) {
    final videos = [
      {
        'title': localeProvider.isHindi ? 'डेमो वीडियो 1' : 'Demo Video 1',
        'url': 'https://www.youtube.com/watch?v=iBipXtofx4Y',
        'thumbnail': 'https://img.youtube.com/vi/iBipXtofx4Y/hqdefault.jpg',
      },
      {
        'title': localeProvider.isHindi ? 'डेमो वीडियो 2' : 'Demo Video 2',
        'url': 'https://www.youtube.com/watch?v=r8f-jyPWJz0',
        'thumbnail': 'https://img.youtube.com/vi/r8f-jyPWJz0/hqdefault.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localeProvider.isHindi ? 'डेमो वीडियो' : 'Demo Videos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode
                ? Colors.white
                : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...videos.map((video) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Semantics(
            label: '${localeProvider.translate('a11y_video_thumbnail')}, ${video['title']}, ${localeProvider.translate('a11y_tap_to_play')}',
            button: true,
            child: InkWell(
              onTap: () async {
                try {
                  final Uri url = Uri.parse(video['url']!);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  print('Error launching URL: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localeProvider.isHindi 
                        ? 'वीडियो खोलने में त्रुटि' 
                        : 'Error opening video'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          ExcludeSemantics(
                            child: Image.network(
                              video['thumbnail']!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.play_circle_outline,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Video Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.video_library,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ExcludeSemantics(
                              child: Text(
                                video['title']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            child: Icon(
                              Icons.open_in_new,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }


  Widget _buildBottomNav(LocaleProvider localeProvider, ThemeProvider themeProvider) {
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
              color: themeProvider.isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // LEFT SECTION (2 items)
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: localeProvider.translate('dashboard'),
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    themeProvider: themeProvider,
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
                    themeProvider: themeProvider,
                  ),

                  // CENTER SPACER (for floating button)
                  const SizedBox(width: 60),

                  // RIGHT SECTION (2 items)
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: localeProvider.translate('profile'),
                    isSelected: _selectedIndex == 3,
                    onTap: () {
                      setState(() => _selectedIndex = 3);
                      Navigator.pushNamed(
                          context, AppRouter.farmerProfile);
                    },
                    themeProvider: themeProvider,
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
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ),
          ),

          // Floating CENTER BUTTON (Always Centered)
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: localeProvider.translate('a11y_fab_new_collection'),
                button: true,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pushNamed(context, AppRouter.newCollection);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: themeProvider.isDarkMode
                            ? [const Color(0xFF1A4D2E), const Color(0xFF2D5F3F)]
                            : [const Color(0xFF2D5F3F), const Color(0xFF3D7F5F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (themeProvider.isDarkMode
                                  ? const Color(0xFF1A4D2E)
                                  : const Color(0xFF2D5F3F))
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ExcludeSemantics(
                      child: const Icon(Icons.add, size: 34, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),

// Floating Button Label (Exactly under Button)
          Positioned(
            top: 50,  // increased from 46 to add more space
            left: 0,
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
    required ThemeProvider themeProvider,
  }) {
    final primaryColor =
        themeProvider.isDarkMode ? Colors.green : const Color(0xFF2D5F3F);
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.grey.shade600;
    final localeProvider = context.watch<LocaleProvider>();

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      hint: '${localeProvider.translate('a11y_nav_button')}, ${isSelected ? localeProvider.translate('a11y_nav_selected') : localeProvider.translate('a11y_nav_not_selected')}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? primaryColor : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 3),
              ExcludeSemantics(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryColor : textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
