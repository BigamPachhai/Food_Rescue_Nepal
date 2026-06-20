import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

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

// ─── Dietary preferences ──────────────────────────────────────────────────

class DietaryPrefsNotifier extends StateNotifier<Set<String>> {
  DietaryPrefsNotifier() : super(const {}) {
    _load();
  }

  static const _key = 'dietary_prefs';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored != null) state = Set<String>.from(stored);
  }

  Future<void> toggle(String tag) async {
    final next = {...state};
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final dietaryPrefsProvider =
    StateNotifierProvider<DietaryPrefsNotifier, Set<String>>(
  (_) => DietaryPrefsNotifier(),
);

// ─── Nearby alert radius ──────────────────────────────────────────────────

class NearbyRadiusNotifier extends StateNotifier<double> {
  NearbyRadiusNotifier() : super(5.0) {
    _load();
  }

  static const _key = 'nearby_radius';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key) ?? 5.0;
  }

  Future<void> set(double value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
  }
}

final nearbyRadiusProvider =
    StateNotifierProvider<NearbyRadiusNotifier, double>(
  (_) => NearbyRadiusNotifier(),
);
