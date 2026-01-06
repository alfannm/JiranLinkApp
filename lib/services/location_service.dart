import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Location helpers for reading the device position and district.
class LocationService {
  // Requests permission and returns the current device position.
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

  // Returns a best-effort district name for the current location.
  Future<String> getCurrentDistrict() async {
    final position = await getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return '';
    return getDistrictFromPlacemark(placemarks.first);
  }

  // Extracts a district name from a Placemark.
  String getDistrictFromPlacemark(Placemark place) {
    // Map known local names to the district.
    final subLocality = place.subLocality?.trim() ?? '';
    if (subLocality.toLowerCase().contains('tok jembal')) {
      return 'Kuala Nerus';
    }

    final subAdmin = place.subAdministrativeArea?.trim() ?? '';
    final locality = place.locality?.trim() ?? '';

    // Handle dataset variations for Kuala Nerus.
    if (subAdmin.toLowerCase() == 'kuala terengganu' && 
        locality.toLowerCase() == 'kuala nerus') {
      return 'Kuala Nerus';
    }

    // Fallback order for district name.
    return (subAdmin.isNotEmpty ? subAdmin : 
            locality.isNotEmpty ? locality : 
            subLocality.isNotEmpty ? subLocality : 
            place.administrativeArea ?? 
            '').trim();
  }

  // Looks up a placemark for a given position.
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
