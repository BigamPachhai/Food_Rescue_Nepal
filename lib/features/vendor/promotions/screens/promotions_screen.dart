import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';

class _PromoCode {
  final String id, code, discountType;
  final int discountValue, usedCount, minOrderAmount;
  final int? maxUses;
  final DateTime? expiresAt;
  final bool isActive;
  final String? description;
  const _PromoCode({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.usedCount,
    required this.minOrderAmount,
    this.maxUses,
    this.expiresAt,
    required this.isActive,
    this.description,
  });
  factory _PromoCode.fromJson(Map<String, dynamic> j) => _PromoCode(
        id: j['id'] as String,
        code: j['code'] as String,
        discountType: j['discountType'] as String,
        discountValue: (j['discountValue'] as num).toInt(),
        usedCount: (j['usedCount'] as num? ?? 0).toInt(),
        minOrderAmount: (j['minOrderAmount'] as num? ?? 0).toInt(),
        maxUses: j['maxUses'] != null ? (j['maxUses'] as num).toInt() : null,
        expiresAt: j['expiresAt'] != null ? DateTime.tryParse(j['expiresAt'] as String) : null,
        isActive: j['isActive'] as bool? ?? true,
        description: j['description'] as String?,
      );
}

final _promoCodesProvider = FutureProvider.autoDispose<List<_PromoCode>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.myPromoCodes);
  final raw = res.data as Map<String, dynamic>;
  final payload = raw['data'] as Map<String, dynamic>? ?? raw;
  final items = payload['items'] as List? ?? [];
  return items.map((e) => _PromoCode.fromJson(e as Map<String, dynamic>)).toList();
});

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoAsync = ref.watch(_promoCodesProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Promotions Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePromoDialog(context, ref),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Promo', style: TextStyle(color: Colors.white)),
      ),
      body: promoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (promos) => promos.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No promotions yet', style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Tap "+ Create Promo" to add your first promotion', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PromoStats(promos: promos),
                  const SizedBox(height: 16),
                  if (promos.any((p) => p.isActive)) ...[
                    Text('Active Promotions', style: AppTextStyles.h5),
                    const SizedBox(height: 12),
                    ...promos.where((p) => p.isActive).map((p) => _PromoCard(promo: p, ref: ref)),
                    const SizedBox(height: 8),
                  ],
                  if (promos.any((p) => !p.isActive)) ...[
                    Text('Expired / Inactive', style: AppTextStyles.h5),
                    const SizedBox(height: 12),
                    ...promos.where((p) => !p.isActive).map((p) => _PromoCard(promo: p, ref: ref)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  void _showCreatePromoDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatePromoSheet(onCreated: () => ref.invalidate(_promoCodesProvider)),
    );
  }
}

class _PromoStats extends StatelessWidget {
  final List<_PromoCode> promos;
  const _PromoStats({required this.promos});
  @override
  Widget build(BuildContext context) => Row(children: [
    _PStat(value: '${promos.where((p) => p.isActive).length}', label: 'Active', icon: Icons.local_offer_rounded, color: AppColors.primaryMedium),
    const SizedBox(width: 10),
    _PStat(value: '${promos.fold(0, (s, p) => s + p.usedCount)}', label: 'Total Used', icon: Icons.people_rounded, color: Colors.blue),
    const SizedBox(width: 10),
    _PStat(value: '${promos.length}', label: 'Total', icon: Icons.confirmation_number_rounded, color: Colors.orange),
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
  final _PromoCode promo;
  final WidgetRef ref;
  const _PromoCard({required this.promo, required this.ref});

  @override
  Widget build(BuildContext context) {
    final daysLeft = promo.expiresAt?.difference(DateTime.now()).inDays;
    final usePct = promo.maxUses != null && promo.maxUses! > 0 ? promo.usedCount / promo.maxUses! : 0.0;
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
              color: promo.discountType == 'PERCENT' ? Colors.blue.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              promo.discountType == 'PERCENT' ? '-${promo.discountValue}%' : 'Rs. ${promo.discountValue} OFF',
              style: TextStyle(color: promo.discountType == 'PERCENT' ? Colors.blue.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(promo.description ?? promo.code, style: AppTextStyles.label)),
          Switch(
            value: promo.isActive,
            onChanged: (_) => _toggle(context),
            activeThumbColor: AppColors.primaryMedium,
          ),
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
          Text('Used: ${promo.usedCount}${promo.maxUses != null ? "/${promo.maxUses}" : ""}', style: AppTextStyles.caption),
          if (daysLeft != null)
            Text('Expires in $daysLeft days', style: AppTextStyles.caption.copyWith(color: daysLeft <= 3 ? Colors.red : AppColors.textSecondary))
          else
            Text('No expiry', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ]),
        if (promo.maxUses != null) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(value: usePct.toDouble(), backgroundColor: AppColors.backgroundLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium), minHeight: 5, borderRadius: BorderRadius.circular(3)),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ),
      ]),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch(ApiEndpoints.myPromoCodeToggle(promo.id));
      ref.invalidate(_promoCodesProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promo'),
        content: Text('Delete "${promo.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.myPromoCodeDelete(promo.id));
      ref.invalidate(_promoCodesProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _CreatePromoSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreatePromoSheet({required this.onCreated});
  @override
  State<_CreatePromoSheet> createState() => _CreatePromoSheetState();
}

class _CreatePromoSheetState extends State<_CreatePromoSheet> {
  String _type = 'PERCENT';
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty || _valueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in the code and discount value')));
      return;
    }
    setState(() => _saving = true);
    try {
      final container = ProviderScope.containerOf(context);
      final dio = container.read(dioClientProvider);
      await dio.post(ApiEndpoints.myPromoCodes, data: {
        'code': _codeCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'discountType': _type,
        'discountValue': int.parse(_valueCtrl.text.trim()),
        if (_maxUsesCtrl.text.trim().isNotEmpty) 'maxUses': int.parse(_maxUsesCtrl.text.trim()),
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion created!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create Promotion', style: AppTextStyles.h5),
        const SizedBox(height: 16),
        TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Promo Code (e.g. SAVE20)', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'PERCENT', label: Text('% Discount')), ButtonSegment(value: 'FIXED', label: Text('Rs. Off'))],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: _valueCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == 'PERCENT' ? 'Discount %' : 'Amount Off (Rs.)', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _maxUsesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Uses (optional, leave blank for unlimited)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Promotion'),
        )),
        const SizedBox(height: 20),
      ]),
    );
  }
}
