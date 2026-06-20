import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _Promo {
  final String id, name, type, code;
  final double value;
  final int usedCount, maxUses;
  final DateTime expiry;
  final bool isActive;
  const _Promo({required this.id, required this.name, required this.type, required this.code, required this.value, required this.usedCount, required this.maxUses, required this.expiry, required this.isActive});
}

final _promos = [
  _Promo(id: '1', name: 'Weekend Special', type: 'PERCENT', code: 'WEEKEND20', value: 20, usedCount: 12, maxUses: 50, expiry: DateTime.now().add(const Duration(days: 3)), isActive: true),
  _Promo(id: '2', name: 'New Customer', type: 'FIXED', code: 'WELCOME50', value: 50, usedCount: 8, maxUses: 100, expiry: DateTime.now().add(const Duration(days: 30)), isActive: true),
  _Promo(id: '3', name: 'Flash Sale', type: 'PERCENT', code: 'FLASH30', value: 30, usedCount: 25, maxUses: 25, expiry: DateTime.now().add(const Duration(hours: 2)), isActive: false),
];

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Promotions Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePromoDialog(context),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Promo', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PromoStats(),
          const SizedBox(height: 16),
          Text('Active Promotions', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ..._promos.where((p) => p.isActive).map((p) => _PromoCard(promo: p)),
          const SizedBox(height: 8),
          Text('Expired / Inactive', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ..._promos.where((p) => !p.isActive).map((p) => _PromoCard(promo: p)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showCreatePromoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreatePromoSheet(),
    );
  }
}

class _PromoStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    _PStat(value: '${_promos.where((p) => p.isActive).length}', label: 'Active', icon: Icons.local_offer_rounded, color: AppColors.primaryMedium),
    const SizedBox(width: 10),
    _PStat(value: '${_promos.fold(0, (s, p) => s + p.usedCount)}', label: 'Total Used', icon: Icons.people_rounded, color: Colors.blue),
    const SizedBox(width: 10),
    const _PStat(value: 'Rs. 0', label: 'Discount Given', icon: Icons.attach_money_rounded, color: Colors.orange),
  ]);
}

class _PStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _PStat({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _PromoCard extends StatelessWidget {
  final _Promo promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiry.difference(DateTime.now()).inDays;
    final usePct = promo.usedCount / promo.maxUses;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: promo.isActive ? AppColors.primaryMedium.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: promo.type == 'PERCENT' ? Colors.blue.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              promo.type == 'PERCENT' ? '-${promo.value.toInt()}%' : 'Rs. ${promo.value.toInt()} OFF',
              style: TextStyle(color: promo.type == 'PERCENT' ? Colors.blue.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(promo.name, style: AppTextStyles.label)),
          Switch(value: promo.isActive, onChanged: (_) {}, activeThumbColor: AppColors.primaryMedium),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3), style: BorderStyle.solid),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(promo.code, style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.primaryDark)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Used: ${promo.usedCount}/${promo.maxUses}', style: AppTextStyles.caption),
          Text('Expires in $daysLeft days', style: AppTextStyles.caption.copyWith(color: daysLeft <= 3 ? Colors.red : AppColors.textSecondary)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: usePct, backgroundColor: AppColors.backgroundLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium), minHeight: 5, borderRadius: BorderRadius.circular(3)),
      ]),
    );
  }
}

class _CreatePromoSheet extends StatefulWidget {
  const _CreatePromoSheet();
  @override
  State<_CreatePromoSheet> createState() => _CreatePromoSheetState();
}

class _CreatePromoSheetState extends State<_CreatePromoSheet> {
  String _type = 'PERCENT';
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Promotion', style: AppTextStyles.h5),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Promotion Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'PERCENT', label: Text('% Discount')), ButtonSegment(value: 'FIXED', label: Text('Rs. Off'))],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: _valueCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == 'PERCENT' ? 'Discount %' : 'Amount Off (Rs.)', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Promo Code (e.g. SAVE20)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion created!'))); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Create Promotion'),
        )),
        const SizedBox(height: 20),
      ]),
    );
  }
}
