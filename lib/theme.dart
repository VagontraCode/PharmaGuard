import 'package:flutter/material.dart';

class AppTheme {
  // === PALETTE DE COULEURS DARK MODE ===
  static const Color deepBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF2D2D2D);
  static const Color lightGray = Color(0xFF404040);

  // === PALETTE DE COULEURS LIGHT MODE (Option 2 - Beige chaud) ===
  static const Color warmCream = Color(0xFFFAF7F0);
  static const Color lightBeige = Color(0xFFF5F1E8);
  static const Color softBrown = Color(0xFF8B7355);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightShadow = Color(0xFFD4C5B0);
  static const Color darkText = Color(0xFF2C2416);

  // === CONFIGURATION DU THÈME DARK ===
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentGreen,
      scaffoldBackgroundColor: deepBlack,
      fontFamily: 'Inter',

      colorScheme: ColorScheme.dark(
        primary: accentGreen,
        secondary: accentGreen,
        surface: darkGray,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: pureWhite,
      ),

      cardColor: darkGray,
      shadowColor: mediumGray,

      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: pureWhite,
        ),
        iconTheme: IconThemeData(color: pureWhite),
      ),

      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: pureWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: pureWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: pureWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: pureWhite.withValues(alpha: 0.8),
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: pureWhite.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // === CONFIGURATION DU THÈME LIGHT ===
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: darkGray,
      scaffoldBackgroundColor: warmCream,
      fontFamily: 'Inter',

      colorScheme: ColorScheme.light(
        primary: accentGreen,
        secondary: accentGreen,
        surface: lightCardBg,
        surfaceBright: warmCream,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: darkText,
        onSurfaceVariant: darkText,
      ),

      cardColor: lightCardBg,
      shadowColor: lightShadow,

      appBarTheme: AppBarTheme(
        backgroundColor: warmCream,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        iconTheme: IconThemeData(color: darkText),
      ),

      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkText.withValues(alpha: 0.8),
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkText.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // === STYLE ADAPTATIF POUR LES CARTES ===
  static BoxDecoration modernCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? mediumGray.withValues(alpha: 0.3)
              : lightShadow.withValues(alpha: 0.4),
          blurRadius: isDark ? 10 : 8,
          spreadRadius: isDark ? 2 : 1,
          offset: Offset(0, isDark ? 5 : 3),
        ),
      ],
    );
  }

  // === STYLE ADAPTATIF POUR BOUTONS ===
  static BoxDecoration modernButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accentGreen,
          isDark
              ? accentGreen.withValues(alpha: 0.8)
              : accentGreen.withValues(alpha: 0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: accentGreen.withValues(alpha: isDark ? 0.3 : 0.25),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  // === SÉPARATEURS ADAPTATIFS ===
  static BoxDecoration divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [mediumGray, lightGray, mediumGray]
            : [
                lightShadow.withValues(alpha: 0.3),
                lightShadow,
                lightShadow.withValues(alpha: 0.3),
              ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  // === ICONES DE RÉGION ===
  static IconData getRegionIcon(String regionName) {
    switch (regionName) {
      case "ADAMAOUA":
        return Icons.landscape;
      case "CENTRE":
        return Icons.business_center;
      case "EST":
        return Icons.forest;
      case "EXTRÊME-NORD":
        return Icons.north;
      case "LITTORAL":
        return Icons.beach_access;
      case "NORD":
        return Icons.bubble_chart;
      case "NORD-OUEST":
        return Icons.bubble_chart;
      case "OUEST":
        return Icons.terrain;
      case "SUD":
        return Icons.south;
      case "SUD-OUEST":
        return Icons.waves;
      default:
        return Icons.location_on;
    }
  }

  // Alias pour compatibilité
  static ThemeData get theme => darkTheme;
}
