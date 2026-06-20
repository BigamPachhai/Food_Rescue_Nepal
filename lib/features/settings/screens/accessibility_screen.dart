import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

final _fontSizeProvider = StateNotifierProvider<_FontSizeNotifier, double>((ref) => _FontSizeNotifier());
final _highContrastProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) => _BoolNotifier('high_contrast', false));
final _boldTextProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) => _BoolNotifier('bold_text', false));
final _reduceAnimProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) => _BoolNotifier('reduce_anim', false));
final _hapticProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) => _BoolNotifier('haptic', true));
final _screenReaderProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) => _BoolNotifier('screen_reader', false));

class _FontSizeNotifier extends StateNotifier<double> {
  _FontSizeNotifier() : super(1.0) { _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); state = p.getDouble('font_size') ?? 1.0; }
  Future<void> set(double v) async { final p = await SharedPreferences.getInstance(); await p.setDouble('font_size', v); state = v; }
}

class _BoolNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolNotifier(this._key, bool def) : super(def) { _load(def); }
  Future<void> _load(bool def) async { final p = await SharedPreferences.getInstance(); state = p.getBool(_key) ?? def; }
  Future<void> toggle() async { final p = await SharedPreferences.getInstance(); await p.setBool(_key, !state); state = !state; }
}

class AccessibilityScreen extends ConsumerWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(_fontSizeProvider);
    final highContrast = ref.watch(_highContrastProvider);
    final boldText = ref.watch(_boldTextProvider);
    final reduceAnim = ref.watch(_reduceAnimProvider);
    final haptic = ref.watch(_hapticProvider);
    final screenReader = ref.watch(_screenReaderProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Text', [
            _SettingTile(title: 'Font Size', subtitle: _fontSizeLabel(fontSize), trailing: _FontSizeSlider(value: fontSize, onChanged: (v) => ref.read(_fontSizeProvider.notifier).set(v))),
            _ToggleTile(title: 'Bold Text', subtitle: 'Make text heavier for better readability', value: boldText, onToggle: () => ref.read(_boldTextProvider.notifier).toggle()),
          ]),
          _Section('Display', [
            _ToggleTile(title: 'High Contrast Mode', subtitle: 'Increase contrast between text and backgrounds', value: highContrast, onToggle: () => ref.read(_highContrastProvider.notifier).toggle()),
            _ToggleTile(title: 'Reduce Motion', subtitle: 'Minimize animations and transitions', value: reduceAnim, onToggle: () => ref.read(_reduceAnimProvider.notifier).toggle()),
          ]),
          _Section('Interaction', [
            _ToggleTile(title: 'Haptic Feedback', subtitle: 'Vibrate on button presses and interactions', value: haptic, onToggle: () => ref.read(_hapticProvider.notifier).toggle()),
            _ToggleTile(title: 'Screen Reader Support', subtitle: 'Optimize layout for screen readers', value: screenReader, onToggle: () => ref.read(_screenReaderProvider.notifier).toggle()),
          ]),
          _Section('Preview', [
            _PreviewCard(fontSize: fontSize, boldText: boldText, highContrast: highContrast),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryMedium),
              const SizedBox(width: 10),
              Expanded(child: Text('These settings apply to Food Rescue Nepal only. For system-wide accessibility, visit your device Settings > Accessibility.', style: AppTextStyles.caption)),
            ]),
          ),
        ],
      ),
    );
  }

  String _fontSizeLabel(double v) {
    if (v <= 0.8) return 'Small';
    if (v <= 1.0) return 'Default';
    if (v <= 1.2) return 'Large';
    return 'Extra Large';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) items.add(const Divider(height: 1, indent: 16));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h5),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title, subtitle;
  final Widget trailing;
  const _SettingTile({required this.title, required this.subtitle, required this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.label),
      Text(subtitle, style: AppTextStyles.caption),
      trailing,
    ]),
  );
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final VoidCallback onToggle;
  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onToggle});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title, style: AppTextStyles.label),
    subtitle: Text(subtitle, style: AppTextStyles.caption),
    value: value,
    onChanged: (_) => onToggle(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
  );
}

class _FontSizeSlider extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;
  const _FontSizeSlider({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Slider(
    value: value, min: 0.75, max: 1.5, divisions: 3,
    activeColor: AppColors.primaryMedium,
    label: value.toStringAsFixed(2),
    onChanged: onChanged,
  );
}

class _PreviewCard extends StatelessWidget {
  final double fontSize;
  final bool boldText, highContrast;
  const _PreviewCard({required this.fontSize, required this.boldText, required this.highContrast});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Preview', style: AppTextStyles.caption),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highContrast ? Colors.black : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Rescue today\'s surplus food and help reduce waste in your community! 🌱',
          style: TextStyle(
            fontSize: 14 * fontSize,
            fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
            color: highContrast ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    ]),
  );
}
