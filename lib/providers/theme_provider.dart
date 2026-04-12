import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/constants.dart';

/// Reads and persists the user's preferred [ThemeMode].
///
/// Defaults to [ThemeMode.system] on first launch so the app follows the
/// device setting out of the box. When the user toggles dark mode in Settings,
/// the choice is written to SharedPreferences and survives restarts.
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    // null  → user has never toggled → follow system
    final stored = prefs.getBool(PrefsKeys.darkMode);
    if (stored == null) return ThemeMode.system;
    return stored ? ThemeMode.dark : ThemeMode.light;
  }

  /// Persists [isDark] and updates the live theme immediately.
  Future<void> setDark(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.darkMode, isDark);
    state = AsyncData(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
