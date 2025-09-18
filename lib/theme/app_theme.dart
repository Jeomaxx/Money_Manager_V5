import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System Constants
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  
  // Colors for income/expense
  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFF44336);
  static const Color balancePositive = Color(0xFF2E7D32);
  static const Color balanceNegative = Color(0xFFD32F2F);
  
  // Primary brand colors
  static const Color primarySeed = Color(0xFF00695C); // Teal
  static const Color secondarySeed = Color(0xFF1976D2); // Blue
  
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
    ),
    
    // Typography using Noto Sans Arabic for better Arabic support
    textTheme: GoogleFonts.notoSansArabicTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.notoSansArabic(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.notoSansArabic(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.notoSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.notoSansArabic(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleSpacing: spacingL,
    ),
    
    // Card Theme
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusM)),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingXs,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primarySeed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingXl,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    ),
    
    // FloatingActionButton Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusL)),
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusS)),
      ),
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
    ),
    
    // Typography - same as light theme but with dark colors
    textTheme: GoogleFonts.notoSansArabicTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.notoSansArabic(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.notoSansArabic(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.notoSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.notoSansArabic(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // Apply same component themes as light theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleSpacing: spacingL,
    ),
    
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusM)),
      ),
    ),
    
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingXs,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primarySeed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingXl,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusL)),
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusS)),
      ),
    ),
  );
  
  // Helper methods for semantic colors
  static Color getIncomeColor(BuildContext context) => incomeColor;
  static Color getExpenseColor(BuildContext context) => expenseColor;
  
  static Color getBalanceColor(BuildContext context, double balance) {
    return balance >= 0 ? balancePositive : balanceNegative;
  }
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Animation curves
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const Curve animationBounceCurve = Curves.elasticOut;
}