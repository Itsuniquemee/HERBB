// lib/services/collection_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CollectionApi {
  // Only domain kept here as per earlier comment idea — full endpoint used in function
  static const String baseUrl = "https://herbal-trace-production.up.railway.app";

  // Hardcoded token (as requested)
  static const String _bearerToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MjM1MDU2LCJleHAiOjE3NjUzMjE0NTZ9.obOcf9rK86hhrf4Xqq_4MvKoM20qKICNI6TXfblsKwU";

  /// Creates a collection record.
  /// Returns event id string if available on success, otherwise throws.
  static Future<String?> createCollection({
    required String herbType,
    required int quantity,
    required String unit,
    required String collectionDate, // YYYY-MM-DD
    required String location,
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/collections');

    final body = {
      "species": herbType,
      "quantity": quantity,
      "unit": unit,
      "harvestDate": collectionDate,
      "location": location,
    };

    // Merge extras if present (moisture, temperature, etc.)
    if (extra != null) {
      body.addAll(extra.map((k, v) => MapEntry(k, v)));
    }

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_bearerToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        // try common id fields
        if (decoded is Map<String, dynamic>) {
          return decoded['id']?.toString() ?? decoded['eventId']?.toString() ?? decoded['_id']?.toString();
        }
      } catch (_) {
        // if can't decode, just return null
      }
      return null;
    } else {
      // throw with server response body to help debugging
      throw Exception('API ${response.statusCode}: ${response.body}');
    }
  }
}
