import 'package:hive/hive.dart';

part 'collection_event.g.dart';

@HiveType(typeId: 0)
class CollectionEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farmerId;

  @HiveField(2)
  final String species;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final List<String> imagePaths;

  @HiveField(6)
  final double? weight;

  @HiveField(7)
  final double? moisture;

  @HiveField(8)
  final String? quality;

  @HiveField(9)
  final String? notes;

  @HiveField(10)
  final DateTime timestamp;

  @HiveField(11)
  bool isSynced;

  @HiveField(12)
  String? blockchainHash;

  CollectionEvent({
    required this.id,
    required this.farmerId,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
    this.weight,
    this.moisture,
    this.quality,
    this.notes,
    required this.timestamp,
    this.isSynced = false,
    this.blockchainHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'species': species,
      'latitude': latitude,
      'longitude': longitude,
      'imagePaths': imagePaths,
      'weight': weight,
      'moisture': moisture,
      'quality': quality,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'blockchainHash': blockchainHash,
    };
  }

  factory CollectionEvent.fromJson(Map<String, dynamic> json) {
    return CollectionEvent(
      id: json['id'],
      farmerId: json['farmerId'],
      species: json['species'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imagePaths: List<String>.from(json['imagePaths']),
      weight: json['weight']?.toDouble(),
      moisture: json['moisture']?.toDouble(),
      quality: json['quality'],
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
      isSynced: json['isSynced'] ?? false,
      blockchainHash: json['blockchainHash'],
    );
  }
}
