import 'package:url_launcher/url_launcher.dart';

/// Opens Naver Maps via URL scheme, with web fallback.
class MapDirectionService {
  MapDirectionService._();
  static final MapDirectionService instance = MapDirectionService._();

  static const String _appName = 'com.example.hicampus';

  /// Opens Naver Maps with driving directions to [lat]/[lng].
  ///
  /// Scheme: `nmap://route/public?dlat=...&dlng=...&dname=...&appname=...`
  /// Fallback: `https://map.naver.com/v5/directions/-/-/-/public`
  Future<void> openNaverMaps(
    double lat,
    double lng,
    String destinationName,
  ) async {
    final encodedName = Uri.encodeComponent(destinationName);

    final appUri = Uri.parse(
      'nmap://route/public'
      '?dlat=$lat&dlng=$lng&dname=$encodedName&appname=$_appName',
    );
    final webUri = Uri.parse(
      'https://map.naver.com/v5/directions/-/-/-/public'
      '?c=$lng,$lat,15,0,0,0,dh',
    );

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
