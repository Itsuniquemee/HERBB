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
  final double? temperature;

  @HiveField(9)
  final double? humidity;

  @HiveField(10)
  final DateTime timestamp;

  @HiveField(11)
  bool isSynced;

  @HiveField(12)
  String? blockchainHash;

  @HiveField(13)
  String? commonName;

  @HiveField(14)
  String? scientificName;

  @HiveField(15)
  String? harvestMethod;

  @HiveField(16)
  String? partCollected;

  @HiveField(17)
  double? altitude;

  @HiveField(18)
  double? latitudeAccuracy;

  @HiveField(19)
  double? longitudeAccuracy;

  @HiveField(20)
  String? locationName;

  @HiveField(21)
  String? soilType;

  @HiveField(22)
  String? notes;

  @HiveField(23)
  String? weatherCondition;

  CollectionEvent({
    required this.id,
    required this.farmerId,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
    this.weight,
    this.moisture,
    this.temperature,
    this.humidity,
    required this.timestamp,
    this.isSynced = false,
    this.blockchainHash,
    this.commonName,
    this.scientificName,
    this.harvestMethod,
    this.partCollected,
    this.altitude,
    this.latitudeAccuracy,
    this.longitudeAccuracy,
    this.locationName,
    this.soilType,
    this.notes,
    this.weatherCondition,
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
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'blockchainHash': blockchainHash,
      'commonName': commonName,
      'scientificName': scientificName,
      'harvestMethod': harvestMethod,
      'partCollected': partCollected,
      'altitude': altitude,
      'latitudeAccuracy': latitudeAccuracy,
      'longitudeAccuracy': longitudeAccuracy,
      'locationName': locationName,
      'soilType': soilType,
      'notes': notes,
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
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      isSynced: json['isSynced'] ?? false,
      blockchainHash: json['blockchainHash'],
      commonName: json['commonName'],
      scientificName: json['scientificName'],
      harvestMethod: json['harvestMethod'],
      partCollected: json['partCollected'],
      altitude: json['altitude']?.toDouble(),
      latitudeAccuracy: json['latitudeAccuracy']?.toDouble(),
      longitudeAccuracy: json['longitudeAccuracy']?.toDouble(),
      locationName: json['locationName'],
      soilType: json['soilType'],
      notes: json['notes'],
    );
  }
}
