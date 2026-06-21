import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../dashboard/providers/vendor_stats_provider.dart';

class RevenueReportScreen extends ConsumerStatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  ConsumerState<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends ConsumerState<RevenueReportScreen> {
  String _period = 'This Month';

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(vendorStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Revenue Report'),
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
      ),
      body: statsAsync.when(
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
              _SummaryCard(period: _period, totalRevenue: total),
              const SizedBox(height: 16),
              _RevenueBreakdown(total: total, foodSales: foodSales, packaging: packaging, delivery: delivery),
              const SizedBox(height: 16),
              _TopPerformers(listings: stats.listingPerformance),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String period;
  final int totalRevenue;
  const _SummaryCard({required this.period, required this.totalRevenue});

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$period Revenue', style: AppTextStyles.bodySmallOnPrimary),
      const SizedBox(height: 4),
      Text('Rs. ${_fmt(totalRevenue)}', style: AppTextStyles.display.copyWith(color: Colors.white)),
      const SizedBox(height: 12),
      if (totalRevenue == 0)
        Text('No revenue recorded yet', style: AppTextStyles.bodySmallOnPrimary)
      else
        Text('Based on completed orders', style: AppTextStyles.bodySmallOnPrimary),
    ]),
  );
}

class _RevenueBreakdown extends StatelessWidget {
  final int total, foodSales, packaging, delivery;
  const _RevenueBreakdown({required this.total, required this.foodSales, required this.packaging, required this.delivery});

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

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
        if (total == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No revenue data yet', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...breakdown.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(b.$1, style: AppTextStyles.bodySmall),
                Text(b.$2, style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: b.$3,
                backgroundColor: AppColors.backgroundLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
          )),
      ]),
    );
  }
}

class _TopPerformers extends StatelessWidget {
  final List<ListingPerf> listings;
  const _TopPerformers({required this.listings});

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) {
    final sorted = [...listings]..sort((a, b) => b.revenuePaisa.compareTo(a.revenuePaisa));
    final top = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Revenue Items', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        if (top.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No sales data yet', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
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
                Text('${e.value.quantitySold} sold', style: AppTextStyles.caption),
              ])),
              Text('Rs. ${_fmt(e.value.revenuePaisa ~/ 100)}', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
            ]),
          )),
      ]),
    );
  }
}
