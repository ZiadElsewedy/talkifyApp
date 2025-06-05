import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkifyapp/theme/DarkMode.dart';
import 'package:talkifyapp/theme/LightMode.dart';

// Theme states
abstract class ThemeState {}

class LightThemeState extends ThemeState {}

class DarkThemeState extends ThemeState {}

class ThemeCubit extends Cubit<ThemeState> {
  // Key for storing theme preference
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeCubit() : super(LightThemeState()) {
    _loadSavedTheme();
  }

  // Get current theme data
  ThemeData get themeData => 
    state is DarkThemeState ? darkmode : lightmode;

  // Switch between light and dark themes
  void toggleTheme() async {
    final newState = state is LightThemeState 
        ? DarkThemeState() 
        : LightThemeState();
    
    emit(newState);
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, state is DarkThemeState);
  }

  // Load saved theme preference
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
      
      if (isDarkMode) {
        emit(DarkThemeState());
      } else {
        emit(LightThemeState());
      }
    } catch (e) {
      // Default to light theme if there's an error
      emit(LightThemeState());
    }
  }
} 