import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBackground = Color(0xFF1C1C1E);
  static const Color cardBackground = Color(0xFF2C2C2E);
  static const Color accentBackground = Color(0xFF38383A);
  static const Color dividerColor = Color(0xFF38383A);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAEAEB2);
  static const Color textTertiary = Color(0xFF8E8E93);
  
  static const Color incomeColor = Color(0xFF32D74B); // green-400
  static const Color expenseColor = Color(0xFFFF453A); // red-400
  static const Color activeTabColor = Color(0xFF007AFF); // blue-500
  
  static const Color iconPrimary = Colors.white;
  static const Color iconSecondary = Color(0xFF48484A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: activeTabColor,
        secondary: activeTabColor,
        surface: cardBackground,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),

      // Scaffold theme
      scaffoldBackgroundColor: primaryBackground,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'SplineSans',
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF242426),
        selectedItemColor: activeTabColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
      ),

      // Card theme
      cardTheme: const CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'SplineSans',
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'SplineSans',
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'SplineSans',
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SplineSans',
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
        titleSmall: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: 'SplineSans',
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'SplineSans',
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'SplineSans',
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
        labelSmall: TextStyle(
          color: textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: activeTabColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: activeTabColor,
          foregroundColor: textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'SplineSans',
          ),
        ),
      ),

      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textTertiary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: activeTabColor, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'SplineSans',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'SplineSans',
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Currency formatter
  static String formatCurrency(double amount, {bool showSign = true}) {
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();
    
    String formatted = '₹${absoluteAmount.toStringAsFixed(2)}';
    
    if (showSign && isNegative) {
      formatted = '-$formatted';
    } else if (showSign && !isNegative && amount > 0) {
      formatted = '+$formatted';
    }
    
    return formatted;
  }

  // Get amount color based on type
  static Color getAmountColor(double amount, {bool isIncome = false}) {
    if (isIncome || amount > 0) {
      return incomeColor;
    } else {
      return expenseColor;
    }
  }

  // Common padding and margins
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // Common border radius
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(12));

  // Common spacings
  static const SizedBox verticalSpaceSmall = SizedBox(height: 8);
  static const SizedBox verticalSpaceMedium = SizedBox(height: 16);
  static const SizedBox verticalSpaceLarge = SizedBox(height: 24);
  
  static const SizedBox horizontalSpaceSmall = SizedBox(width: 8);
  static const SizedBox horizontalSpaceMedium = SizedBox(width: 16);
  static const SizedBox horizontalSpaceLarge = SizedBox(width: 24);
}