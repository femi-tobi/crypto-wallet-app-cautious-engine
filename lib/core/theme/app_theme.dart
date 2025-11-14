// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeData get theme => _isDark ? darkTheme : lightTheme; // Use public getters

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// PUBLIC THEMES — NO UNDERSCORE
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF0D0D1C),
  scaffoldBackgroundColor: const Color(0xFF0D0D1C),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D0D1C),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Colors.cyanAccent,
    secondary: Colors.teal,
  ),
  iconTheme: const IconThemeData(color: Colors.white70),
);