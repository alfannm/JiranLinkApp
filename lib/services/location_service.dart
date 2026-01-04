import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Requests location permission (if needed) and returns the
  /// current device position.
  ///
  /// Throws an exception with a human-readable message if
  /// permission/service is not available.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it in Settings.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns a best-effort district/locality name for the current location.
  Future<String> getCurrentDistrict() async {
    final position = await getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return '';
    final place = placemarks.first;
    return (place.subAdministrativeArea ??
            place.locality ??
            place.subLocality ??
            place.administrativeArea ??
            '')
        .trim();
  }
}
