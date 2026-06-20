import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class OrderStatsScreen extends StatelessWidget {
  const OrderStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Order Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsHeader(),
          const SizedBox(height: 20),
          Text('Activity This Year', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          _MonthlyChart(),
          const SizedBox(height: 20),
          Text('Breakdown', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          _BreakdownCard(),
          const SizedBox(height: 20),
          Text('Top Categories Ordered', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          _CategoryBreakdown(),
          const SizedBox(height: 20),
          Text('Favourite Vendors', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          _FaveVendors(),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      Text('Your Food Rescue Journey', style: AppTextStyles.h5OnPrimary),
      const SizedBox(height: 16),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _HeaderStat('47', 'Total Orders'),
        _Divider(),
        _HeaderStat('NPR 9,840', 'Total Saved'),
        _Divider(),
        _HeaderStat('23.5 kg', 'Food Rescued'),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.eco_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text('You\'ve saved ~47 kg of CO₂ emissions!', style: TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      ),
    ]),
  );
}

class _HeaderStat extends StatelessWidget {
  final String value, label;
  const _HeaderStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3));
}

class _MonthlyChart extends StatelessWidget {
  static const _months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  static const _data = [2, 3, 5, 4, 6, 7, 8, 5, 4, 3, 0, 0];

  @override
  Widget build(BuildContext context) {
    final max = _data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Monthly Orders (2025)', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final h = max == 0 ? 0.0 : _data[i] / max;
              return Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (_data[i] > 0)
                    Text('${_data[i]}', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  Container(
                    height: 80 * h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _data[i] == max ? Colors.orange : AppColors.primaryMedium,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_months[i], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ]),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: const Column(children: [
      _Row('Completed Orders', '42', Icons.check_circle_rounded, Colors.green),
      Divider(height: 1, indent: 56),
      _Row('Cancelled Orders', '3', Icons.cancel_rounded, Colors.red),
      Divider(height: 1, indent: 56),
      _Row('Pending Orders', '2', Icons.pending_rounded, Colors.orange),
      Divider(height: 1, indent: 56),
      _Row('Average Order Value', 'NPR 209', Icons.attach_money_rounded, AppColors.primaryMedium),
      Divider(height: 1, indent: 56),
      _Row('Most Ordered Item', 'Bakery Box', Icons.favorite_rounded, Colors.pink),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Row(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: AppTextStyles.label),
    trailing: Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
  );
}

class _CategoryBreakdown extends StatelessWidget {
  static const _cats = [
    ('Bakery & Pastry', 18, 0.38),
    ('Prepared Meals', 12, 0.25),
    ('Fruits & Veggies', 8, 0.17),
    ('Dairy Products', 6, 0.13),
    ('Beverages', 3, 0.06),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.orange, AppColors.primaryMedium, Colors.green, Colors.blue, Colors.teal];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(_cats.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(_cats[i].$1, style: AppTextStyles.label)),
              Text('${_cats[i].$2} orders', style: AppTextStyles.caption),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _cats[i].$3, minHeight: 8, backgroundColor: colors[i].withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(colors[i])),
            ),
          ]),
        )),
      ),
    );
  }
}

class _FaveVendors extends StatelessWidget {
  static const _vendors = [
    ('Himalayan Bakehouse', 12, '4.8★'),
    ('Green Valley Kitchen', 9, '4.6★'),
    ('Thamel Deli', 7, '4.5★'),
    ('Mountain Fresh', 5, '4.7★'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: _vendors.asMap().entries.map((e) => Column(children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15),
            child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.bold)),
          ),
          title: Text(e.value.$1, style: AppTextStyles.label),
          subtitle: Text('${e.value.$2} orders', style: AppTextStyles.caption),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(e.value.$3, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
        if (e.key < _vendors.length - 1) const Divider(height: 1, indent: 56),
      ])).toList(),
    ),
  );
}
