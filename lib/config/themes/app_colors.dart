import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // Primary Brand Colors (MyHome Theme)
  static const primaryBlue = Color(0xFF051D40);
  static const secondaryBlue = Color(0xFF145DA0);
  static const darkPrimaryBlue = Color(0xFF6088C0);
  
  // Surface Colors
  static const white = Color(0xFFFFFFFF);
  static const scaffoldBackground = Color(0xFFFAFAFA);
  static const surfaceLight = Color(0xFFF4F6F8);
  static const black = Color(0xFF000000);
  
  // Text Colors
  static const textPrimary = Color(0xDE000000);
  static const textSecondary = Color(0xC2000000);
  static const textTertiary = Color(0x8A000000);
  static const textDisabled = Color(0x61000000);
  static const textWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF282828);
  
  // Icon Colors
  static const iconSecondary = Color(0xC2000000);
  static const iconTertiary = Color(0x8a000000);
  static const iconDisabled = Color(0x61000000);
  
  // Border Colors
  static const bordersLight = Color(0x1F000000);
  static const borderError = Color(0xFFD12730);
  
  // State Colors
  static const textError = Color(0xFFD12730);
  static const notificationInfo = Color(0xFF323232);
  static const notificationWarning = Color(0xFFdc6d1b);
  static const notificationSuccess = Color(0xFF008000);
  static const notificationError = Color(0xFFD12730);
  
  // Overlay Colors
  static const bgOverlay = Color(0x61000000);
  static const cameraBackground = Color(0xFF828282);
  
  // Selection and Focus Colors
  static const selectionColor = Color(0x33051D40); // primaryBlue with 20% opacity
  static const focusColor = primaryBlue;
  
  // Material Color Swatch for Primary Blue
  static const MaterialColor primarySwatch = MaterialColor(0xFF051D40, <int, Color>{
    50: Color(0xFFE3EEF9),
    100: Color(0xFFB8D0ED),
    200: Color(0xFF89B0E0),
    300: Color(0xFF5A90D3),
    400: Color(0xFF3678C9),
    500: primaryBlue,
    600: secondaryBlue,
    700: Color(0xFF0F4A8A),
    800: Color(0xFF0A3670),
    900: Color(0xFF051D40),
  });
  
  // Dark Theme Material Color Swatch
  static const MaterialColor darkPrimarySwatch = MaterialColor(0xFF6088C0, <int, Color>{
    50: Color(0xFFE3EEF9),
    100: Color(0xFFB8D0ED),
    200: Color(0xFF89B0E0),
    300: Color(0xFF5A90D3),
    400: Color(0xFF3678C9),
    500: darkPrimaryBlue,
    600: secondaryBlue,
    700: Color(0xFF0F4A8A),
    800: Color(0xFF0A3670),
    900: Color(0xFF051D40),
  });
  
  // Getters for dynamic color access
  static Color get appPrimaryColor => primaryBlue;
}
