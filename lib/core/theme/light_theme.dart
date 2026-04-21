// ==================== Light Theme ====================
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_theme.dart';

class LightTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Primary Colors
    primaryColor: ColorsManager.primaryColor,
    primaryColorLight: ColorsManager.secondaryColor,
    primaryColorDark: ColorsManager.primaryColor,

    // Card & Surface Colors
    cardColor: ColorsManager.backgroundCard,
    scaffoldBackgroundColor: ColorsManager.backgroundSurface,
    canvasColor: ColorsManager.defaultSurface,

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: ColorsManager.primaryColor,
      secondary: ColorsManager.secondaryColor,

      // Surface colors
      surface: ColorsManager.defaultSurface,
      surfaceContainerHighest: ColorsManager.backgroundCard,

      // Background
      background: ColorsManager.backgroundSurface,

      // Error colors
      error: ColorsManager.errorFill,
      onError: ColorsManager.errorOnFill,
      errorContainer: ColorsManager.errorSurface,

      // On colors (text on surfaces)
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ColorsManager.defaultText,
      onBackground: ColorsManager.defaultText,
      onSurfaceVariant: ColorsManager.defaultTextSecondary,

      // Outline & Shadow
      outline: ColorsManager.inputBorder,
      shadow: Colors.black.withOpacity(0.1),
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorsManager.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: ColorsManager.primaryColor,
      unselectedItemColor: ColorsManager.inputBorder,
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: AppTextTheme.fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Bottom App Bar Theme
    bottomAppBarTheme: const BottomAppBarTheme(
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextTheme.fontFamily,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextTheme.fontFamily,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.inputSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // Borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorsManager.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorsManager.errorFill, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorsManager.errorFill, width: 2),
      ),

      // Text styles
      hintStyle: const TextStyle(
        color: ColorsManager.inputBorder,
        fontFamily: AppTextTheme.fontFamily,
      ),
      labelStyle: const TextStyle(
        color: ColorsManager.defaultTextSecondary,
        fontFamily: AppTextTheme.fontFamily,
      ),
      errorStyle: const TextStyle(
        color: ColorsManager.errorText,
        fontFamily: AppTextTheme.fontFamily,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: ColorsManager.defaultText,
      size: 24,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: ColorsManager.inputBorder,
      thickness: 1,
      space: 1,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: ColorsManager.primaryColor.withOpacity(0.1),
      selectedColor: ColorsManager.primaryColor,
      disabledColor: ColorsManager.inputBorder.withOpacity(0.3),
      labelStyle: const TextStyle(
        color: ColorsManager.primaryColor,
        fontFamily: AppTextTheme.fontFamily,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: AppTextTheme.fontFamily,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Text Theme
    textTheme: AppTextTheme.lightTextTheme,
  );
}

