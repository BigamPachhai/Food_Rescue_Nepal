import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class SpendingAnalyticsData {
  final int totalSpentPaisa;
  final int totalOrders;
  final int totalSavedPaisa;
  final double avgOrderValue;
  final Map<String, int> byCategory;
  final List<Map<String, dynamic>> recentOrders;

  const SpendingAnalyticsData({
    required this.totalSpentPaisa,
    required this.totalOrders,
    required this.totalSavedPaisa,
    required this.avgOrderValue,
    required this.byCategory,
    required this.recentOrders,
  });
}

final spendingAnalyticsProvider = FutureProvider<SpendingAnalyticsData>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.customerOrders, queryParameters: {'limit': 100, 'status': 'COMPLETED'});
  final raw = res.data as Map<String, dynamic>;
  final dataMap = raw['data'] as Map<String, dynamic>? ?? {};
  final items = (dataMap['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

  int total = 0;
  final byCategory = <String, int>{};
  for (final o in items) {
    final amt = (o['totalAmount'] as num?)?.toInt() ?? 0;
    total += amt;
    final cat = (o['listing'] as Map<String, dynamic>?)?['category'] as String? ?? 'Other';
    byCategory[cat] = (byCategory[cat] ?? 0) + amt;
  }
  final originalTotal = items.fold<int>(0, (sum, o) => sum + ((o['originalAmount'] as num?)?.toInt() ?? (o['totalAmount'] as num?)?.toInt() ?? 0));

  return SpendingAnalyticsData(
    totalSpentPaisa: total,
    totalOrders: items.length,
    totalSavedPaisa: originalTotal - total,
    avgOrderValue: items.isEmpty ? 0 : total / items.length,
    byCategory: byCategory,
    recentOrders: items.take(5).toList(),
  );
});

class SpendingAnalyticsScreen extends ConsumerWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(spendingAnalyticsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(spendingAnalyticsProvider))],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(children: [
                Expanded(child: _SummaryCard(label: 'Total Spent', value: 'Rs.${(data.totalSpentPaisa / 100).toStringAsFixed(0)}', icon: Icons.payments, color: colorScheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(label: 'Orders', value: '${data.totalOrders}', icon: Icons.receipt_long, color: Colors.blue)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _SummaryCard(label: 'Money Saved', value: 'Rs.${(data.totalSavedPaisa / 100).toStringAsFixed(0)}', icon: Icons.savings, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(label: 'Avg Order', value: 'Rs.${(data.avgOrderValue / 100).toStringAsFixed(0)}', icon: Icons.trending_up, color: Colors.orange)),
              ]),
              const SizedBox(height: 24),

              if (data.byCategory.isNotEmpty) ...[
                const Text('Spending by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...(data.byCategory.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(6)
                    .map((e) {
                  final pct = data.totalSpentPaisa > 0 ? e.value / data.totalSpentPaisa : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                            Text('Rs.${(e.value / 100).toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.grey[200]),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              if (data.recentOrders.isNotEmpty) ...[
                const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...data.recentOrders.map((o) {
                  final listing = o['listing'] as Map<String, dynamic>? ?? {};
                  final amt = (o['totalAmount'] as num?)?.toInt() ?? 0;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.fastfood),
                    title: Text(listing['name'] as String? ?? 'Order'),
                    subtitle: Text(listing['category'] as String? ?? ''),
                    trailing: Text('Rs.${(amt / 100).toStringAsFixed(0)}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
}
