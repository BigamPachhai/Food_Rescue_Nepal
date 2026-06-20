import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'app_theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

class DarkModeScreen extends ConsumerWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          _ThemeTile(
            mode: ThemeMode.system,
            current: current,
            icon: Icons.brightness_auto,
            title: 'System Default',
            subtitle: 'Follow device light/dark setting',
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          _ThemeTile(
            mode: ThemeMode.light,
            current: current,
            icon: Icons.light_mode,
            title: 'Light Mode',
            subtitle: 'Always use light theme',
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _ThemeTile(
            mode: ThemeMode.dark,
            current: current,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Always use dark theme',
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode mode, current;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ThemeTile({required this.mode, required this.current, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: onTap,
    );
  }
}
