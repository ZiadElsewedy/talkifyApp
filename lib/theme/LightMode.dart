import 'package:flutter/material.dart';

ThemeData lightmode = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: Colors.grey.shade700,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade500,
    onSecondary: Colors.white,
    tertiary: Colors.grey.shade400,
    surface: Colors.white,
    onSurface: Colors.grey.shade900,
    background: Colors.grey.shade100,
    onBackground: Colors.grey.shade900,
    error: Colors.redAccent,
    onError: Colors.white,
    inversePrimary: Colors.grey.shade900,
  ),
  scaffoldBackgroundColor: Colors.grey.shade100,
  cardColor: Colors.white,
  dividerColor: Colors.grey.shade300,
  
  // Text themes
  textTheme: TextTheme(
    titleLarge: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Colors.grey.shade900),
    bodyMedium: TextStyle(color: Colors.grey.shade700),
    bodySmall: TextStyle(color: Colors.grey.shade600),
  ),
  
  // Component themes
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.grey.shade900,
    elevation: 0,
    shadowColor: Colors.grey.shade300,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade700,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.grey.shade900,
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Colors.grey.shade100,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey.shade500),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.grey.shade900,
    unselectedItemColor: Colors.grey.shade400,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
  ),
  tabBarTheme: TabBarTheme(
    labelColor: Colors.grey.shade900,
    unselectedLabelColor: Colors.grey.shade400,
    indicatorColor: Colors.grey.shade900,
  ),
);