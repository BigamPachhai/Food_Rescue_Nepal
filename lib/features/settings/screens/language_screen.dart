import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey) ?? 'en';
    state = Locale(code);
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, code);
  }
}

const _languages = [
  ('en', 'English', 'English'),
  ('ne', 'नेपाली', 'Nepali'),
];

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Language / भाषा')),
      body: ListView(
        children: _languages.map((lang) {
          final isSelected = current.languageCode == lang.$1;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
              child: Text(lang.$1.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ),
            title: Text(lang.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text(lang.$3),
            trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
            onTap: () {
              ref.read(languageProvider.notifier).setLanguage(lang.$1);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language changed to ${lang.$2}')));
            },
          );
        }).toList(),
      ),
    );
  }
}
