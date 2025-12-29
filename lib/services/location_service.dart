import 'package:geolocator/geolocator.dart';

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
}
