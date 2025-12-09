// lib/providers/collection_provider.dart
import 'package:flutter/material.dart';
import '../../../services/collection_api.dart';

class CollectionProvider with ChangeNotifier {
  // any state you need (loading etc.)
  bool isLoading = false;

  Future<String?> createCollectionEvent({
    required String farmerId,
    required String species,
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
    double? weight,
    double? moisture,
    double? temperature,
    double? humidity,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await CollectionApi.createCollection(
        herbType: species,
        quantity: (weight != null) ? (weight.toInt()) : 0,
        unit: 'kg',
        collectionDate: DateTime.now().toIso8601String().split('T')[0],
        location: '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
        extra: {
          'moisture': moisture,
          'temperature': temperature,
          'humidity': humidity,
          'farmerId': farmerId,
          'imagePaths': imagePaths,
        },
      );

      isLoading = false;
      notifyListeners();
      return result; // event id or null
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
