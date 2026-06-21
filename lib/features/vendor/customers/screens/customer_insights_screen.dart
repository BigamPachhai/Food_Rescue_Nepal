import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../orders/providers/vendor_orders_provider.dart';

class CustomerInsightsScreen extends ConsumerWidget {
  const CustomerInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Customer Insights')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (orders) {
          final insights = _CustomerInsights.from(orders);
          return _InsightsBody(insights: insights);
        },
      ),
    );
  }
}

class _CustomerInsights {
  final int totalCustomers;
  final int completedOrders;
  final int cancelledOrders;
  final double retentionRate;
  final double avgOrderValue;
  final List<_TopCustomer> topCustomers;
  final Map<String, int> listingOrderCounts;
  final int newCustomersThisMonth;

  const _CustomerInsights({
    required this.totalCustomers,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.retentionRate,
    required this.avgOrderValue,
    required this.topCustomers,
    required this.listingOrderCounts,
    required this.newCustomersThisMonth,
  });

  factory _CustomerInsights.from(List<VendorOrder> orders) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Aggregate by customer
    final customerMap = <String, _CustomerAgg>{};
    for (final o in orders) {
      customerMap.putIfAbsent(o.customerId, () => _CustomerAgg(o.customerId));
      customerMap[o.customerId]!.add(o);
    }

    final allCustomers = customerMap.values.toList();
    final totalCustomers = allCustomers.length;

    // Retention: customers with >1 completed order
    final returningCount = allCustomers.where((c) => c.completedOrders > 1).length;
    final retentionRate = totalCustomers > 0 ? returningCount / totalCustomers : 0.0;

    // New customers this month: first order in this month
    final newThisMonth = allCustomers.where((c) => c.firstOrderDate.isAfter(monthStart)).length;

    // Average order value across all completed orders
    final completedList = orders.where((o) => o.status == 'COMPLETED').toList();
    final avgOrderValue = completedList.isEmpty
        ? 0.0
        : completedList.map((o) => o.totalAmount).reduce((a, b) => a + b) / completedList.length;

    // Top 5 customers by completed order count
    allCustomers.sort((a, b) => b.completedOrders.compareTo(a.completedOrders));
    final topCustomers = allCustomers.take(5).map((c) {
      final label = c.name.isNotEmpty ? c.name : 'Customer';
      final daysSince = now.difference(c.lastOrderDate).inDays;
      final lastStr = daysSince == 0
          ? 'Today'
          : daysSince == 1
              ? '1 day ago'
              : '$daysSince days ago';
      return _TopCustomer(
        name: label,
        orderCount: c.completedOrders,
        totalSpent: c.totalSpent,
        lastOrder: lastStr,
      );
    }).toList();

    // Listing popularity by order count
    final listingCounts = <String, int>{};
    for (final o in completedList) {
      final name = o.listing?.name ?? 'Unknown';
      listingCounts[name] = (listingCounts[name] ?? 0) + 1;
    }

    return _CustomerInsights(
      totalCustomers: totalCustomers,
      completedOrders: completedList.length,
      cancelledOrders: orders.where((o) => o.status == 'CANCELLED').length,
      retentionRate: retentionRate,
      avgOrderValue: avgOrderValue,
      topCustomers: topCustomers,
      listingOrderCounts: listingCounts,
      newCustomersThisMonth: newThisMonth,
    );
  }
}

class _CustomerAgg {
  final String customerId;
  String name = '';
  int completedOrders = 0;
  int totalSpent = 0;
  DateTime firstOrderDate = DateTime.now();
  DateTime lastOrderDate = DateTime.fromMillisecondsSinceEpoch(0);

  _CustomerAgg(this.customerId);

  void add(VendorOrder o) {
    if (name.isEmpty) {
      name = o.customerName?.isNotEmpty == true
          ? o.customerName!
          : 'Customer #${customerId.substring(0, 6)}';
    }
    if (o.createdAt.isBefore(firstOrderDate)) firstOrderDate = o.createdAt;
    if (o.createdAt.isAfter(lastOrderDate)) lastOrderDate = o.createdAt;
    if (o.status == 'COMPLETED') {
      completedOrders++;
      totalSpent += o.totalAmount;
    }
  }
}

class _TopCustomer {
  final String name;
  final int orderCount;
  final int totalSpent;
  final String lastOrder;
  const _TopCustomer({required this.name, required this.orderCount, required this.totalSpent, required this.lastOrder});
}

class _InsightsBody extends StatelessWidget {
  final _CustomerInsights insights;
  const _InsightsBody({required this.insights});

  @override
  Widget build(BuildContext context) {
    final sortedListings = insights.listingOrderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _StatCard('${insights.totalCustomers}', 'Total Customers', Icons.people_rounded, AppColors.primaryMedium),
            _StatCard('${insights.newCustomersThisMonth}', 'New This Month', Icons.person_add_rounded, Colors.blue),
            _StatCard('${insights.completedOrders}', 'Completed Orders', Icons.check_circle_outline_rounded, Colors.green),
            _StatCard('${(insights.retentionRate * 100).toStringAsFixed(0)}%', 'Retention Rate', Icons.loop_rounded, Colors.orange),
          ],
        ),
        const SizedBox(height: 20),

        // Order Patterns
        Text('Order Patterns', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _PatternRow('Average Order Value', 'NPR ${insights.avgOrderValue.toStringAsFixed(0)}'),
            const Divider(height: 20),
            _PatternRow('Total Orders Completed', '${insights.completedOrders}'),
            const Divider(height: 20),
            _PatternRow('Orders Cancelled', '${insights.cancelledOrders}'),
            const Divider(height: 20),
            _PatternRow('Repeat Purchase Rate', '${(insights.retentionRate * 100).toStringAsFixed(0)}%'),
          ]),
        ),
        const SizedBox(height: 20),

        // Top Customers
        if (insights.topCustomers.isNotEmpty) ...[
          Text('Top Customers', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ...insights.topCustomers.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Column(children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15),
                      child: Text('${i + 1}', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(c.name, style: AppTextStyles.label),
                    subtitle: Text('${c.orderCount} orders • Last: ${c.lastOrder}', style: AppTextStyles.caption),
                    trailing: Text('NPR ${c.totalSpent}', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
                  ),
                  if (i < insights.topCustomers.length - 1) const Divider(height: 1, indent: 56),
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Popular listings
        if (sortedListings.isNotEmpty) ...[
          Text('Popular Items', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedListings.take(10).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${t.key} (${t.value})', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.w500, fontSize: 12)),
              )).toList(),
            ),
          ),
        ],

        if (insights.totalCustomers == 0) ...[
          const SizedBox(height: 40),
          const Center(child: Text('No orders yet. Insights will appear once you receive orders.', textAlign: TextAlign.center)),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _PatternRow extends StatelessWidget {
  final String label, value;
  const _PatternRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
    Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
  ]);
}
