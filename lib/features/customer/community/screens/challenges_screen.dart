import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _Challenge {
  final String id, title, description, icon, reward;
  final int target, current;
  final DateTime deadline;
  final String category;
  const _Challenge({required this.id, required this.title, required this.description, required this.icon, required this.reward, required this.target, required this.current, required this.deadline, required this.category});
  double get progress => (current / target).clamp(0.0, 1.0);
  bool get isCompleted => current >= target;
  int get daysLeft => deadline.difference(DateTime.now()).inDays.clamp(0, 999);
}

final _weeklyChallenges = [
  _Challenge(id: 'w1', title: 'Week Warrior', description: 'Complete 5 orders this week', icon: '⚡', reward: '100 pts', target: 5, current: 3, deadline: DateTime.now().add(const Duration(days: 4)), category: 'Weekly'),
  _Challenge(id: 'w2', title: 'Variety Explorer', description: 'Order from 3 different categories', icon: '🗺️', reward: '75 pts', target: 3, current: 1, deadline: DateTime.now().add(const Duration(days: 4)), category: 'Weekly'),
  _Challenge(id: 'w3', title: 'Early Bird', description: 'Make 2 morning pickups before 9am', icon: '🌅', reward: '50 pts', target: 2, current: 0, deadline: DateTime.now().add(const Duration(days: 4)), category: 'Weekly'),
];

final _monthlyChallenges = [
  _Challenge(id: 'm1', title: 'Monthly Champion', description: 'Complete 20 orders this month', icon: '🏆', reward: '500 pts + Badge', target: 20, current: 8, deadline: DateTime.now().add(const Duration(days: 18)), category: 'Monthly'),
  _Challenge(id: 'm2', title: 'Green Giant', description: 'Save 50kg of CO₂ this month', icon: '🌍', reward: '300 pts', target: 50, current: 20, deadline: DateTime.now().add(const Duration(days: 18)), category: 'Monthly'),
  _Challenge(id: 'm3', title: 'Social Butterfly', description: 'Write 5 reviews this month', icon: '🦋', reward: '200 pts', target: 5, current: 2, deadline: DateTime.now().add(const Duration(days: 18)), category: 'Monthly'),
];

final _specialChallenges = [
  _Challenge(id: 's1', title: 'New Year Resolution', description: 'Rescue 100 meals in January', icon: '🎊', reward: '1000 pts + Special Badge', target: 100, current: 34, deadline: DateTime(2025, 1, 31), category: 'Special'),
  _Challenge(id: 's2', title: 'Community Hero', description: 'Help 10 different vendors', icon: '🦸', reward: '750 pts', target: 10, current: 6, deadline: DateTime.now().add(const Duration(days: 30)), category: 'Special'),
];

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

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
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Weekly'), Tab(text: 'Monthly'), Tab(text: 'Special')],
        ),
      ),
      body: Column(
        children: [
          _StreakBanner(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ChallengeList(challenges: _weeklyChallenges),
                _ChallengeList(challenges: _monthlyChallenges),
                _ChallengeList(challenges: _specialChallenges),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.deepOrange.shade500]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3-Day Streak!', style: AppTextStyles.h5OnPrimary),
                Text('Keep going to unlock the Week Warrior bonus!', style: AppTextStyles.bodySmallOnPrimary),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('4 left', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ChallengeList extends StatelessWidget {
  final List<_Challenge> challenges;
  const _ChallengeList({required this.challenges});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: challenges.map((c) => _ChallengeCard(challenge: c)).toList(),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final _Challenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: challenge.isCompleted ? Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.5)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(challenge.title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700))),
                        if (challenge.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primaryMedium, borderRadius: BorderRadius.circular(10)),
                            child: const Text('✓ Done', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                      ],
                    ),
                    Text(challenge.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${challenge.current} / ${challenge.target}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600)),
              Text('${challenge.daysLeft} days left', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 8,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(challenge.isCompleted ? AppColors.primaryMedium : AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text('Reward: ${challenge.reward}', style: AppTextStyles.caption.copyWith(color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
