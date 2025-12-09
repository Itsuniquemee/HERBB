import 'package:flutter_test/flutter_test.dart';
import 'package:herbal_trace/core/models/collection_event.dart';

void main() {
  group('CollectionEvent Model Tests', () {
    test('CollectionEvent should be created with required fields', () {
      final event = CollectionEvent(
        id: 'test-id-123',
        farmerId: 'farmer-1',
        species: 'Ashwagandha',
        latitude: 28.6139,
        longitude: 77.2090,
        imagePaths: ['path/to/image1.jpg'],
        timestamp: DateTime(2024, 1, 1),
      );

      expect(event.id, 'test-id-123');
      expect(event.farmerId, 'farmer-1');
      expect(event.species, 'Ashwagandha');
      expect(event.latitude, 28.6139);
      expect(event.longitude, 77.2090);
      expect(event.imagePaths.length, 1);
      expect(event.isSynced, false);
    });

    test('CollectionEvent should serialize to JSON', () {
      final event = CollectionEvent(
        id: 'test-id-123',
        farmerId: 'farmer-1',
        species: 'Tulsi',
        latitude: 28.6139,
        longitude: 77.2090,
        imagePaths: ['path/to/image1.jpg'],
        weight: 10.5,
        timestamp: DateTime(2024, 1, 1),
      );

      final json = event.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['species'], 'Tulsi');
      expect(json['weight'], 10.5);
      expect(json['isSynced'], false);
    });

    test('CollectionEvent should deserialize from JSON', () {
      final json = {
        'id': 'test-id-123',
        'farmerId': 'farmer-1',
        'species': 'Neem',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'imagePaths': ['path/to/image1.jpg', 'path/to/image2.jpg'],
        'weight': 15.0,
        'moisture': 12.5,
        'quality': 'Premium',
        'notes': 'Good quality harvest',
        'timestamp': '2024-01-01T10:00:00.000Z',
        'isSynced': true,
        'blockchainHash': 'abc123hash',
      };

      final event = CollectionEvent.fromJson(json);

      expect(event.id, 'test-id-123');
      expect(event.species, 'Neem');
      expect(event.weight, 15.0);
      expect(event.moisture, 12.5);
      expect(event.quality, 'Premium');
      expect(event.isSynced, true);
      expect(event.blockchainHash, 'abc123hash');
      expect(event.imagePaths.length, 2);
    });
  });
}
