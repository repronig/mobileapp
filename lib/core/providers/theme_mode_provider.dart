import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import 'storage_providers.dart';

/// Persists [ThemeMode] in SharedPreferences. First launch defaults to **light**
/// (not system), so the app does not follow the OS dark theme until the user
/// changes it under More → Theme.
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(StorageKeys.themeMode);
    return _parse(raw);
  }

  ThemeMode _parse(String? raw) {
    if (raw == null) return ThemeMode.light;
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(StorageKeys.themeMode, mode.name);
  }

  Future<void> cycle() async {
    switch (state) {
      case ThemeMode.system:
        await setTheme(ThemeMode.light);
      case ThemeMode.light:
        await setTheme(ThemeMode.dark);
      case ThemeMode.dark:
        await setTheme(ThemeMode.system);
    }
  }
}
