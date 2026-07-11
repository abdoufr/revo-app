import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Riverpod 3: use NotifierProvider instead of StateNotifierProvider ────────
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

class ThemeState {
  final ThemeMode themeMode;
  final Locale locale;

  ThemeState({
    required this.themeMode,
    required this.locale,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

// ─── Riverpod 3: use Notifier instead of StateNotifier ───────────────────────
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    // Load saved settings asynchronously after init
    _loadSettings();
    return ThemeState(themeMode: ThemeMode.light, locale: const Locale('fr'));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final langCode = prefs.getString('lang') ?? 'fr';

    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(langCode),
    );
  }

  Future<void> toggleTheme() async {
    final isDark = state.themeMode == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(themeMode: newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', !isDark);
  }

  Future<void> setLanguage(String langCode) async {
    state = state.copyWith(locale: Locale(langCode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', langCode);
  }
}
