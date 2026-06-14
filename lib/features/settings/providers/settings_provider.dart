import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else if (value == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (_) => ThemeNotifier(),
);

// ─── Notification preferences ─────────────────────────────────────────────

const _defaultNotifPrefs = {
  'order_updates': true,
  'nearby_food': true,
  'pickup_reminders': true,
  'promotions': false,
};

class NotifPrefsNotifier extends StateNotifier<Map<String, bool>> {
  NotifPrefsNotifier() : super(_defaultNotifPrefs) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {..._defaultNotifPrefs};
    for (final key in _defaultNotifPrefs.keys) {
      final stored = prefs.getBool('notif_$key');
      if (stored != null) updated[key] = stored;
    }
    state = updated;
  }

  Future<void> toggle(String key) async {
    final newVal = !(state[key] ?? true);
    state = {...state, key: newVal};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$key', newVal);
  }
}

final notifPrefsProvider =
    StateNotifierProvider<NotifPrefsNotifier, Map<String, bool>>(
  (_) => NotifPrefsNotifier(),
);

// ─── Language ─────────────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'en';
  }

  Future<void> set(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (_) => LanguageNotifier(),
);
