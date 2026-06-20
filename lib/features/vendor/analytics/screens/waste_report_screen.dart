import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class WasteReportScreen extends StatefulWidget {
  const WasteReportScreen({super.key});

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  String _period = 'This Month';

  static const _categories = [
    _WasteItem('Dairy Products', 12, 8, Colors.blue),
    _WasteItem('Bakery Items', 28, 22, Colors.orange),
    _WasteItem('Prepared Meals', 8, 6, Colors.purple),
    _WasteItem('Fruits & Veggies', 18, 15, Colors.green),
    _WasteItem('Beverages', 5, 4, Colors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    final totalListed = _categories.fold(0, (s, c) => s + c.listed);
    final totalSold = _categories.fold(0, (s, c) => s + c.sold);
    final wasted = totalListed - totalSold;
    final rescueRate = totalSold / totalListed;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Waste Report'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (v) => setState(() => _period = v),
            itemBuilder: (_) => ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                .map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_period, style: const TextStyle(color: AppColors.primaryMedium)),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryBanner(totalListed: totalListed, totalSold: totalSold, wasted: wasted, rescueRate: rescueRate),
          const SizedBox(height: 20),
          Text('Waste by Category', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _categories.map((c) => _CategoryRow(item: c)).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Top Wasted Items', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ...[
            ('Chocolate Croissant', 6, 'Bakery Items'),
            ('Strawberry Cheesecake', 4, 'Bakery Items'),
            ('Whole Milk 1L', 3, 'Dairy Products'),
            ('Veg Momo Set', 2, 'Prepared Meals'),
          ].map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$1, style: AppTextStyles.label),
                Text(item.$3, style: AppTextStyles.caption),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${item.$2} wasted', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          )),
          const SizedBox(height: 20),
          _TipsCard(),
        ],
      ),
    );
  }
}

class _WasteItem {
  final String name;
  final int listed, sold;
  final Color color;
  const _WasteItem(this.name, this.listed, this.sold, this.color);
  int get wasted => listed - sold;
  double get rate => sold / listed;
}

class _SummaryBanner extends StatelessWidget {
  final int totalListed, totalSold, wasted;
  final double rescueRate;
  const _SummaryBanner({required this.totalListed, required this.totalSold, required this.wasted, required this.rescueRate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.recycling_rounded, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text('Rescue Rate', style: AppTextStyles.h5OnPrimary),
      ]),
      const SizedBox(height: 8),
      Text('${(rescueRate * 100).toStringAsFixed(1)}%', style: AppTextStyles.h1OnPrimary),
      const SizedBox(height: 4),
      Text('$totalSold of $totalListed items rescued', style: AppTextStyles.bodySmallOnPrimary),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: rescueRate, minHeight: 10, backgroundColor: Colors.white.withValues(alpha: 0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _BannerStat('$totalListed', 'Listed'),
        _BannerStat('$totalSold', 'Rescued'),
        _BannerStat('$wasted', 'Wasted'),
      ]),
    ]),
  );
}

class _BannerStat extends StatelessWidget {
  final String value, label;
  const _BannerStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);
}

class _CategoryRow extends StatelessWidget {
  final _WasteItem item;
  const _CategoryRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(item.name, style: AppTextStyles.label)),
        Text('${item.wasted} wasted / ${item.listed} listed', style: AppTextStyles.caption),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: item.rate,
          minHeight: 10,
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(item.color),
        ),
      ),
    ]),
  );
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('🌿', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('Reduce Waste Tips', style: AppTextStyles.h5),
      ]),
      const SizedBox(height: 12),
      ...[
        'List items 2–3 hours before closing for better visibility',
        'Use flash sales for overstocked bakery items near closing',
        'Bundle slow-moving items at a discount to clear stock',
        'Track weekly trends to avoid over-ordering',
      ].map((tip) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          Expanded(child: Text(tip, style: AppTextStyles.bodySmall)),
        ]),
      )),
    ]),
  );
}
