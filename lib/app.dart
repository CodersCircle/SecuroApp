import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

// Forced light mode by removing dependency on ThemeService
class SecuroApp extends StatelessWidget {
  const SecuroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecuroApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
