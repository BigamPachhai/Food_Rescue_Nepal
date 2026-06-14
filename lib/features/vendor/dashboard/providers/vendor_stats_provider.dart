import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class ListingPerf {
  final String id;
  final String name;
  final int availableQty;
  final bool isActive;
  final int totalOrders;
  final int completedOrders;
  final int revenuePaisa;
  final int quantitySold;

  const ListingPerf({
    required this.id,
    required this.name,
    required this.availableQty,
    required this.isActive,
    required this.totalOrders,
    required this.completedOrders,
    required this.revenuePaisa,
    required this.quantitySold,
  });

  factory ListingPerf.fromJson(Map<String, dynamic> json) => ListingPerf(
        id: json['id'] as String,
        name: json['name'] as String,
        availableQty: json['availableQty'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? false,
        totalOrders: json['totalOrders'] as int? ?? 0,
        completedOrders: json['completedOrders'] as int? ?? 0,
        revenuePaisa: json['revenuePaisa'] as int? ?? 0,
        quantitySold: json['quantitySold'] as int? ?? 0,
      );
}

class VendorStats {
  final int todayOrders;
  final int todayEarnedPaisa;
  final double foodSavedKg;
  final int pendingOrders;
  final int activeListings;
  final int totalReservations;
  final int completedPickups;
  final double totalFoodSavedKg;
  final int totalRevenuePaisa;
  final List<ListingPerf> listingPerformance;

  const VendorStats({
    required this.todayOrders,
    required this.todayEarnedPaisa,
    required this.foodSavedKg,
    required this.pendingOrders,
    required this.activeListings,
    required this.totalReservations,
    required this.completedPickups,
    required this.totalFoodSavedKg,
    required this.totalRevenuePaisa,
    required this.listingPerformance,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) => VendorStats(
        todayOrders: json['todayOrders'] as int? ?? 0,
        todayEarnedPaisa: json['todayEarned'] as int? ?? 0,
        foodSavedKg: (json['foodSavedKg'] as num?)?.toDouble() ?? 0,
        pendingOrders: json['pendingOrders'] as int? ?? 0,
        activeListings: json['activeListings'] as int? ?? 0,
        totalReservations: json['totalReservations'] as int? ?? 0,
        completedPickups: json['completedPickups'] as int? ?? 0,
        totalFoodSavedKg:
            (json['totalFoodSavedKg'] as num?)?.toDouble() ?? 0,
        totalRevenuePaisa: json['totalRevenuePaisa'] as int? ?? 0,
        listingPerformance: (json['listingPerformance'] as List<dynamic>? ?? [])
            .map((e) => ListingPerf.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final vendorStatsProvider = FutureProvider<VendorStats>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorStats);
  final raw = response.data as Map<String, dynamic>;
  final data =
      raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return VendorStats.fromJson(data);
});
