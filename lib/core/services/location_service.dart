import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
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
}
