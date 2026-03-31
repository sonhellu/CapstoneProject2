import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/capstone_app.dart';
import 'core/locale/locale_controller.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
      ],
      child: const CapstoneApp(),
    ),
  );
}
