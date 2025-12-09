import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      print('DEBUG LocationService: Checking if location services are enabled...');
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG LocationService: Location services are disabled');
        return null;
      }
      print('DEBUG LocationService: Location services enabled');

      print('DEBUG LocationService: Requesting location permission...');
      // Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('DEBUG LocationService: Location permission denied');
        return null;
      }
      print('DEBUG LocationService: Location permission granted');

      print('DEBUG LocationService: Fetching current position...');
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('DEBUG LocationService: Position fetched successfully - ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('DEBUG LocationService: Error getting location: $e');
      return null;
    }
  }

  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lonDirection = longitude >= 0 ? 'E' : 'W';

    return '${latitude.abs().toStringAsFixed(6)}°$latDirection, ${longitude.abs().toStringAsFixed(6)}°$lonDirection';
  }

  // Reverse geocoding to get location name from coordinates
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      print('DEBUG LocationService: Starting reverse geocoding for $latitude, $longitude');
      
      // Using Nominatim (OpenStreetMap) reverse geocoding API - free and no API key required
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en'
      );
      
      print('DEBUG LocationService: Calling API: $url');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'HerbalTrace/1.0', // Required by Nominatim usage policy
        },
      ).timeout(const Duration(seconds: 10));

      print('DEBUG LocationService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG LocationService: Response data: $data');
        
        // Extract location details
        final address = data['address'];
        if (address != null) {
          // Build location name from available components
          List<String> locationParts = [];
          
          // Add village/town/city
          if (address['village'] != null) {
            locationParts.add(address['village']);
          } else if (address['town'] != null) {
            locationParts.add(address['town']);
          } else if (address['city'] != null) {
            locationParts.add(address['city']);
          }
          
          // Add state/region
          if (address['state'] != null) {
            locationParts.add(address['state']);
          }
          
          // Add country
          if (address['country'] != null) {
            locationParts.add(address['country']);
          }
          
          if (locationParts.isNotEmpty) {
            final locationName = locationParts.join(', ');
            print('DEBUG LocationService: Constructed location name: $locationName');
            return locationName;
          }
        }
        
        // Fallback to display_name if address components not available
        final displayName = data['display_name'];
        print('DEBUG LocationService: Using display_name: $displayName');
        return displayName;
      }
      
      print('DEBUG LocationService: Reverse geocoding failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('DEBUG LocationService: Error in reverse geocoding: $e');
      return null;
    }
  }
}
