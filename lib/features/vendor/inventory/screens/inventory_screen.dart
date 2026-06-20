import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _InventoryItem {
  final String id, name, category;
  final int quantity, alertThreshold;
  final double price;
  final String status;
  const _InventoryItem({required this.id, required this.name, required this.category, required this.quantity, required this.alertThreshold, required this.price, required this.status});
  bool get isLow => quantity <= alertThreshold;
  bool get isOut => quantity == 0;
}

const _items = [
  _InventoryItem(id: '1', name: 'Surprise Bakery Bag', category: 'Bakery', quantity: 8, alertThreshold: 3, price: 180, status: 'ACTIVE'),
  _InventoryItem(id: '2', name: 'Dal Bhat Set', category: 'Restaurant', quantity: 2, alertThreshold: 3, price: 120, status: 'ACTIVE'),
  _InventoryItem(id: '3', name: 'Fresh Bread Loaf', category: 'Bakery', quantity: 0, alertThreshold: 2, price: 80, status: 'INACTIVE'),
  _InventoryItem(id: '4', name: 'Café Pastry Box', category: 'Cafe', quantity: 15, alertThreshold: 5, price: 250, status: 'ACTIVE'),
  _InventoryItem(id: '5', name: 'Vegetable Curry', category: 'Restaurant', quantity: 1, alertThreshold: 2, price: 100, status: 'ACTIVE'),
];

final _filterProvider = StateProvider<String>((ref) => 'All');

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);
    final filtered = filter == 'All'
        ? _items
        : filter == 'Low Stock'
            ? _items.where((i) => i.isLow && !i.isOut).toList()
            : filter == 'Out of Stock'
                ? _items.where((i) => i.isOut).toList()
                : _items.where((i) => !i.isLow).toList();

    final lowCount = _items.where((i) => i.isLow).length;
    final outCount = _items.where((i) => i.isOut).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_rounded), onPressed: () {}, tooltip: 'Stock Alerts'),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () {}, tooltip: 'Add Item'),
        ],
      ),
      body: Column(
        children: [
          if (lowCount > 0 || outCount > 0)
            _AlertBanner(lowCount: lowCount, outCount: outCount),
          _SummaryRow(items: _items.toList()),
          _FilterChips(filter: filter, onFilter: (f) => ref.read(_filterProvider.notifier).state = f),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _InventoryCard(item: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int lowCount, outCount;
  const _AlertBanner({required this.lowCount, required this.outCount});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: Colors.orange.shade50,
    child: Row(children: [
      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
      const SizedBox(width: 8),
      Expanded(child: Text(
        '${outCount > 0 ? "$outCount out of stock • " : ""}$lowCount items running low',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.orange.shade800),
      )),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final List<_InventoryItem> items;
  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    color: Colors.white,
    child: Row(children: [
      _SumCard(label: 'Total Items', value: '${items.length}', color: AppColors.primaryMedium),
      const SizedBox(width: 8),
      _SumCard(label: 'Active', value: '${items.where((i) => i.status == 'ACTIVE').length}', color: Colors.green),
      const SizedBox(width: 8),
      _SumCard(label: 'Low Stock', value: '${items.where((i) => i.isLow && !i.isOut).length}', color: Colors.orange),
      const SizedBox(width: 8),
      _SumCard(label: 'Out of Stock', value: '${items.where((i) => i.isOut).length}', color: Colors.red),
    ]),
  );
}

class _SumCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: AppTextStyles.h5.copyWith(color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  final String filter;
  final void Function(String) onFilter;
  const _FilterChips({required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: ['All', 'Low Stock', 'Out of Stock', 'In Stock'].map((f) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(f),
        selected: filter == f,
        onSelected: (_) => onFilter(f),
        selectedColor: AppColors.primaryMedium.withValues(alpha: 0.2),
      ),
    )).toList()),
  );
}

class _InventoryCard extends StatelessWidget {
  final _InventoryItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isOut ? Colors.red : item.isLow ? Colors.orange : Colors.green;
    final statusLabel = item.isOut ? 'Out of Stock' : item.isLow ? 'Low Stock' : 'In Stock';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isLow ? statusColor.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryMedium),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(item.category, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            Text('${item.quantity} left', style: AppTextStyles.caption),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Rs. ${item.price.toInt()}', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 4),
          Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {}),
            Text('${item.quantity}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.green), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {}),
          ]),
        ]),
      ]),
    );
  }
}
