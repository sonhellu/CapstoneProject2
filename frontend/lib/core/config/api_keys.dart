/// API keys — điền giá trị từ NCP / Naver Developers (xem `api_keys.example.dart`).
/// File này được commit với placeholder rỗng để CI và `flutter analyze` chạy được;
/// trên máy dev, thay bằng key thật (không push key production lên repo công khai).
abstract final class ApiKeys {
  static const naverMapClientId = '';
  static const naverMapClientSecret = '';

  static const naverLocalSearchClientId = '';
  static const naverLocalSearchClientSecret = '';

  static const papagoClientId = '';
  static const papagoClientSecret = '';
}
