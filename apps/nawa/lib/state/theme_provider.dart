import 'package:flutter/material.dart';
import 'package:nawa/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode;

  ThemeProvider(this._storageService, this._themeMode);

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _storageService.saveThemeMode(_themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(_themeMode);
  }
}
