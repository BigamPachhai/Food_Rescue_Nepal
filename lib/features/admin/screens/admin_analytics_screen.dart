import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _period = 'This Month';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
        title: const Text('Platform Analytics'),
        actions: [
          DropdownButton<String>(
            value: _period,
            underline: const SizedBox(),
            items: ['Today', 'This Week', 'This Month', 'This Year']
                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTextStyles.bodySmall)))
                .toList(),
            onChanged: (v) => setState(() => _period = v!),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Users'), Tab(text: 'Revenue'), Tab(text: 'Food Saved')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(period: _period),
          _UsersTab(),
          _RevenueTab(),
          _FoodSavedTab(),
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
        _PlatformKPIs(),
        const SizedBox(height: 16),
        _GrowthChart(),
        const SizedBox(height: 16),
        _TopVendors(),
        const SizedBox(height: 16),
        _GeographicBreakdown(),
      ],
    );
  }
}

class _PlatformKPIs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, childAspectRatio: 1.4, mainAxisSpacing: 12, crossAxisSpacing: 12,
      children: const [
        _KPI(label: 'Total Users', value: '4,821', change: '+18%', icon: Icons.people_rounded, positive: true),
        _KPI(label: 'Active Vendors', value: '142', change: '+12%', icon: Icons.store_rounded, positive: true),
        _KPI(label: 'Orders This Month', value: '3,240', change: '+24%', icon: Icons.receipt_long_rounded, positive: true),
        _KPI(label: 'Platform Revenue', value: 'Rs. 182K', change: '+31%', icon: Icons.attach_money_rounded, positive: true),
        _KPI(label: 'Meals Rescued', value: '12,840', change: '+28%', icon: Icons.restaurant_rounded, positive: true),
        _KPI(label: 'CO₂ Saved (kg)', value: '32,100', change: '+28%', icon: Icons.eco_rounded, positive: true),
      ],
    );
  }
}

class _KPI extends StatelessWidget {
  final String label, value, change;
  final IconData icon;
  final bool positive;
  const _KPI({required this.label, required this.value, required this.change, required this.icon, required this.positive});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: AppColors.primaryMedium, size: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: (positive ? Colors.green : Colors.red).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(change, style: TextStyle(fontSize: 10, color: positive ? Colors.green.shade700 : Colors.red, fontWeight: FontWeight.bold)),
        ),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
        Text(label, style: AppTextStyles.caption),
      ]),
    ]),
  );
}

class _GrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final users = [280, 420, 650, 890, 1240, 1680];
    final orders = [180, 310, 520, 780, 1100, 1420];
    const maxVal = 1680;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Platform Growth', style: AppTextStyles.h5),
        const SizedBox(height: 8),
        const Row(children: [
          _Legend(color: AppColors.primaryMedium, label: 'Users'),
          SizedBox(width: 16),
          _Legend(color: Colors.orange, label: 'Orders'),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(6, (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Stack(
                    children: [
                      Container(height: 120 * users[i] / maxVal, color: AppColors.primaryMedium.withValues(alpha: 0.3)),
                      Container(height: 120 * orders[i] / maxVal, color: AppColors.primaryMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(months[i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _TopVendors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const vendors = [
      ('Himalayan Bakes', 'Bakery', 342, 'Rs. 61,560'),
      ('Thakali Kitchen', 'Restaurant', 289, 'Rs. 34,680'),
      ('Green Farm Store', 'Grocery', 241, 'Rs. 48,200'),
      ('Mountain Brew Café', 'Cafe', 198, 'Rs. 49,500'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Vendors This Month', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        ...vendors.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text('${e.key + 1}', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.$1, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Text(e.value.$2, style: AppTextStyles.caption),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${e.value.$3} orders', style: AppTextStyles.caption),
              Text(e.value.$4, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _GeographicBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const areas = [
      ('Kathmandu', 45),
      ('Lalitpur', 28),
      ('Bhaktapur', 15),
      ('Kirtipur', 8),
      ('Other', 4),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Orders by Area', style: AppTextStyles.h5),
        const SizedBox(height: 12),
        ...areas.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(a.$1, style: AppTextStyles.bodySmall),
              Text('${a.$2}%', style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 3),
            LinearProgressIndicator(value: a.$2 / 100, backgroundColor: AppColors.backgroundLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ]),
        )),
      ]),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _UserGrowthCard(),
      const SizedBox(height: 16),
      _UserTypeBreakdown(),
    ]);
  }
}

class _UserGrowthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Total Users', style: AppTextStyles.bodySmallOnPrimary),
      Text('4,821', style: AppTextStyles.display.copyWith(color: Colors.white)),
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 18),
        SizedBox(width: 4),
        Text('+18% this month', style: TextStyle(color: Colors.greenAccent)),
      ]),
      const SizedBox(height: 12),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _UStatPill(label: 'Customers', value: '4,321'),
        _UStatPill(label: 'Vendors', value: '487'),
        _UStatPill(label: 'Admins', value: '13'),
      ]),
    ]),
  );
}

class _UStatPill extends StatelessWidget {
  final String label, value;
  const _UStatPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h4OnPrimary),
    Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
  ]);
}

class _UserTypeBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('New Users This Week', style: AppTextStyles.h5),
      const SizedBox(height: 12),
      ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].asMap().entries.map((e) {
        final vals = [45, 62, 38, 71, 84, 96, 52];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 32, child: Text(e.value, style: AppTextStyles.caption)),
            Expanded(child: LinearProgressIndicator(value: vals[e.key] / 100, backgroundColor: AppColors.backgroundLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium), minHeight: 14, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Text('${vals[e.key]}', style: AppTextStyles.caption),
          ]),
        );
      }),
    ]),
  );
}

class _RevenueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade500]), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Platform Revenue', style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text('Rs. 182,400', style: AppTextStyles.display.copyWith(color: Colors.white)),
        const SizedBox(height: 4),
        const Text('+31% vs last month', style: TextStyle(color: Colors.greenAccent)),
      ]),
    ),
  ]);
}

class _FoodSavedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade700, AppColors.primaryMedium]), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
        const SizedBox(height: 8),
        Text('12,840 Meals Rescued', style: AppTextStyles.h3OnPrimary),
        Text('This Month', style: AppTextStyles.bodySmallOnPrimary),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ImpactPill(value: '32,100 kg', label: 'CO₂ Saved'),
          _ImpactPill(value: '1.5M L', label: 'Water Saved'),
          _ImpactPill(value: 'Rs. 2.1M', label: 'Value Rescued'),
        ]),
      ]),
    ),
  ]);
}

class _ImpactPill extends StatelessWidget {
  final String value, label;
  const _ImpactPill({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h5OnPrimary),
    Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
  ]);
}
