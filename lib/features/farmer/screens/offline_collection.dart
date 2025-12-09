import 'package:hive/hive.dart';

part 'offline_collection.g.dart';

@HiveType(typeId: 1)
class OfflineCollection extends HiveObject {
  // Existing fields
  @HiveField(0)
  final String species;
  @HiveField(1)
  final double? weight; // quantity_kg
  @HiveField(2)
  final double? moisture; // This is an input field, not part of API weather
  @HiveField(3)
  final List<String> imagePaths;
  @HiveField(4)
  final double latitude;
  @HiveField(5)
  final double longitude;
  @HiveField(6)
  final double? temperature;
  @HiveField(7)
  final double? humidity;
  @HiveField(8)
  final DateTime timestamp;

  // NEW FIELDS (API Requirements)
  @HiveField(9)
  final String? localName;
  @HiveField(10)
  final String? plantPart;
  @HiveField(11)
  final String? maturityStage;
  @HiveField(12)
  final String? collectionMethod;
  @HiveField(13)
  final String? qualityNotes;
  @HiveField(14)
  final String? soilCondition;
  @HiveField(15)
  final double? altitudeM;
  @HiveField(16)
  final String? locationName;

  // Quality Assessment (4 boolean fields)
  @HiveField(17)
  final bool noPestDamage;
  @HiveField(18)
  final bool properMoisture;
  @HiveField(19)
  final bool clean;
  @HiveField(20)
  final bool correctMaturity;

  OfflineCollection({
    required this.species,
    this.weight,
    this.moisture,
    required this.imagePaths,
    required this.latitude,
    required this.longitude,
    this.temperature,
    this.humidity,
    required this.timestamp,
    // NEW
    this.localName,
    this.plantPart,
    this.maturityStage,
    this.collectionMethod,
    this.qualityNotes,
    this.soilCondition,
    this.altitudeM,
    this.locationName,
    required this.noPestDamage,
    required this.properMoisture,
    required this.clean,
    required this.correctMaturity,
  });
}