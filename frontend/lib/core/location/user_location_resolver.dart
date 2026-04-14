import 'package:geolocator/geolocator.dart';

/// One-shot GPS read after service + permission checks (same policy as map "my location").
///
/// Returns `null` if location is disabled, denied, or no fix in time.
Future<Position?> resolveCurrentGpsPosition({
  Duration timeLimit = const Duration(seconds: 15),
}) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: timeLimit,
      ),
    );
  } catch (_) {
    return await Geolocator.getLastKnownPosition();
  }
}
