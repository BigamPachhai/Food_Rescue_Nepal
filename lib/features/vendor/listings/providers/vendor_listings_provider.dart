import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class VendorListing {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final String category;
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final int availableQty;
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final DateTime? expiryTime;
  final String? conditionNotes;
  final List<String> imageUrls;
  final bool isActive;
  final List<String> dietaryTags;

  const VendorListing({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.availableQty,
    required this.pickupStart,
    required this.pickupEnd,
    this.expiryTime,
    this.conditionNotes,
    required this.imageUrls,
    required this.isActive,
    this.dietaryTags = const [],
  });

  factory VendorListing.fromJson(Map<String, dynamic> json) => VendorListing(
        id: json['id'] as String? ?? '',
        vendorId: json['vendorId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        category: json['category'] as String? ?? 'Other',
        originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
        discountedPrice: (json['discountedPrice'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        availableQty: (json['availableQty'] as num?)?.toInt() ?? (json['quantity'] as num?)?.toInt() ?? 0,
        pickupStart: json['pickupStart'] != null
            ? DateTime.parse(json['pickupStart'] as String)
            : DateTime.now(),
        pickupEnd: json['pickupEnd'] != null
            ? DateTime.parse(json['pickupEnd'] as String)
            : DateTime.now().add(const Duration(hours: 4)),
        expiryTime: json['expiryTime'] != null
            ? DateTime.parse(json['expiryTime'] as String)
            : null,
        conditionNotes: json['conditionNotes'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        dietaryTags: (json['dietaryTags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  int get discountPercent {
    if (originalPrice == 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }

  bool get isSoldOut => availableQty == 0;

  int get soldCount => quantity - availableQty;
}

class VendorListingsNotifier
    extends StateNotifier<AsyncValue<List<VendorListing>>> {
  VendorListingsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get(ApiEndpoints.vendorListings);
      if (!mounted) return;
      final data = response.data;
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else {
        items = [];
      }
      state = AsyncValue.data(
        items
            .map((e) => VendorListing.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteListing(String id) async {
    await _dio.delete(ApiEndpoints.vendorListingById(id));
    if (!mounted) return;
    await fetch();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _dio.patch(ApiEndpoints.vendorListingById(id), data: {'isActive': isActive});
    if (!mounted) return;
    await fetch();
  }

  Future<void> markSoldOut(String id) async {
    await _dio.patch(ApiEndpoints.vendorListingById(id), data: {'availableQty': 0});
    if (!mounted) return;
    await fetch();
  }

  Future<void> duplicateListing(VendorListing listing) async {
    await _dio.post(ApiEndpoints.createListing, data: {
      'name': '${listing.name} (Copy)',
      'description': listing.description,
      'category': listing.category,
      'originalPrice': listing.originalPrice,
      'discountedPrice': listing.discountedPrice,
      'quantity': listing.quantity,
      'pickupStart': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'pickupEnd': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      'imageUrls': listing.imageUrls,
      if (listing.conditionNotes != null) 'conditionNotes': listing.conditionNotes,
      if (listing.dietaryTags.isNotEmpty) 'dietaryTags': listing.dietaryTags,
    });
    if (!mounted) return;
    await fetch();
  }
}

final vendorListingsProvider =
    StateNotifierProvider<VendorListingsNotifier, AsyncValue<List<VendorListing>>>(
        (ref) {
  return VendorListingsNotifier(ref.read(dioClientProvider));
});

final vendorListingDetailProvider =
    FutureProvider.family<VendorListing, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorListingById(id));
  final raw = response.data as Map<String, dynamic>;
  final d = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return VendorListing.fromJson(d);
});
