import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../dashboard/providers/vendor_stats_provider.dart';
import '../../orders/providers/vendor_orders_provider.dart';

class VendorAnalyticsScreen extends ConsumerStatefulWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  ConsumerState<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends ConsumerState<VendorAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _period = 'This Week';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (v) => setState(() => _period = v),
            itemBuilder: (_) => ['Today', 'This Week', 'This Month', 'This Year']
                .map((p) => PopupMenuItem(value: p, child: Text(p)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text(_period, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
                const Icon(Icons.arrow_drop_down_rounded),
              ]),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Revenue'), Tab(text: 'Orders')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(period: _period),
          _RevenueTab(period: _period),
          _OrdersTab(period: _period),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String period;
  const _OverviewTab({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load stats: $e')),
      data: (stats) => ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders: $e')),
        data: (orders) {
          final totalRevenue = stats.totalRevenuePaisa ~/ 100;
          final completedOrders = stats.completedPickups;
          final avgOrderValue = completedOrders > 0 ? totalRevenue ~/ completedOrders : 0;
          final cancelled = orders.where((o) => o.status == 'CANCELLED').length;

          final weeklyData = _buildWeeklyRevenue(orders);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _KPIGrid(
                revenue: totalRevenue,
                orders: completedOrders,
                avgOrderValue: avgOrderValue,
                cancellations: cancelled,
              ),
              const SizedBox(height: 16),
              _RevenueChart(weeklyData: weeklyData),
              const SizedBox(height: 16),
              _TopItemsCard(listings: stats.listingPerformance),
              const SizedBox(height: 16),
              _QuickLinksRow(),
            ],
          );
        },
      ),
    );
  }

  List<int> _buildWeeklyRevenue(List<VendorOrder> orders) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final daily = List<int>.filled(7, 0);
    for (final o in orders) {
      if (o.status != 'COMPLETED') continue;
      final diff = o.createdAt.difference(DateTime(weekStart.year, weekStart.month, weekStart.day)).inDays;
      if (diff >= 0 && diff < 7) {
        daily[diff] += o.totalAmount ~/ 100;
      }
    }
    return daily;
  }
}

class _KPIGrid extends StatelessWidget {
  final int revenue;
  final int orders;
  final int avgOrderValue;
  final int cancellations;

  const _KPIGrid({
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
    required this.cancellations,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _KPICard(title: 'Revenue', value: 'Rs. ${_fmt(revenue)}', icon: Icons.attach_money_rounded),
        _KPICard(title: 'Orders', value: '$orders', icon: Icons.receipt_long_rounded),
        _KPICard(title: 'Avg Order Value', value: 'Rs. ${_fmt(avgOrderValue)}', icon: Icons.trending_up_rounded),
        _KPICard(title: 'Cancellations', value: '$cancellations', icon: Icons.cancel_outlined, negative: true),
      ],
    );
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
}

class _KPICard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final bool negative;
  const _KPICard({required this.title, required this.value, required this.icon, this.negative = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: negative ? Colors.red.shade400 : AppColors.primaryMedium, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
              Text(title, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<int> weeklyData;
  const _RevenueChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = weeklyData.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue This Week', style: AppTextStyles.h5),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = maxVal > 0 ? weeklyData[i] / maxVal : 0.0;
                final label = weeklyData[i] >= 1000
                    ? '${(weeklyData[i] / 1000).toStringAsFixed(1)}k'
                    : '${weeklyData[i]}';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Flexible(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: 100 * h,
                            constraints: const BoxConstraints(maxHeight: 100),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryMedium, AppColors.primaryDark],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  final List<ListingPerf> listings;
  const _TopItemsCard({required this.listings});

  @override
  Widget build(BuildContext context) {
    final sorted = [...listings]..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    final top = sorted.take(4).toList();

    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Selling Items', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            const Center(child: Text('No sales data yet', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Items', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text('${e.value.quantitySold} orders', style: AppTextStyles.caption),
              ])),
              Text('Rs. ${_fmt(e.value.revenuePaisa ~/ 100)}', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
            ]),
          )),
        ],
      ),
    );
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
}

class _QuickLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _QuickLink(icon: Icons.bar_chart_rounded, label: 'Revenue\nReport', onTap: () => context.push('/vendor/analytics/revenue-report')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.schedule_rounded, label: 'Peak\nHours', onTap: () => context.push('/vendor/analytics/peak-hours')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.people_outline_rounded, label: 'Customer\nInsights', onTap: () => context.push('/vendor/customers')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.eco_rounded, label: 'Waste\nReport', onTap: () => context.push('/vendor/analytics/waste-report')),
    ]);
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: AppColors.primaryMedium, size: 24),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

class _RevenueTab extends ConsumerWidget {
  final String period;
  const _RevenueTab({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (stats) {
        final total = stats.totalRevenuePaisa ~/ 100;
        final foodSales = (total * 0.80).round();
        final packaging = (total * 0.10).round();
        final delivery = total - foodSales - packaging;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(period: period, totalRevenue: total),
            const SizedBox(height: 16),
            _MonthlyBreakdown(total: total, foodSales: foodSales, packaging: packaging, delivery: delivery),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String period;
  final int totalRevenue;
  const _SummaryCard({required this.period, required this.totalRevenue});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]), borderRadius: BorderRadius.all(Radius.circular(16))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$period Revenue', style: AppTextStyles.bodySmallOnPrimary),
      Text('Rs. ${_fmt(totalRevenue)}', style: AppTextStyles.display.copyWith(color: Colors.white)),
    ]),
  );

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
}

class _MonthlyBreakdown extends StatelessWidget {
  final int total;
  final int foodSales;
  final int packaging;
  final int delivery;

  const _MonthlyBreakdown({required this.total, required this.foodSales, required this.packaging, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final breakdown = [
      ('Food Sales', 'Rs. ${_fmt(foodSales)}', total > 0 ? foodSales / total : 0.0),
      ('Packaging Fees', 'Rs. ${_fmt(packaging)}', total > 0 ? packaging / total : 0.0),
      ('Delivery Commission', 'Rs. ${_fmt(delivery)}', total > 0 ? delivery / total : 0.0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Revenue Breakdown', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        ...breakdown.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(b.$1, style: AppTextStyles.bodySmall),
              Text(b.$2, style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: b.$3, backgroundColor: AppColors.backgroundLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ]),
        )),
      ]),
    );
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
}

class _OrdersTab extends ConsumerWidget {
  final String period;
  const _OrdersTab({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (orders) {
        final completed = orders.where((o) => o.status == 'COMPLETED').length;
        final cancelled = orders.where((o) => o.status == 'CANCELLED').length;
        final expired = orders.where((o) => o.status == 'EXPIRED').length;
        final pending = orders.where((o) => o.status == 'PENDING' || o.status == 'RESERVED').length;

        final statuses = [
          ('Completed', completed, Colors.green),
          ('Cancelled', cancelled, Colors.red),
          ('Expired', expired, Colors.orange),
          ('Pending', pending, Colors.blue),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order Status Breakdown', style: AppTextStyles.h5),
                const SizedBox(height: 14),
                ...statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.$1, style: AppTextStyles.bodySmall)),
                    Text('${s.$2}', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
                  ]),
                )),
              ]),
            ),
          ],
        );
      },
    );
  }
}
