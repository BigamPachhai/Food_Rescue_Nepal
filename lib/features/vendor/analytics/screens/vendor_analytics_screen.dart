import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

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

class _OverviewTab extends StatelessWidget {
  final String period;
  const _OverviewTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KPIGrid(),
        const SizedBox(height: 16),
        _RevenueChart(),
        const SizedBox(height: 16),
        _TopItemsCard(),
        const SizedBox(height: 16),
        _QuickLinksRow(),
      ],
    );
  }
}

class _KPIGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        _KPICard(title: 'Revenue', value: 'Rs. 8,450', change: '+12%', icon: Icons.attach_money_rounded, positive: true),
        _KPICard(title: 'Orders', value: '47', change: '+8%', icon: Icons.receipt_long_rounded, positive: true),
        _KPICard(title: 'Avg Order Value', value: 'Rs. 180', change: '+3%', icon: Icons.trending_up_rounded, positive: true),
        _KPICard(title: 'Cancellations', value: '3', change: '-2%', icon: Icons.cancel_outlined, positive: false),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title, value, change;
  final IconData icon;
  final bool positive;
  const _KPICard({required this.title, required this.value, required this.change, required this.icon, required this.positive});

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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: AppColors.primaryMedium, size: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (positive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(change, style: TextStyle(fontSize: 11, color: positive ? Colors.green.shade700 : Colors.red, fontWeight: FontWeight.bold)),
            ),
          ]),
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
  @override
  Widget build(BuildContext context) {
    final data = [2100, 3200, 1800, 4100, 2900, 3800, 2400];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);
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
                final h = data[i] / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(data[i] / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 100 * h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryMedium, AppColors.primaryDark],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
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
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Surprise Bag', 18, 'Rs. 3,240'),
      ('Dal Bhat Special', 14, 'Rs. 1,680'),
      ('Café Pastry Box', 9, 'Rs. 2,250'),
      ('Fresh Salad', 6, 'Rs. 1,080'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Items', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.$1, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text('${e.value.$2} orders', style: AppTextStyles.caption),
              ])),
              Text(e.value.$3, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _QuickLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _QuickLink(icon: Icons.bar_chart_rounded, label: 'Revenue\nReport', onTap: () => context.push('/vendor/analytics/revenue')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.schedule_rounded, label: 'Peak\nHours', onTap: () => context.push('/vendor/analytics/peak-hours')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.people_outline_rounded, label: 'Customer\nInsights', onTap: () => context.push('/vendor/customers')),
      const SizedBox(width: 10),
      _QuickLink(icon: Icons.eco_rounded, label: 'Waste\nReport', onTap: () => context.push('/vendor/analytics/waste')),
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

class _RevenueTab extends StatelessWidget {
  final String period;
  const _RevenueTab({required this.period});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _SummaryCard(period: period),
      const SizedBox(height: 16),
      _MonthlyBreakdown(),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String period;
  const _SummaryCard({required this.period});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]), borderRadius: BorderRadius.all(Radius.circular(16))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$period Revenue', style: AppTextStyles.bodySmallOnPrimary),
      Text('Rs. 8,450', style: AppTextStyles.display.copyWith(color: Colors.white)),
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 18),
        SizedBox(width: 4),
        Text('+12% vs last period', style: TextStyle(color: Colors.greenAccent)),
      ]),
    ]),
  );
}

class _MonthlyBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const breakdown = [
      ('Food Sales', 'Rs. 6,800', 0.80),
      ('Packaging Fees', 'Rs. 850', 0.10),
      ('Delivery Commission', 'Rs. 800', 0.10),
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
}

class _OrdersTab extends StatelessWidget {
  final String period;
  const _OrdersTab({required this.period});
  @override
  Widget build(BuildContext context) {
    const statuses = [('Completed', 41, Colors.green), ('Cancelled', 3, Colors.red), ('Expired', 2, Colors.orange), ('Pending', 1, Colors.blue)];
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
  }
}
