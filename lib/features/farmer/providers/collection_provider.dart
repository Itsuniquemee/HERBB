import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/collection_event.dart';
import '../../../core/services/storage_service.dart';

class CollectionProvider extends ChangeNotifier {
  final List<CollectionEvent> _events = [];
  bool _isLoading = false;

  List<CollectionEvent> get events => _events;
  List<CollectionEvent> get syncedEvents =>
      _events.where((e) => e.isSynced).toList();
  List<CollectionEvent> get unsyncedEvents =>
      _events.where((e) => !e.isSynced).toList();
  bool get isLoading => _isLoading;

  CollectionProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events.clear();
      _events.addAll(StorageService.getAllCollectionEvents());
      _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createCollectionEvent({
    required String farmerId,
    required String species,
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
    double? weight,
    double? moisture,
    String? quality,
    String? notes,
  }) async {
    final event = CollectionEvent(
      id: const Uuid().v4(),
      farmerId: farmerId,
      species: species,
      latitude: latitude,
      longitude: longitude,
      imagePaths: imagePaths,
      weight: weight,
      moisture: moisture,
      quality: quality,
      notes: notes,
      timestamp: DateTime.now(),
      isSynced: false,
    );

    await StorageService.saveCollectionEvent(event);
    _events.insert(0, event);
    notifyListeners();

    return event.id;
  }

  Future<void> deleteEvent(String eventId) async {
    await StorageService.deleteCollectionEvent(eventId);
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }

  Future<void> updateSyncStatus(String eventId, String blockchainHash) async {
    await StorageService.markEventAsSynced(eventId, blockchainHash);

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index].isSynced = true;
      _events[index].blockchainHash = blockchainHash;
      notifyListeners();
    }
  }

  Map<String, dynamic> getStatistics() {
    return {
      'totalSubmissions': _events.length,
      'syncedCount': syncedEvents.length,
      'pendingCount': unsyncedEvents.length,
      'totalWeight': _events
          .where((e) => e.weight != null)
          .fold<double>(0, (sum, e) => sum + e.weight!),
      'recentSubmissions': _events.take(5).toList(),
    };
  }
}
