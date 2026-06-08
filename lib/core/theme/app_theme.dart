import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kOrangePrimary,
    primary: kOrangePrimary,
    onPrimary: Colors.white,
    surface: kSurfaceColor,
    onSurface: kTextPrimary,
  ),
  scaffoldBackgroundColor: kWarmWhite,
  appBarTheme: const AppBarTheme(
    backgroundColor: kBrownDark,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kOrangePrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kOrangePrimary,
      side: const BorderSide(color: kOrangePrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kDividerWarm),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kDividerWarm),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kOrangePrimary, width: 2),
    ),
    labelStyle: const TextStyle(color: kTextSecondary),
    hintStyle: const TextStyle(color: kTextTertiary),
  ),
  cardTheme: CardThemeData(
    color: kSurfaceColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  dividerColor: kDividerWarm,
  fontFamily: 'Roboto',
);
