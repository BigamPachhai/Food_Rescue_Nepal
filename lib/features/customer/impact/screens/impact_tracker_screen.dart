import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/impact_provider.dart';

class ImpactTrackerScreen extends ConsumerWidget {
  const ImpactTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(impactProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryMedium],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text('Your Impact', style: AppTextStyles.h3OnPrimary),
                      Text('Together we rescue food, save the planet', style: AppTextStyles.bodySmallOnPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ImpactSummaryRow(impact: impact),
                const SizedBox(height: 20),
                const _SectionTitle('Environmental Savings'),
                const SizedBox(height: 12),
                _EnvCard(
                  icon: Icons.cloud_off_rounded,
                  color: Colors.blue,
                  title: 'CO₂ Saved',
                  value: '${impact.co2SavedKg.toStringAsFixed(1)} kg',
                  subtitle: 'Equivalent to ${(impact.co2SavedKg / 21).toStringAsFixed(0)} car trips avoided',
                  progress: (impact.co2SavedKg / 100).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 12),
                _EnvCard(
                  icon: Icons.water_drop_rounded,
                  color: Colors.lightBlue,
                  title: 'Water Saved',
                  value: '${impact.waterSavedLiters.toStringAsFixed(0)} L',
                  subtitle: 'Equal to ${(impact.waterSavedLiters / 150).toStringAsFixed(0)} showers',
                  progress: (impact.waterSavedLiters / 1000).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 12),
                _EnvCard(
                  icon: Icons.restaurant_rounded,
                  color: Colors.orange,
                  title: 'Meals Rescued',
                  value: '${impact.mealsRescued}',
                  subtitle: 'Fed ${impact.mealsRescued} people in need',
                  progress: (impact.mealsRescued / 50).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Financial Savings'),
                const SizedBox(height: 12),
                _MoneySavedCard(impact: impact),
                const SizedBox(height: 20),
                const _SectionTitle('Community Impact'),
                const SizedBox(height: 12),
                _CommunityStatsRow(impact: impact),
                const SizedBox(height: 20),
                const _SectionTitle('Monthly Progress'),
                const SizedBox(height: 12),
                _MonthlyChart(impact: impact),
                const SizedBox(height: 20),
                _ShareImpactCard(context: context, impact: impact),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactSummaryRow extends StatelessWidget {
  final ImpactData impact;
  const _ImpactSummaryRow({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Orders', value: '${impact.totalOrders}', icon: Icons.shopping_bag_rounded),
        const SizedBox(width: 8),
        _StatChip(label: 'Streak', value: '${impact.currentStreak}d', icon: Icons.local_fire_department_rounded),
        const SizedBox(width: 8),
        _StatChip(label: 'Level', value: impact.level, icon: Icons.military_tech_rounded),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryMedium, size: 22),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _EnvCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, value, subtitle;
  final double progress;
  const _EnvCard({required this.icon, required this.color, required this.title, required this.value, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.label),
                    Text(value, style: AppTextStyles.h5.copyWith(color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneySavedCard extends StatelessWidget {
  final ImpactData impact;
  const _MoneySavedCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryMedium, AppColors.primaryDark]),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Saved', style: AppTextStyles.bodySmallOnPrimary),
                Text('Rs. ${impact.moneySavedNPR.toStringAsFixed(0)}', style: AppTextStyles.h2OnPrimary),
                const SizedBox(height: 4),
                Text('Average ${((impact.moneySavedNPR / impact.totalOrders.clamp(1, 9999))).toStringAsFixed(0)} per order', style: AppTextStyles.bodySmallOnPrimary),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (impact.moneySavedNPR / 10000).clamp(0.0, 1.0),
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${((impact.moneySavedNPR / 10000) * 100).toInt()}%',
                  style: AppTextStyles.h5OnPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityStatsRow extends StatelessWidget {
  final ImpactData impact;
  const _CommunityStatsRow({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CommStat(value: '${impact.communityRank}', label: 'Your Rank', icon: Icons.leaderboard_rounded),
        const SizedBox(width: 8),
        _CommStat(value: '${impact.vendorsSupported}', label: 'Vendors\nSupported', icon: Icons.store_rounded),
        const SizedBox(width: 8),
        _CommStat(value: '${impact.reviewsGiven}', label: 'Reviews\nGiven', icon: Icons.star_rounded),
      ],
    );
  }
}

class _CommStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _CommStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryMedium, size: 24),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final ImpactData impact;
  const _MonthlyChart({required this.impact});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final data = impact.monthlyOrders;
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders per Month', style: AppTextStyles.label),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final h = data[i] / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (data[i] > 0) Text('${data[i]}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Container(
                          height: 90 * h,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryMedium,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(months[i], style: const TextStyle(fontSize: 9, color: Colors.grey)),
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

class _ShareImpactCard extends StatelessWidget {
  final BuildContext context;
  final ImpactData impact;
  const _ShareImpactCard({required this.context, required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.share_rounded, color: AppColors.primaryMedium, size: 32),
          const SizedBox(height: 8),
          Text('Share Your Impact!', style: AppTextStyles.h5),
          const SizedBox(height: 4),
          Text('Inspire others to join the food rescue movement', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share My Impact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title, style: AppTextStyles.h5);
}
