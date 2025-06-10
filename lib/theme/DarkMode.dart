import 'package:flutter/material.dart';

ThemeData darkmode = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade800,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade700,
    onSecondary: Colors.white,
    tertiary: Colors.grey.shade600,
    surface: Color(0xFF1E1E1E),  // Almost black
    onSurface: Colors.white,
    background: Color(0xFF121212),  // Pure black
    onBackground: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    inversePrimary: Colors.grey.shade200,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),  // Pure black
  cardColor: Color(0xFF1E1E1E),
  dividerColor: Colors.grey.shade800,
  
  // Text themes
  textTheme: TextTheme(
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.grey.shade300),
    bodySmall: TextStyle(color: Colors.grey.shade400),
  ),
  
  // Component themes
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade800,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  iconTheme: IconThemeData(
    color: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Color(0xFF2C2C2C),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey.shade500),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey.shade600,
  ),
  cardTheme: CardThemeData(
    color: Color(0xFF1E1E1E),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade800, width: 1),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.grey.shade600,
    indicatorColor: Colors.white,
  ),
); 