import 'package:flutter/material.dart';


/// ThemeModel class is a ChangeNotifier that manages the application's theme state (dark/light mode).
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}