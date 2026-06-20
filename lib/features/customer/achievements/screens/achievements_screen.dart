import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final categories = state.achievements.map((a) => a.category).toSet().toList();
    final unlockedCount = state.achievements.where((a) => a.isUnlocked).length;

    return DefaultTabController(
      length: categories.length + 1,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Achievements'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'All'),
              ...categories.map((c) => Tab(text: c)),
            ],
          ),
        ),
        body: Column(
          children: [
            _ProgressHeader(unlockedCount: unlockedCount, total: state.achievements.length, points: state.totalPoints),
            Expanded(
              child: TabBarView(
                children: [
                  _AchievementGrid(achievements: state.achievements),
                  ...categories.map((c) => _AchievementGrid(
                    achievements: state.achievements.where((a) => a.category == c).toList(),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlockedCount, total, points;
  const _ProgressHeader({required this.unlockedCount, required this.total, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$unlockedCount / $total unlocked', style: AppTextStyles.h5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.primaryMedium, size: 16),
                    const SizedBox(width: 4),
                    Text('$points pts', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: unlockedCount / total,
              minHeight: 10,
              backgroundColor: AppColors.backgroundLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: achievements.length,
      itemBuilder: (_, i) => _AchievementCard(achievement: achievements[i]),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? AppColors.primaryMedium.withValues(alpha: 0.4) : Colors.transparent,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.primaryMedium.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: unlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 0.4, 0,
                  ]),
            child: Text(achievement.icon, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: AppTextStyles.label.copyWith(color: unlocked ? AppColors.textPrimary : AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: AppTextStyles.caption.copyWith(color: unlocked ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (unlocked) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryMedium, borderRadius: BorderRadius.circular(10)),
              child: Text('+50 pts', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}
