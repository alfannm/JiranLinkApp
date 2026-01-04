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
    return getDistrictFromPlacemark(placemarks.first);
  }

  /// Helper to extract district from Placemark with custom logic
  String getDistrictFromPlacemark(Placemark place) {
    // Special handling for Tok Jembal -> Kuala Nerus
    final subLocality = place.subLocality?.trim() ?? '';
    if (subLocality.toLowerCase().contains('tok jembal')) {
      return 'Kuala Nerus';
    }

    final subAdmin = place.subAdministrativeArea?.trim() ?? '';
    final locality = place.locality?.trim() ?? '';

    // Fix for Kuala Nerus being inside Kuala Terengganu district in some datasets
    if (subAdmin.toLowerCase() == 'kuala terengganu' && 
        locality.toLowerCase() == 'kuala nerus') {
      return 'Kuala Nerus';
    }

    // Default fallback priority
    return (subAdmin.isNotEmpty ? subAdmin : 
            locality.isNotEmpty ? locality : 
            subLocality.isNotEmpty ? subLocality : 
            place.administrativeArea ?? 
            '').trim();
  }

  /// Returns the full Placemark object for the current location.
  Future<Placemark?> getCurrentPlacemark() async {
    try {
      final position = await getCurrentPosition();
      return getPlacemarkFromPosition(position);
    } catch (e) {
      return null;
    }
  }

  Future<Placemark?> getPlacemarkFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      return placemarks.first;
    } catch (e) {
      return null;
    }
  }
}
