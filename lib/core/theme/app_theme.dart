import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryVariant = Color(0xFF4A42D4);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);
  static const Color cardColor = Color(0xFF1E1E30);
  static const Color onSurface = Color(0xFFE8E8FF);
  static const Color onSurfaceMuted = Color(0xFF8888AA);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFFFB74D);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? background : Colors.white; // Default scaffold background
    final surf = isDark ? surface : Colors.white;
    final surfVar = isDark ? surfaceVariant : const Color(0xFFF3F4F6); // Slightly darker surface for contrast
    final card = isDark ? cardColor : Colors.white;
    final onSurf = isDark ? onSurface : const Color(0xFF1F2937); // Darker text for readability
    final onSurfMuted = isDark ? onSurfaceMuted : const Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: bg,
        onSurface: onSurf,
      ).copyWith(
        primaryContainer: primaryVariant,
        surfaceContainerHighest: surfVar,
      ),
      scaffoldBackgroundColor: bg,
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 6 : 8,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF9CA3AF).withValues(alpha: 0.3), // Softer grey shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6), // subtle border
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurf,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: onSurf),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfVar,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE5E7EB), // Clearer light border
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: onSurfMuted),
        hintStyle: TextStyle(color: onSurfMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: primary,
        unselectedItemColor: onSurfMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfVar,
        selectedColor: primary.withValues(alpha: 0.2), // Lighter selected chip bg
        labelStyle: TextStyle(color: onSurf, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            color: onSurf,
            fontSize: 28,
            fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(
            color: onSurf,
            fontSize: 22,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: onSurf,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: onSurf,
            fontSize: 16,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: onSurf, fontSize: 15),
        bodyMedium: TextStyle(color: onSurfMuted, fontSize: 13),
        labelSmall: TextStyle(color: onSurfMuted, fontSize: 11),
      ),
    );
  }
}
