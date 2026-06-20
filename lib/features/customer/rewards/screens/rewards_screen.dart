import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _pointsProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('loyalty_points') ?? 0;
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(_pointsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Points & Rewards')),
      body: pointsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load points')),
        data: (points) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PointsCard(points: points),
            const SizedBox(height: 20),
            Text('How to Earn Points', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            ..._earnRules.map((r) => _EarnRuleCard(rule: r)),
            const SizedBox(height: 20),
            Text('Redeem Points', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            ..._rewards.map((r) => _RewardCard(reward: r, points: points)),
            const SizedBox(height: 20),
            _PointsHistoryCard(),
          ],
        ),
      ),
    );
  }
}

const _earnRules = [
  _EarnRule(icon: '🛒', title: 'Complete an Order', points: 10, description: 'Earn 10 points for every completed rescue order'),
  _EarnRule(icon: '⭐', title: 'Write a Review', points: 5, description: 'Earn 5 points for each review you submit'),
  _EarnRule(icon: '🔥', title: '7-Day Streak', points: 50, description: 'Bonus 50 points for a 7-day ordering streak'),
  _EarnRule(icon: '👥', title: 'Refer a Friend', points: 100, description: 'Earn 100 points when a friend joins'),
  _EarnRule(icon: '🌟', title: 'First Order of Month', points: 20, description: 'Bonus 20 points for your first order each month'),
];

const _rewards = [
  _Reward(icon: '🎁', title: '5% Discount Coupon', cost: 100, description: 'Get 5% off your next order'),
  _Reward(icon: '🆓', title: 'Free Delivery', cost: 150, description: 'Free delivery on your next order'),
  _Reward(icon: '💰', title: 'Rs. 50 Cashback', cost: 200, description: 'Rs. 50 cashback on your next purchase'),
  _Reward(icon: '🎉', title: '10% Discount Coupon', cost: 350, description: 'Get 10% off your next order'),
  _Reward(icon: '🏆', title: 'Premium Member (1 Month)', cost: 500, description: 'Access exclusive deals and early listings'),
];

class _EarnRule {
  final String icon, title, description;
  final int points;
  const _EarnRule({required this.icon, required this.title, required this.points, required this.description});
}

class _Reward {
  final String icon, title, description;
  final int cost;
  const _Reward({required this.icon, required this.title, required this.cost, required this.description});
}

class _PointsCard extends StatelessWidget {
  final int points;
  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          Text('$points', style: AppTextStyles.display.copyWith(color: Colors.white)),
          Text('Rescue Points', style: AppTextStyles.h5OnPrimary),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PointsStat(label: 'This Month', value: '${(points * 0.3).toInt()}'),
              Container(width: 1, height: 30, color: Colors.white30),
              const _PointsStat(label: 'Redeemed', value: '0'),
              Container(width: 1, height: 30, color: Colors.white30),
              const _PointsStat(label: 'Expiring', value: '0'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsStat extends StatelessWidget {
  final String label, value;
  const _PointsStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h5OnPrimary),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _EarnRuleCard extends StatelessWidget {
  final _EarnRule rule;
  const _EarnRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(rule.icon, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.title, style: AppTextStyles.label),
                Text(rule.description, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('+${rule.points} pts', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  final int points;
  const _RewardCard({required this.reward, required this.points});

  @override
  Widget build(BuildContext context) {
    final canRedeem = points >= reward.cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: canRedeem ? Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(reward.icon, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTextStyles.label),
                Text(reward.description, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text('${reward.cost} pts required', style: AppTextStyles.caption.copyWith(color: canRedeem ? AppColors.primaryMedium : AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canRedeem ? () => _showRedeemDialog(context, reward) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              disabledBackgroundColor: AppColors.backgroundLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(canRedeem ? 'Redeem' : 'Locked', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, _Reward reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Redeem ${reward.title}?'),
        content: Text('This will cost ${reward.cost} points. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 ${reward.title} redeemed!')));
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class _PointsHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Points History', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          const _HistoryRow(icon: Icons.shopping_bag_rounded, title: 'Order #FRN1042', points: '+10', date: 'Today'),
          const _HistoryRow(icon: Icons.star_rounded, title: 'Review submitted', points: '+5', date: 'Yesterday'),
          const _HistoryRow(icon: Icons.local_fire_department_rounded, title: '7-day streak bonus', points: '+50', date: '3 days ago'),
          Center(
            child: TextButton(onPressed: () {}, child: const Text('View All History')),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final IconData icon;
  final String title, points, date;
  const _HistoryRow({required this.icon, required this.title, required this.points, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryMedium, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(points, style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
        ],
      ),
    );
  }
}
