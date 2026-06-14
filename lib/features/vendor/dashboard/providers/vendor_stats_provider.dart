import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class VendorStats {
  final int todayOrders;
  final int todayEarnedPaisa;
  final double foodSavedKg;
  final int pendingOrders;
  final int activeListings;

  const VendorStats({
    required this.todayOrders,
    required this.todayEarnedPaisa,
    required this.foodSavedKg,
    required this.pendingOrders,
    required this.activeListings,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) => VendorStats(
        todayOrders: json['todayOrders'] as int? ?? 0,
        todayEarnedPaisa: json['todayEarned'] as int? ?? 0,
        foodSavedKg: (json['foodSavedKg'] as num?)?.toDouble() ?? 0,
        pendingOrders: json['pendingOrders'] as int? ?? 0,
        activeListings: json['activeListings'] as int? ?? 0,
      );
}

final vendorStatsProvider = FutureProvider<VendorStats>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorStats);
  return VendorStats.fromJson(response.data as Map<String, dynamic>);
});
