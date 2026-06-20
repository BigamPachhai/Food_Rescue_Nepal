import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _DietaryOption {
  final String key, label, emoji, description;
  const _DietaryOption({required this.key, required this.label, required this.emoji, required this.description});
}

const _dietaryOptions = [
  _DietaryOption(key: 'veg', label: 'Vegetarian', emoji: '🥦', description: 'No meat or fish'),
  _DietaryOption(key: 'vegan', label: 'Vegan', emoji: '🌱', description: 'No animal products'),
  _DietaryOption(key: 'gluten_free', label: 'Gluten Free', emoji: '🌾', description: 'No wheat, barley, rye'),
  _DietaryOption(key: 'dairy_free', label: 'Dairy Free', emoji: '🥛', description: 'No milk or dairy products'),
  _DietaryOption(key: 'nut_free', label: 'Nut Free', emoji: '🥜', description: 'No peanuts or tree nuts'),
  _DietaryOption(key: 'halal', label: 'Halal', emoji: '☪️', description: 'Prepared according to Islamic law'),
  _DietaryOption(key: 'low_carb', label: 'Low Carb', emoji: '🍳', description: 'Reduced carbohydrate content'),
  _DietaryOption(key: 'organic', label: 'Organic', emoji: '🌿', description: 'Organically grown ingredients'),
];

const _allergens = [
  _DietaryOption(key: 'allergy_nuts', label: 'Nuts', emoji: '🥜', description: 'Peanuts and tree nuts'),
  _DietaryOption(key: 'allergy_dairy', label: 'Dairy', emoji: '🧀', description: 'Milk, cheese, butter'),
  _DietaryOption(key: 'allergy_eggs', label: 'Eggs', emoji: '🥚', description: 'Eggs and egg products'),
  _DietaryOption(key: 'allergy_gluten', label: 'Gluten', emoji: '🌾', description: 'Wheat, barley, rye'),
  _DietaryOption(key: 'allergy_soy', label: 'Soy', emoji: '🫘', description: 'Soy and soy products'),
  _DietaryOption(key: 'allergy_shellfish', label: 'Shellfish', emoji: '🦐', description: 'Shrimp, crab, lobster'),
];

final _dietaryPrefsProvider = StateNotifierProvider<_DietaryPrefsNotifier, Map<String, bool>>((ref) => _DietaryPrefsNotifier());

class _DietaryPrefsNotifier extends StateNotifier<Map<String, bool>> {
  _DietaryPrefsNotifier() : super({}) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final o in [..._dietaryOptions, ..._allergens]) {
      map[o.key] = prefs.getBool(o.key) ?? false;
    }
    state = map;
  }

  Future<void> toggle(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final val = !(state[key] ?? false);
    await prefs.setBool(key, val);
    state = {...state, key: val};
  }
}

class DietaryAlertsScreen extends ConsumerWidget {
  const DietaryAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(_dietaryPrefsProvider);
    final notifier = ref.read(_dietaryPrefsProvider.notifier);
    final activeCount = prefs.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Dietary Preferences & Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryMedium),
                const SizedBox(width: 10),
                Expanded(child: Text('$activeCount preference${activeCount > 1 ? 's' : ''} active — listings will be filtered and alerts shown accordingly.', style: AppTextStyles.bodySmall)),
              ]),
            ),
          Text('Dietary Preferences', style: AppTextStyles.h5),
          const SizedBox(height: 4),
          Text('Show only listings that match your diet', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _dietaryOptions.asMap().entries.map((e) => Column(children: [
                _DietaryTile(option: e.value, isOn: prefs[e.value.key] ?? false, onToggle: () => notifier.toggle(e.value.key)),
                if (e.key < _dietaryOptions.length - 1) const Divider(height: 1, indent: 64),
              ])).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Allergen Alerts', style: AppTextStyles.h5),
          const SizedBox(height: 4),
          Text('Get warnings when listings contain these allergens', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _allergens.asMap().entries.map((e) => Column(children: [
                _DietaryTile(option: e.value, isOn: prefs[e.value.key] ?? false, onToggle: () => notifier.toggle(e.value.key), isAllergen: true),
                if (e.key < _allergens.length - 1) const Divider(height: 1, indent: 64),
              ])).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('These preferences help filter listings but vendors self-report their dietary info. Always verify with the vendor if you have severe allergies.', style: AppTextStyles.caption)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DietaryTile extends StatelessWidget {
  final _DietaryOption option;
  final bool isOn, isAllergen;
  final VoidCallback onToggle;
  const _DietaryTile({required this.option, required this.isOn, required this.onToggle, this.isAllergen = false});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: (isAllergen ? Colors.red : AppColors.primaryMedium).withValues(alpha: isOn ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(option.emoji, style: const TextStyle(fontSize: 22))),
    ),
    title: Text(option.label, style: AppTextStyles.label),
    subtitle: Text(option.description, style: AppTextStyles.caption),
    trailing: Switch(
      value: isOn,
      onChanged: (_) => onToggle(),
      activeThumbColor: isAllergen ? Colors.red : AppColors.primaryMedium,
    ),
  );
}
