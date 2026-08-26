import 'package:flutter/material.dart';

/// 七天学堂主题配置
/// 主色调取自原App CSS: #ed5b68
class AppTheme {
  static const Color primaryColor = Color(0xFFED5B68);
  static const Color primaryLight = Color(0xFFEF6B77);
  static const Color primaryDark = Color(0xFFD1505C);
  static const Color accentColor = Color(0xFF0CD1E8);
  static const Color goldColor = Color(0xFFD29C4E);
  static const Color backgroundColor = Color(0xFFFBFBFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textHint = Color(0xFFADADAD);
  static const Color dividerColor = Color(0xFFDADADA);
  static const Color errorColor = Color(0xFFFF5656);
  static const Color successColor = Color(0xFF10DC60);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}