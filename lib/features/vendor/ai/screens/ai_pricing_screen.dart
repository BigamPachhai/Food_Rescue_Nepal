import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/mistral_service.dart';

class AiPricingScreen extends ConsumerStatefulWidget {
  const AiPricingScreen({super.key});

  @override
  ConsumerState<AiPricingScreen> createState() => _AiPricingScreenState();
}

class _AiPricingScreenState extends ConsumerState<AiPricingScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _getSuggestion() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (name.isEmpty || price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in item name and original price')));
      return;
    }
    setState(() { _isLoading = true; _result = null; });
    final result = await ref.read(mistralServiceProvider).suggestPrice(name, price, qty);
    if (mounted) setState(() { _isLoading = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.price_change_rounded, color: AppColors.primaryMedium, size: 20),
          SizedBox(width: 8),
          Text('AI Price Suggestion'),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PricingBanner(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Item Details', style: AppTextStyles.h5),
              const SizedBox(height: 14),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.fastfood_rounded))),
              const SizedBox(height: 12),
              TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Original Price (Rs.) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money_rounded))),
              const SizedBox(height: 12),
              TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity Remaining', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_rounded))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _getSuggestion,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology_rounded),
              label: Text(_isLoading ? 'Analyzing...' : 'Get AI Price Suggestion'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text('AI Recommendation', style: AppTextStyles.h5),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.copy_rounded), onPressed: () {
                    Clipboard.setData(ClipboardData(text: _result!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                  }),
                ]),
                const SizedBox(height: 10),
                Text(_result!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          _PricingGuide(),
        ],
      ),
    );
  }
}

class _PricingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.green.shade700, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Text('💰', style: TextStyle(fontSize: 32)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Smart Pricing with AI', style: AppTextStyles.h5OnPrimary),
        Text('Get the optimal rescue price based on your item, quantity, and market trends.', style: AppTextStyles.bodySmallOnPrimary),
      ])),
    ]),
  );
}

class _PricingGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const guide = [
      ('Expiring Today', '60-75% off', Colors.red),
      ('Expires Tomorrow', '40-60% off', Colors.orange),
      ('2-3 Days Left', '25-40% off', Colors.amber),
      ('This Week', '15-25% off', Colors.green),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('General Pricing Guide', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        ...guide.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: g.$3, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(g.$1, style: AppTextStyles.bodySmall)),
            Text(g.$2, style: AppTextStyles.label.copyWith(color: g.$3)),
          ]),
        )),
      ]),
    );
  }
}
