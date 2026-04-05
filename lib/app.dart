import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/web_connect_screen.dart';

// Web / Desktop → QR connect screen only (no login credentials).
// Mobile (Android / iOS) → normal auth flow (splash → login → home).
bool get _isDesktopOrWeb {
  if (kIsWeb) return true;
  try {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } catch (_) {
    return false;
  }
}

class SecuroApp extends StatelessWidget {
  const SecuroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecuroApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDesktopOrWeb ? ThemeMode.dark : ThemeMode.system,
      home: _isDesktopOrWeb ? const WebConnectScreen() : const SplashScreen(),
    );
  }
}
