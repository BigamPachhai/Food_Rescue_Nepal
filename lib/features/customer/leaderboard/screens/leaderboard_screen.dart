import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _LeaderEntry {
  final int rank;
  final String name;
  final int orders;
  final double co2Saved;
  final String level;
  final bool isCurrentUser;
  const _LeaderEntry({required this.rank, required this.name, required this.orders, required this.co2Saved, required this.level, this.isCurrentUser = false});
}

final _mockLeaderboard = [
  const _LeaderEntry(rank: 1, name: 'Sita Sharma', orders: 142, co2Saved: 355.0, level: 'Forest Guardian'),
  const _LeaderEntry(rank: 2, name: 'Ram Thapa', orders: 118, co2Saved: 295.0, level: 'Forest Guardian'),
  const _LeaderEntry(rank: 3, name: 'Gita Rai', orders: 97, co2Saved: 242.5, level: 'Tree'),
  const _LeaderEntry(rank: 4, name: 'Hari Gurung', orders: 84, co2Saved: 210.0, level: 'Tree'),
  const _LeaderEntry(rank: 5, name: 'Maya Tamang', orders: 71, co2Saved: 177.5, level: 'Tree'),
  const _LeaderEntry(rank: 6, name: 'Bikash KC', orders: 63, co2Saved: 157.5, level: 'Sprout'),
  const _LeaderEntry(rank: 7, name: 'Pooja Adhikari', orders: 54, co2Saved: 135.0, level: 'Sprout'),
  const _LeaderEntry(rank: 8, name: 'Suresh Bhandari', orders: 45, co2Saved: 112.5, level: 'Sprout'),
  const _LeaderEntry(rank: 9, name: 'Anita Karki', orders: 38, co2Saved: 95.0, level: 'Sprout'),
  const _LeaderEntry(rank: 10, name: 'You', orders: 12, co2Saved: 30.0, level: 'Leaf', isCurrentUser: true),
];

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
                      const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      Text('Food Rescue Leaderboard', style: AppTextStyles.h4OnPrimary),
                      Text('Top rescuers in your community', style: AppTextStyles.bodySmallOnPrimary),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Orders'),
                Tab(text: 'CO₂ Saved'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _TopThree(entries: _mockLeaderboard.take(3).toList())),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _LeaderRow(entry: _mockLeaderboard[i + 3]),
                childCount: _mockLeaderboard.length - 3,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _TopThree extends StatelessWidget {
  final List<_LeaderEntry> entries;
  const _TopThree({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (entries.length > 1) _PodiumItem(entry: entries[1], height: 80),
          const SizedBox(width: 12),
          if (entries.isNotEmpty) _PodiumItem(entry: entries[0], height: 110, isFirst: true),
          const SizedBox(width: 12),
          if (entries.length > 2) _PodiumItem(entry: entries[2], height: 60),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final _LeaderEntry entry;
  final double height;
  final bool isFirst;
  const _PodiumItem({required this.entry, required this.height, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final medal = ['🥇', '🥈', '🥉'][entry.rank - 1];
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: isFirst ? 28 : 22,
            backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15),
            child: Text(entry.name[0], style: TextStyle(fontSize: isFirst ? 22 : 18, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Text(entry.name.split(' ')[0], style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          Text('${entry.orders} orders', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: [AppColors.primaryMedium, AppColors.primaryLight, AppColors.primaryDark][entry.rank - 1],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('#${entry.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final _LeaderEntry entry;
  const _LeaderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.primaryMedium.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser ? Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#${entry.rank}', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Text(entry.name[0], style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.name, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryMedium, borderRadius: BorderRadius.circular(8)),
                        child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(entry.level, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.orders}', style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium)),
              Text('orders', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
