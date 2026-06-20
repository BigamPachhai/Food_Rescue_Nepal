import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpactData {
  final int totalOrders;
  final double co2SavedKg;
  final double waterSavedLiters;
  final int mealsRescued;
  final double moneySavedNPR;
  final int currentStreak;
  final int longestStreak;
  final String level;
  final int communityRank;
  final int vendorsSupported;
  final int reviewsGiven;
  final List<int> monthlyOrders;

  const ImpactData({
    this.totalOrders = 0,
    this.co2SavedKg = 0,
    this.waterSavedLiters = 0,
    this.mealsRescued = 0,
    this.moneySavedNPR = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.level = 'Seed',
    this.communityRank = 0,
    this.vendorsSupported = 0,
    this.reviewsGiven = 0,
    this.monthlyOrders = const [],
  });

  ImpactData copyWith({
    int? totalOrders,
    double? co2SavedKg,
    double? waterSavedLiters,
    int? mealsRescued,
    double? moneySavedNPR,
    int? currentStreak,
    int? longestStreak,
    String? level,
    int? communityRank,
    int? vendorsSupported,
    int? reviewsGiven,
    List<int>? monthlyOrders,
  }) {
    return ImpactData(
      totalOrders: totalOrders ?? this.totalOrders,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
      waterSavedLiters: waterSavedLiters ?? this.waterSavedLiters,
      mealsRescued: mealsRescued ?? this.mealsRescued,
      moneySavedNPR: moneySavedNPR ?? this.moneySavedNPR,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      level: level ?? this.level,
      communityRank: communityRank ?? this.communityRank,
      vendorsSupported: vendorsSupported ?? this.vendorsSupported,
      reviewsGiven: reviewsGiven ?? this.reviewsGiven,
      monthlyOrders: monthlyOrders ?? this.monthlyOrders,
    );
  }

  static String levelFromOrders(int orders) {
    if (orders >= 100) return 'Forest Guardian';
    if (orders >= 50) return 'Tree';
    if (orders >= 20) return 'Sprout';
    if (orders >= 5) return 'Leaf';
    return 'Seed';
  }
}

class ImpactNotifier extends StateNotifier<ImpactData> {
  ImpactNotifier() : super(const ImpactData()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = prefs.getInt('impact_orders') ?? 0;
    final monthly = List<int>.generate(12, (i) => prefs.getInt('impact_month_$i') ?? 0);
    state = ImpactData(
      totalOrders: orders,
      co2SavedKg: orders * 2.5,
      waterSavedLiters: orders * 120.0,
      mealsRescued: orders,
      moneySavedNPR: prefs.getDouble('impact_money') ?? 0,
      currentStreak: prefs.getInt('impact_streak') ?? 0,
      longestStreak: prefs.getInt('impact_best_streak') ?? 0,
      level: ImpactData.levelFromOrders(orders),
      communityRank: prefs.getInt('impact_rank') ?? 999,
      vendorsSupported: prefs.getInt('impact_vendors') ?? 0,
      reviewsGiven: prefs.getInt('impact_reviews') ?? 0,
      monthlyOrders: monthly,
    );
  }

  Future<void> recordOrder({required double moneySaved, required String vendorId}) async {
    final prefs = await SharedPreferences.getInstance();
    final newOrders = state.totalOrders + 1;
    final newMoney = state.moneySavedNPR + moneySaved;
    final month = DateTime.now().month - 1;
    final monthly = List<int>.from(state.monthlyOrders.isEmpty
        ? List.filled(12, 0)
        : state.monthlyOrders);
    if (monthly.length > month) monthly[month]++;

    await prefs.setInt('impact_orders', newOrders);
    await prefs.setDouble('impact_money', newMoney);
    await prefs.setInt('impact_month_$month', monthly[month]);

    final vendors = <String>{...prefs.getStringList('impact_vendor_ids') ?? []};
    vendors.add(vendorId);
    await prefs.setStringList('impact_vendor_ids', vendors.toList());

    state = state.copyWith(
      totalOrders: newOrders,
      co2SavedKg: newOrders * 2.5,
      waterSavedLiters: newOrders * 120.0,
      mealsRescued: newOrders,
      moneySavedNPR: newMoney,
      level: ImpactData.levelFromOrders(newOrders),
      vendorsSupported: vendors.length,
      monthlyOrders: monthly,
    );
  }

  Future<void> refresh() => _load();
}

final impactProvider = StateNotifierProvider<ImpactNotifier, ImpactData>(
  (ref) => ImpactNotifier(),
);
