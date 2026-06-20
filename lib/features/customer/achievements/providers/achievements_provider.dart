import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) => Achievement(
        id: id, title: title, description: description, icon: icon,
        requiredValue: requiredValue, category: category,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

class AchievementsState {
  final List<Achievement> achievements;
  final int totalPoints;
  const AchievementsState({this.achievements = const [], this.totalPoints = 0});
}

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  static const _allAchievements = [
    Achievement(id: 'first_order', title: 'First Rescue!', description: 'Complete your first food rescue order', icon: '🌱', requiredValue: 1, category: 'Orders'),
    Achievement(id: 'five_orders', title: 'Rescue Rookie', description: 'Complete 5 food rescue orders', icon: '🥗', requiredValue: 5, category: 'Orders'),
    Achievement(id: 'ten_orders', title: 'Food Hero', description: 'Complete 10 food rescue orders', icon: '🦸', requiredValue: 10, category: 'Orders'),
    Achievement(id: 'twenty_five_orders', title: 'Rescue Veteran', description: 'Complete 25 food rescue orders', icon: '🏅', requiredValue: 25, category: 'Orders'),
    Achievement(id: 'fifty_orders', title: 'Food Rescue Legend', description: 'Complete 50 food rescue orders', icon: '🏆', requiredValue: 50, category: 'Orders'),
    Achievement(id: 'hundred_orders', title: 'Planet Protector', description: 'Complete 100 food rescue orders', icon: '🌍', requiredValue: 100, category: 'Orders'),
    Achievement(id: 'streak_3', title: '3-Day Streak', description: 'Order 3 days in a row', icon: '🔥', requiredValue: 3, category: 'Streaks'),
    Achievement(id: 'streak_7', title: 'Week Warrior', description: 'Order 7 days in a row', icon: '⚡', requiredValue: 7, category: 'Streaks'),
    Achievement(id: 'streak_30', title: 'Monthly Champion', description: 'Order 30 days in a row', icon: '💎', requiredValue: 30, category: 'Streaks'),
    Achievement(id: 'save_500', title: 'Budget Saver', description: 'Save Rs. 500 through food rescue', icon: '💰', requiredValue: 500, category: 'Savings'),
    Achievement(id: 'save_2000', title: 'Money Master', description: 'Save Rs. 2,000 through food rescue', icon: '💵', requiredValue: 2000, category: 'Savings'),
    Achievement(id: 'save_5000', title: 'Thrifty Champion', description: 'Save Rs. 5,000 through food rescue', icon: '🤑', requiredValue: 5000, category: 'Savings'),
    Achievement(id: 'co2_10', title: 'Carbon Fighter', description: 'Save 10kg of CO₂ emissions', icon: '🌿', requiredValue: 10, category: 'Environment'),
    Achievement(id: 'co2_50', title: 'Green Guardian', description: 'Save 50kg of CO₂ emissions', icon: '♻️', requiredValue: 50, category: 'Environment'),
    Achievement(id: 'co2_100', title: 'Climate Champion', description: 'Save 100kg of CO₂ emissions', icon: '🌳', requiredValue: 100, category: 'Environment'),
    Achievement(id: 'five_vendors', title: 'Explorer', description: 'Order from 5 different vendors', icon: '🗺️', requiredValue: 5, category: 'Social'),
    Achievement(id: 'ten_vendors', title: 'Adventurer', description: 'Order from 10 different vendors', icon: '🧭', requiredValue: 10, category: 'Social'),
    Achievement(id: 'first_review', title: 'Feedback Champion', description: 'Write your first review', icon: '⭐', requiredValue: 1, category: 'Social'),
    Achievement(id: 'five_reviews', title: 'Review Master', description: 'Write 5 reviews', icon: '📝', requiredValue: 5, category: 'Social'),
    Achievement(id: 'referral', title: 'Community Builder', description: 'Refer a friend to Food Rescue Nepal', icon: '👥', requiredValue: 1, category: 'Social'),
  ];

  AchievementsNotifier() : super(const AchievementsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList('achievements_unlocked') ?? [];
    final achievements = _allAchievements.map((a) {
      final isUnlocked = unlocked.contains(a.id);
      return isUnlocked ? a.copyWith(isUnlocked: true, unlockedAt: DateTime.now()) : a;
    }).toList();
    final points = achievements.where((a) => a.isUnlocked).length * 50;
    state = AchievementsState(achievements: achievements, totalPoints: points);
  }

  Future<void> unlock(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList('achievements_unlocked') ?? [];
    if (!unlocked.contains(id)) {
      unlocked.add(id);
      await prefs.setStringList('achievements_unlocked', unlocked);
      await _load();
    }
  }

  Future<void> checkAndUnlock({int orders = 0, int streak = 0, double moneySaved = 0, double co2Saved = 0, int vendors = 0, int reviews = 0}) async {
    if (orders >= 1) await unlock('first_order');
    if (orders >= 5) await unlock('five_orders');
    if (orders >= 10) await unlock('ten_orders');
    if (orders >= 25) await unlock('twenty_five_orders');
    if (orders >= 50) await unlock('fifty_orders');
    if (orders >= 100) await unlock('hundred_orders');
    if (streak >= 3) await unlock('streak_3');
    if (streak >= 7) await unlock('streak_7');
    if (streak >= 30) await unlock('streak_30');
    if (moneySaved >= 500) await unlock('save_500');
    if (moneySaved >= 2000) await unlock('save_2000');
    if (moneySaved >= 5000) await unlock('save_5000');
    if (co2Saved >= 10) await unlock('co2_10');
    if (co2Saved >= 50) await unlock('co2_50');
    if (co2Saved >= 100) await unlock('co2_100');
    if (vendors >= 5) await unlock('five_vendors');
    if (vendors >= 10) await unlock('ten_vendors');
    if (reviews >= 1) await unlock('first_review');
    if (reviews >= 5) await unlock('five_reviews');
  }
}

final achievementsProvider = StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(),
);
