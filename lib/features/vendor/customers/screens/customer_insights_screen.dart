import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CustomerInsightsScreen extends StatelessWidget {
  const CustomerInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Customer Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryGrid(),
          const SizedBox(height: 20),
          Text('Customer Segments', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          const _SegmentCard(label: 'New Customers', count: 38, pct: 0.32, color: Colors.blue, icon: Icons.person_add_rounded, desc: 'First-time orders this month'),
          const SizedBox(height: 8),
          const _SegmentCard(label: 'Returning Customers', count: 65, pct: 0.55, color: AppColors.primaryMedium, icon: Icons.repeat_rounded, desc: 'Ordered more than once'),
          const SizedBox(height: 8),
          const _SegmentCard(label: 'Loyal Fans', count: 15, pct: 0.13, color: Colors.orange, icon: Icons.favorite_rounded, desc: '5+ orders in last 30 days'),
          const SizedBox(height: 20),
          Text('Top Customers', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ...[
                ('Sita M.', 12, 'NPR 3,240', '2 days ago'),
                ('Ram K.', 9, 'NPR 2,180', '5 days ago'),
                ('Anita S.', 8, 'NPR 1,950', '1 day ago'),
                ('Bikram T.', 7, 'NPR 1,680', '3 days ago'),
                ('Priya G.', 6, 'NPR 1,450', '1 week ago'),
              ].asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Column(children: [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15), child: Text('${i + 1}', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.bold))),
                    title: Text(c.$1, style: AppTextStyles.label),
                    subtitle: Text('${c.$2} orders • Last: ${c.$4}', style: AppTextStyles.caption),
                    trailing: Text(c.$3, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
                  ),
                  if (i < 4) const Divider(height: 1, indent: 56),
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Order Patterns', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Column(children: [
              _PatternRow('Average Order Value', 'NPR 248'),
              Divider(height: 20),
              _PatternRow('Average Items per Order', '2.4 items'),
              Divider(height: 20),
              _PatternRow('Most Popular Time', '6 PM – 8 PM'),
              Divider(height: 20),
              _PatternRow('Peak Day', 'Saturday'),
              Divider(height: 20),
              _PatternRow('Repeat Purchase Rate', '55%'),
              Divider(height: 20),
              _PatternRow('Avg Days Between Orders', '8.3 days'),
            ]),
          ),
          const SizedBox(height: 20),
          Text('What Customers Love', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('Bakery Items', 42),
                ('Value for Money', 38),
                ('Fresh Produce', 31),
                ('Convenient Location', 29),
                ('Good Portions', 25),
                ('Quick Pickup', 22),
                ('Eco Packaging', 18),
              ].map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${t.$1} (${t.$2})', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.w500, fontSize: 12)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.6,
    children: const [
      _StatCard('118', 'Total Customers', Icons.people_rounded, AppColors.primaryMedium),
      _StatCard('38', 'New This Month', Icons.person_add_rounded, Colors.blue),
      _StatCard('4.2★', 'Avg Rating Given', Icons.star_rounded, Colors.amber),
      _StatCard('55%', 'Retention Rate', Icons.loop_rounded, Colors.green),
    ],
  );
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

class _SegmentCard extends StatelessWidget {
  final String label, desc;
  final int count;
  final double pct;
  final Color color;
  final IconData icon;
  const _SegmentCard({required this.label, required this.count, required this.pct, required this.color, required this.icon, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.label),
          Text(desc, style: AppTextStyles.caption),
        ])),
        Text('$count', style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
      ),
      const SizedBox(height: 4),
      Align(alignment: Alignment.centerRight, child: Text('${(pct * 100).toStringAsFixed(0)}% of customers', style: AppTextStyles.caption)),
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
