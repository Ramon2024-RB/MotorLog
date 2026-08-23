import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const _preferenceKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_preferenceKey);

    return switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();

    final value = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await preferences.setString(_preferenceKey, value);

    state = AsyncData(themeMode);
  }
}
