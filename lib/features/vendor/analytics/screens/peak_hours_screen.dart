import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class PeakHoursScreen extends StatelessWidget {
  const PeakHoursScreen({super.key});

  static const _hourlyData = [0, 0, 0, 0, 0, 1, 4, 12, 18, 22, 15, 28, 35, 42, 38, 45, 52, 68, 75, 82, 70, 55, 30, 10];
  static const _dayData = [65, 42, 58, 71, 88, 95, 78];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxHourly = _hourlyData.reduce((a, b) => a > b ? a : b);
    final maxDay = _dayData.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Peak Hours Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InsightCard(
            icon: Icons.insights_rounded,
            title: 'Peak Hour',
            value: '7:00 PM – 8:00 PM',
            subtitle: '82 orders in the last month',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          const _InsightCard(
            icon: Icons.calendar_today_rounded,
            title: 'Busiest Day',
            value: 'Saturday',
            subtitle: '95 orders on average',
            color: AppColors.primaryMedium,
          ),
          const SizedBox(height: 20),
          Text('Orders by Hour (Today)', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tap on a bar to see details', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (i) {
                    final h = maxHourly == 0 ? 0.0 : _hourlyData[i] / maxHourly;
                    final isHigh = _hourlyData[i] == maxHourly;
                    return Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          height: 110 * h,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isHigh ? Colors.orange : AppColors.primaryMedium,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                        if (i % 4 == 0)
                          Text('${i}h', style: const TextStyle(fontSize: 8, color: Colors.grey))
                        else
                          const SizedBox(height: 12),
                      ]),
                    );
                  }),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Orders by Day of Week', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: List.generate(7, (i) {
              final pct = _dayData[i] / maxDay;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 36, child: Text(_days[i], style: AppTextStyles.caption)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 18,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation<Color>(_dayData[i] == maxDay ? Colors.orange : AppColors.primaryMedium),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 28, child: Text('${_dayData[i]}', style: AppTextStyles.caption, textAlign: TextAlign.right)),
                ]),
              );
            })),
          ),
          const SizedBox(height: 20),
          _RecommendationsCard(),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title, value, subtitle;
  final Color color;
  const _InsightCard({required this.icon, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
        Text(subtitle, style: AppTextStyles.caption),
      ])),
    ]),
  );
}

class _RecommendationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('Recommendations', style: AppTextStyles.h5),
      ]),
      const SizedBox(height: 12),
      ...[
        'List your most popular items by 6 PM to capture evening peak traffic',
        'Saturday is your busiest day — ensure enough inventory',
        'Consider flash sales on Tuesday (slowest day) to boost orders',
        'Set pickup windows to end before 8 PM when orders drop significantly',
      ].map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primaryMedium, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(r, style: AppTextStyles.bodySmall)),
        ]),
      )),
    ]),
  );
}
