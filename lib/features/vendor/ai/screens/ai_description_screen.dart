import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/mistral_service.dart';

class AiDescriptionScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final double? initialPrice;
  const AiDescriptionScreen({super.key, this.initialName, this.initialCategory, this.initialPrice});

  @override
  ConsumerState<AiDescriptionScreen> createState() => _AiDescriptionScreenState();
}

class _AiDescriptionScreenState extends ConsumerState<AiDescriptionScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  String _category = 'Bakery';
  String? _result;
  bool _isLoading = false;

  static const _categories = ['Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Surprise Bag', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _priceCtrl = TextEditingController(text: widget.initialPrice?.toString() ?? '');
    _category = widget.initialCategory ?? 'Bakery';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter food item name'))); return; }
    setState(() { _isLoading = true; _result = null; });
    final service = ref.read(mistralServiceProvider);
    final result = await service.generateFoodDescription(name, _category, price);
    if (mounted) setState(() { _isLoading = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primaryMedium, size: 20),
          SizedBox(width: 8),
          Text('AI Description Generator'),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(),
          const SizedBox(height: 16),
          _InputForm(nameCtrl: _nameCtrl, priceCtrl: _priceCtrl, category: _category, categories: _categories, onCategoryChange: (v) => setState(() => _category = v)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isLoading ? 'Generating...' : 'Generate Description'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultCard(result: _result!, onCopy: () {
              Clipboard.setData(ClipboardData(text: _result!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
            }, onRegenerate: _generate),
          ],
          const SizedBox(height: 20),
          _TipsCard(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/vendor/ai/pricing'),
            icon: const Icon(Icons.price_change_rounded),
            label: const Text('Also try AI Price Suggestion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryMedium,
              side: const BorderSide(color: AppColors.primaryMedium),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primaryMedium.withValues(alpha: 0.15), AppColors.primaryLight.withValues(alpha: 0.1)]),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Text('✨', style: TextStyle(fontSize: 24)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI-Powered Descriptions', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
        Text('Generate compelling food descriptions that attract more customers using Mistral AI.', style: AppTextStyles.caption),
      ])),
    ]),
  );
}

class _InputForm extends StatelessWidget {
  final TextEditingController nameCtrl, priceCtrl;
  final String category;
  final List<String> categories;
  final void Function(String) onCategoryChange;
  const _InputForm({required this.nameCtrl, required this.priceCtrl, required this.category, required this.categories, required this.onCategoryChange});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Food Item Details', style: AppTextStyles.h5),
      const SizedBox(height: 14),
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Food Item Name *', hintText: 'e.g. Surprise Bakery Bag', border: OutlineInputBorder(), prefixIcon: Icon(Icons.fastfood_rounded))),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: category,
        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_rounded)),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => onCategoryChange(v!),
      ),
      const SizedBox(height: 12),
      TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rescue Price (Rs.)', hintText: 'e.g. 150', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money_rounded))),
    ]),
  );
}

class _ResultCard extends StatelessWidget {
  final String result;
  final VoidCallback onCopy, onRegenerate;
  const _ResultCard({required this.result, required this.onCopy, required this.onRegenerate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryMedium, size: 18),
        const SizedBox(width: 6),
        Text('Generated Description', style: AppTextStyles.h5),
        const Spacer(),
        IconButton(icon: const Icon(Icons.copy_rounded), onPressed: onCopy, tooltip: 'Copy'),
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: onRegenerate, tooltip: 'Regenerate'),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10)),
        child: Text(result, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: onCopy,
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Use This Description'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
      )),
    ]),
  );
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('💡', style: TextStyle(fontSize: 18)), const SizedBox(width: 6), Text('Pro Tips', style: AppTextStyles.label)]),
      const SizedBox(height: 8),
      ...[
        'Be specific about what makes your food special',
        'Mention freshness and quality',
        'Highlight sustainability and waste reduction',
        'Include flavor profiles and textures',
      ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: Colors.amber)), Expanded(child: Text(t, style: AppTextStyles.caption))]))),
    ]),
  );
}
