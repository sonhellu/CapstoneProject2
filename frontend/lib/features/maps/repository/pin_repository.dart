import '../models/user_pin_model.dart';

/// Mock repository — replace the body of [mockSavePin] with a real
/// http.post() call when the FastAPI backend is ready.
class PinRepository {
  const PinRepository._();

  /// Simulates a POST /pins network request.
  /// Returns [true] on success, [false] on failure.
  ///
  /// Replace with:
  /// ```dart
  /// final res = await http.post(
  ///   Uri.parse('$baseUrl/pins'),
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode(pin.toJson()),
  /// );
  /// return res.statusCode == 201;
  /// ```
  static Future<bool> mockSavePin(UserPinModel pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return true;
  }
}
