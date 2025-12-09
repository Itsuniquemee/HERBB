import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/farmer/screens/farmer_dashboard.dart';
import '../../features/farmer/screens/new_collection_screen.dart';
import '../../features/farmer/screens/register_complaints.dart';
import '../../features/farmer/screens/submission_history_screen.dart';
import '../../features/farmer/screens/farmer_profile_screen.dart';
import '../../features/farmer/screens/farmer-friend.dart';
import '../../features/consumer/screens/consumer_dashboard.dart';
import '../../features/consumer/screens/qr_scanner_screen.dart';
import '../../features/consumer/screens/provenance_viewer_screen.dart';

class AppRouter {
  static const String login = '/';
  static const String roleSelection = '/role-selection';
  static const String farmerDashboard = '/farmer-dashboard';
  static const String newCollection = '/new-collection';
  static const String submissionHistory = '/submission-history';
  static const String farmerProfile = '/farmer-profile';
  static const String consumerDashboard = '/consumer-dashboard';
  static const String qrScanner = '/qr-scanner';
  static const String provenanceViewer = '/provenance-viewer';
  static const String registercomplaint = '/registercomplaint';
  static const String farmerfreind = '/farmerfriend';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen());

      case roleSelection:
        return _buildRoute(const RoleSelectionScreen());

      case farmerfreind:
        return _buildRoute(const FarmerActionPage());

      case farmerDashboard:
        return _buildRoute(const FarmerDashboard());

      case newCollection:
        return _buildRoute(const NewCollectionScreen());

      case submissionHistory:
        return _buildRoute(const SubmissionHistoryScreen());

      case farmerProfile:
        return _buildRoute(const FarmerProfileScreen());

      case registercomplaint:
        return _buildRoute(const ComplainPage());

      case consumerDashboard:
        return _buildRoute(const ConsumerDashboard());

      case qrScanner:
        return _buildRoute(const QRScannerScreen());

      case provenanceViewer:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(ProvenanceViewerScreen(
          batchId: args?['batchId'] ?? '',
        ));

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static PageRoute _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
