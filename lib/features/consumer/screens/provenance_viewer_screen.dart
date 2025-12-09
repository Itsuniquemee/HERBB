import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/scan_provider.dart';
import '../../../core/models/provenance_data.dart';

class ProvenanceViewerScreen extends StatefulWidget {
  final String batchId;

  const ProvenanceViewerScreen({
    super.key,
    required this.batchId,
  });

  @override
  State<ProvenanceViewerScreen> createState() => _ProvenanceViewerScreenState();
}

class _ProvenanceViewerScreenState extends State<ProvenanceViewerScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final scanProvider = context.watch<ScanProvider>();
    final provenance = scanProvider.currentProvenance;

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate('provenance')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: provenance == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Batch Header
                  _buildBatchHeader(provenance, localeProvider),

                  // Map View
                  _buildMapSection(provenance),

                  // Timeline
                  _buildTimeline(provenance, localeProvider),

                  // Quality Tests
                  _buildQualityTests(provenance, localeProvider),

                  // Sustainability Certificate
                  if (provenance.sustainabilityCert != null)
                    _buildSustainabilityCert(provenance, localeProvider),

                  // Chain of Custody
                  _buildChainOfCustody(provenance, localeProvider),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildBatchHeader(
      ProvenanceData provenance, LocaleProvider localeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provenance.collectionEvent.species,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Batch ID: ${provenance.batchId}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  localeProvider.isHindi
                      ? 'ब्लॉकचेन सत्यापित'
                      : 'Blockchain Verified',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(ProvenanceData provenance) {
    final latitude = provenance.collectionEvent.latitude;
    final longitude = provenance.collectionEvent.longitude;

    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('collection'),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: provenance.collectionEvent.species,
                snippet: 'Collection Point',
              ),
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  Widget _buildTimeline(
      ProvenanceData provenance, LocaleProvider localeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localeProvider.isHindi ? 'समयरेखा' : 'Timeline',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Collection Event
          _buildTimelineItem(
            icon: Icons.agriculture,
            title: localeProvider.isHindi ? 'संग्रह' : 'Collection',
            subtitle: provenance.collectionEvent.farmerName,
            date: provenance.collectionEvent.timestamp,
            color: AppTheme.primaryGreen,
            isFirst: true,
          ),

          // Processing Steps
          ...provenance.processingSteps.map((step) => _buildTimelineItem(
                icon: Icons.factory,
                title: step.stepType,
                subtitle: step.facility,
                date: step.timestamp,
                color: AppTheme.secondaryBrown,
              )),

          // Final item
          _buildTimelineItem(
            icon: Icons.inventory_2,
            title: localeProvider.isHindi ? 'पैकेजिंग' : 'Packaging',
            subtitle: localeProvider.isHindi ? 'पूर्ण' : 'Complete',
            date: DateTime.now(),
            color: AppTheme.success,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime date,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityTests(
      ProvenanceData provenance, LocaleProvider localeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localeProvider.translate('quality_tests'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...provenance.qualityTests.map((test) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    test.passed ? Icons.check_circle : Icons.cancel,
                    color: test.passed ? AppTheme.success : AppTheme.error,
                  ),
                  title: Text(test.testType),
                  subtitle: Text(test.result),
                  trailing: Text(
                    DateFormat('MMM dd').format(test.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSustainabilityCert(
      ProvenanceData provenance, LocaleProvider localeProvider) {
    final cert = provenance.sustainabilityCert!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: AppTheme.success.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: AppTheme.success),
                  const SizedBox(width: 12),
                  Text(
                    localeProvider.translate('sustainability_cert'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Type', cert.certType),
              _buildDetailRow('Issuer', cert.issuer),
              _buildDetailRow('Score', '${cert.score}/100'),
              _buildDetailRow(
                  'Issued', DateFormat('MMM dd, yyyy').format(cert.issuedDate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChainOfCustody(
      ProvenanceData provenance, LocaleProvider localeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localeProvider.translate('chain_of_custody'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...provenance.chainOfCustody.transfers.map((transfer) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz,
                      color: AppTheme.primaryGreen),
                  title: Text('${transfer.from} → ${transfer.to}'),
                  subtitle: Text(transfer.location),
                  trailing: Text(
                    DateFormat('MMM dd').format(transfer.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
