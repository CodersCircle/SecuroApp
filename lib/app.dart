import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/web_connect_screen.dart';

// Web → QR connect screen only. Mobile → normal auth flow.
class SecuroApp extends StatelessWidget {
  const SecuroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecuroApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: kIsWeb
          ? const WebConnectScreen()
          : const SplashScreen(),
    );
  }
}
