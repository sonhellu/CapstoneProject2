import 'package:flutter/material.dart';

// On web   → map_screen_web.dart  (HtmlElementView + Naver Maps Web JS SDK)
// On mobile → map_screen.dart     (flutter_naver_map native SDK)
import 'map_screen.dart'
    if (dart.library.html) 'map_screen_web.dart';

class MapsTabScreen extends StatelessWidget {
  const MapsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapScreen();
  }
}
