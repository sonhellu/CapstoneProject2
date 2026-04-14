/// Copy to `api_keys.dart` and fill real values. Do not commit `api_keys.dart`.
///
/// 1. **NCP** https://console.ncloud.com — Maps → Client ID & Secret
///    (Flutter Map SDK, reverse geocode API Gateway).
///
/// 2. **Developers** https://developers.naver.com — Application → API settings
///    → enable **Search** → Client ID & Secret
///    for `openapi.naver.com/v1/search/local.json` (PlaceSearchService).
abstract final class ApiKeysExample {
  static const naverMapClientId = 'NCP_MAP_CLIENT_ID';
  static const naverMapClientSecret = 'NCP_MAP_CLIENT_SECRET';

  static const naverLocalSearchClientId = 'DEVELOPERS_CLIENT_ID';
  static const naverLocalSearchClientSecret = 'DEVELOPERS_CLIENT_SECRET';
}
