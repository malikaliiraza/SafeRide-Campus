import 'package:flutter/material.dart';

/// Design tokens for SafeRide Campus.
///
/// Deep teal + warm amber: the bus is the trusted part of the day, the amber
/// is the "pay attention" colour used only for delays and alerts.
class AppTheme {
  AppTheme._();

  static const Color primaryTeal = Color(0xFF0C4444);
  static const Color primaryTealDark = Color(0xFF072E2E);
  static const Color accentTeal = Color(0xFF5EEAD4);
  static const Color backgroundPearl = Color(0xFFF5F2EB);
  static const Color alertAmber = Color(0xFFD97706);
  static const Color onTimeGreen = Color(0xFF15803D);
  static const Color dangerRed = Color(0xFFB91C1C);

  static const double radius = 16;
  static const double spacing = 16;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundPearl,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
