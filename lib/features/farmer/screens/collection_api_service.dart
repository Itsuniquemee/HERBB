import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Add mime: ^1.0.0 to your pubspec.yaml
import 'package:http_parser/http_parser.dart';

import '../../auth/providers/auth_provider.dart';
import 'offline_collection.dart'; // Add http_parser: ^4.0.0 to pubspec.yaml

// NOTE: You'll need to define your BASE_URL and import your AuthProvider
// to get the JWT token.

class CollectionProvider extends ChangeNotifier {
  final String _baseUrl = 'YOUR_API_BASE_URL'; // e.g., 'https://api.myapp.com'
  final AuthProvider _authProvider;

  CollectionProvider(this._authProvider);

  Future<String> createCollectionEvent({
    required String farmerId,
    required Map<String, dynamic> data,
    required List<File> imageFiles,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/collections');
    final token = _authProvider.currentUser?.token; // Assuming token is here

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['X-App-Version'] = '1.0.0'
        ..headers['X-Network-Type'] = '4g' // Placeholder
        ..headers['X-GPS-Accuracy'] = '10' // Placeholder (use data['gps_accuracy'] if you track it)
        ..headers['X-Device-Model'] = 'Samsung Galaxy A12'; // Placeholder

      // --- 1. Add String Fields ---
      // The API expects nested fields to be serialized as JSON strings for multipart
      final qualityAssessmentJson = json.encode(data['quality_assessment']);
      final weatherConditionsJson = json.encode(data['weather_conditions']);

      // Add simple string/number fields directly
      request.fields['species'] = data['species'] as String;
      request.fields['local_name'] = data['local_name'] as String;
      request.fields['quantity_kg'] = (data['quantity_kg'] ?? 0.0).toString();
      request.fields['plant_part'] = data['plant_part'] as String;
      request.fields['maturity_stage'] = data['maturity_stage'] as String;
      request.fields['collection_method'] = data['collection_method'] as String;
      request.fields['quality_notes'] = data['quality_notes'] as String;
      request.fields['soil_condition'] = data['soil_condition'] as String;
      request.fields['location_lat'] = (data['location_lat'] as double).toString();
      request.fields['location_lng'] = (data['location_lng'] as double).toString();
      request.fields['altitude_m'] = (data['altitude_m'] ?? 0.0).toString();
      request.fields['location_name'] = data['location_name'] as String;
      request.fields['offline_captured'] = data['offline_captured'].toString();
      request.fields['device_timestamp'] = data['device_timestamp'] as String;

      // Add Moisture from the form field (not in the API's weather object, but useful)
      // We will map it to a simple field 'moisture_percent'
      request.fields['moisture_percent'] = (data['moisture'] ?? 0.0).toString();


      // --- 2. Add Complex JSON Fields as JSON String Parts ---
      // This is often required for multipart forms with complex data
      request.fields['quality_assessment'] = qualityAssessmentJson;
      request.fields['weather_conditions'] = weatherConditionsJson;


      // --- 3. Add File Fields (Images) ---
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        final fileName = file.path.split('/').last;

        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // Use 'images[]' or 'image' if the API expects a single field name for all
            file.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // --- 4. Send Request ---
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          // Return the collection_number
          return jsonResponse['data']['collection_number'] as String;
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- OFFLINE SYNC LOGIC ---

  Future<void> _syncSingleOfflineCollection(OfflineCollection offline) async {
    final token = _authProvider.currentUser?.token;
    if (token == null) return;

    // Convert OfflineCollection back to API data structure
    final data = {
      "species": offline.species,
      "local_name": offline.localName ?? '',
      "quantity_kg": offline.weight,
      "plant_part": offline.plantPart ?? 'unknown',
      "maturity_stage": offline.maturityStage ?? 'unknown',
      "collection_method": offline.collectionMethod ?? 'unknown',
      "quality_assessment": {
        "no_pest_damage": offline.noPestDamage,
        "proper_moisture": offline.properMoisture,
        "clean": offline.clean,
        "correct_maturity": offline.correctMaturity,
      },
      "quality_notes": offline.qualityNotes ?? '',
      "soil_condition": offline.soilCondition ?? 'unknown',
      "location_lat": offline.latitude,
      "location_lng": offline.longitude,
      "altitude_m": offline.altitudeM,
      "location_name": offline.locationName ?? '',
      "weather_conditions": {
        "temperature_c": offline.temperature,
        "humidity_percent": offline.humidity,
        "condition": offline.temperature != null ? "recorded" : "unknown",
      },
      "offline_captured": true, // Mark as offline captured
      "device_timestamp": offline.timestamp.toIso8601String(),
      "moisture": offline.moisture, // Include form-field moisture
    };

    // Convert paths to File objects
    final imageFiles = offline.imagePaths.map((path) => File(path)).toList();

    // Call the online submission method
    await createCollectionEvent(
      farmerId: _authProvider.currentUser!.id,
      data: data,
      imageFiles: imageFiles,
    );
  }
}