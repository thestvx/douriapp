import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/app_prefs.dart';

/// App appearance: follow the system, force dark, or force light.
/// The choice is persisted and loaded in main() before the app starts.
/// Default is the system setting; the dark look stays the brand
/// identity for users who never change it.
enum DouriThemeMode { system, dark, light;

  static DouriThemeMode fromName(String? name) => switch (name) {
        'dark' => DouriThemeMode.dark,
        'light' => DouriThemeMode.light,
        _ => DouriThemeMode.system,
      };

  ThemeMode get material => switch (this) {
        DouriThemeMode.system => ThemeMode.system,
        DouriThemeMode.dark => ThemeMode.dark,
        DouriThemeMode.light => ThemeMode.light,
      };
}

final themeModeProvider = StateProvider<DouriThemeMode>((ref) {
  return DouriThemeMode.system;
});

/// Persists [mode] and applies it immediately.
Future<void> setThemeMode(WidgetRef ref, DouriThemeMode mode) async {
  ref.read(themeModeProvider.notifier).state = mode;
  await AppPrefs.saveThemeModeName(mode.name);
}

/// Reads the saved mode (for main() before the first frame).
Future<DouriThemeMode> loadSavedThemeMode() async {
  return DouriThemeMode.fromName(await AppPrefs.loadThemeModeName());
}
