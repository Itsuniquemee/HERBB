import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/routes/app_router.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String batchId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = context.read<AuthProvider>();
    final scanProvider = context.read<ScanProvider>();
    final syncService = context.read<SyncService>();

    await scanProvider.scanQRCode(
      batchId,
      authProvider.currentUser?.id ?? '',
      syncService,
    );

    if (!mounted) return;

    if (scanProvider.error == null) {
      // Navigate to provenance viewer
      Navigator.of(context).pushReplacementNamed(
        AppRouter.provenanceViewer,
        arguments: {'batchId': batchId},
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanProvider.error!),
          backgroundColor: AppTheme.error,
        ),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleScan(barcodes.first.rawValue!);
              }
            },
          ),

          // Scanner Overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Semantics(
                    label: localeProvider.translate('a11y_nav_back'),
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      localeProvider.translate('scan_qr'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Semantics(
                    label: localeProvider.translate('a11y_flash_on'),
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      onPressed: () => controller.toggleTorch(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    localeProvider.isHindi
                        ? 'QR कोड को फ्रेम में रखें'
                        : 'Position QR code within the frame',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Scanner Overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const cutOutSize = 300.0;
    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final cutOutRect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);

    // Draw the overlay with a transparent square in the middle
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16))),
      ),
      paint,
    );

    // Draw the border
    final borderPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final borderRect =
        RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16));
    canvas.drawRRect(borderRect, borderPaint);

    // Draw corner accents
    final accentPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
        Offset(left, top + cornerLength), Offset(left, top), accentPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLength, top), accentPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + cutOutSize - cornerLength, top),
        Offset(left + cutOutSize, top), accentPaint);
    canvas.drawLine(Offset(left + cutOutSize, top),
        Offset(left + cutOutSize, top + cornerLength), accentPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + cutOutSize - cornerLength),
        Offset(left, top + cutOutSize), accentPaint);
    canvas.drawLine(Offset(left, top + cutOutSize),
        Offset(left + cornerLength, top + cutOutSize), accentPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + cutOutSize - cornerLength, top + cutOutSize),
        Offset(left + cutOutSize, top + cutOutSize), accentPaint);
    canvas.drawLine(Offset(left + cutOutSize, top + cutOutSize - cornerLength),
        Offset(left + cutOutSize, top + cutOutSize), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
