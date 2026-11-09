import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persisted app settings: onboarding seen flag + theme mode.
/// Kept in one place so splash, onboarding and the theme picker all
/// agree on the same keys. The theme mode is stored as its plain name
/// (system/dark/light) so this file does not depend on the theme
/// controller — see [theme_controller.dart] for the mapping.
class AppPrefs {
  const AppPrefs._();

  static const _onboardingSeenKey = 'douri_onboarding_seen';
  static const _themeModeKey = 'douri_theme_mode';

  static Future<bool> loadOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> saveOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  static Future<String?> loadThemeModeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  static Future<void> saveThemeModeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, name);
  }
}
