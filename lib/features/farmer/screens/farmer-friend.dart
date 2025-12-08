import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';

class FarmerActionPage extends StatelessWidget {
  const FarmerActionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

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
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        localeProvider.translate('Actions'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Content area
                Expanded(
                  child: Container(
                    width: double.infinity,
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
                        children: [
                          _buildActionCard(
                            context,
                            icon: Icons.add_circle_outline,
                            // title: localeProvider.translate('New Collection'),
                            title: localeProvider.isHindi ? "नया संग्रह" : "New Collection",
                            color: const Color(0xFF4CAF50),
                            routeName: AppRouter.newCollection,
                          ),
                          const SizedBox(height: 20),
                          _buildActionCard(
                            context,
                            icon: Icons.folder_open_rounded,
                            // title: localeProvider.translate('View Collection'),
                            title: localeProvider.isHindi ? "संग्रह देखें" : "View Collections",
                            color: const Color(0xFF29B6F6),
                            routeName: AppRouter.submissionHistory,
                          ),
                          const SizedBox(height: 20),
                          _buildActionCard(
                            context,
                            icon: Icons.report_problem_rounded,
                            // title: localeProvider.translate('Raise Complaint'),
                            title: localeProvider.isHindi ? "शिकायत करे" : "Raise Complaint",
                            color: const Color(0xFFFFA726),
                            routeName: AppRouter.registercomplaint,
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
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required String routeName,
      }) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(routeName),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
