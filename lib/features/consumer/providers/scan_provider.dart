import 'package:flutter/material.dart';
import '../../../core/models/provenance_data.dart';
import '../../../core/services/sync_service.dart';

class ScanProvider extends ChangeNotifier {
  ProvenanceData? _currentProvenance;
  bool _isLoading = false;
  String? _error;
  int _totalScans = 0;
  int _rewardPoints = 0;

  ProvenanceData? get currentProvenance => _currentProvenance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalScans => _totalScans;
  int get rewardPoints => _rewardPoints;

  Future<void> scanQRCode(
      String batchId, String userId, SyncService syncService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Record the scan
      await syncService.recordScan(batchId, userId);

      // Fetch provenance data
      final data = await syncService.fetchProvenanceData(batchId);

      if (data != null) {
        _currentProvenance = ProvenanceData.fromJson(data);
        _totalScans++;
        _rewardPoints += 10; // Award 10 points per scan
      } else {
        _error = 'Provenance data not found';
      }
    } catch (e) {
      _error = 'Error loading provenance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentProvenance() {
    _currentProvenance = null;
    _error = null;
    notifyListeners();
  }
}
