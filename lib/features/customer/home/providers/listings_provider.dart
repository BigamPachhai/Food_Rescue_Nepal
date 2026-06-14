import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class VendorEntity {
  final String id;
  final String userId;
  final String businessName;
  final String businessType;
  final String? address;
  final double? lat;
  final double? lng;
  final String? logoUrl;
  final double avgRating;
  final int totalReviews;
  final String status;

  const VendorEntity({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    this.address,
    this.lat,
    this.lng,
    this.logoUrl,
    this.avgRating = 0,
    this.totalReviews = 0,
    required this.status,
  });

  factory VendorEntity.fromJson(Map<String, dynamic> json) => VendorEntity(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? '',
        businessName: json['businessName'] as String,
        businessType: json['businessType'] as String? ?? '',
        address: json['address'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        logoUrl: json['logoUrl'] as String?,
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
        totalReviews: json['totalReviews'] as int? ?? 0,
        status: json['status'] as String? ?? 'APPROVED',
      );
}

class ListingEntity {
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
  final List<String> imageUrls;
  final bool isActive;
  final VendorEntity? vendor;
  final bool isFavorite;

  const ListingEntity({
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
    required this.imageUrls,
    required this.isActive,
    this.vendor,
    this.isFavorite = false,
  });

  factory ListingEntity.fromJson(Map<String, dynamic> json) => ListingEntity(
        id: json['id'] as String,
        vendorId: json['vendorId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        originalPrice: json['originalPrice'] as int,
        discountedPrice: json['discountedPrice'] as int,
        quantity: json['quantity'] as int,
        availableQty: json['availableQty'] as int? ?? json['quantity'] as int,
        pickupStart: DateTime.parse(json['pickupStart'] as String),
        pickupEnd: DateTime.parse(json['pickupEnd'] as String),
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        vendor: json['vendor'] != null
            ? VendorEntity.fromJson(json['vendor'] as Map<String, dynamic>)
            : null,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  int get discountPercent {
    if (originalPrice == 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }
}

class ListingsNotifier extends StateNotifier<AsyncValue<List<ListingEntity>>> {
  ListingsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Dio _dio;
  String? _category;
  String _search = '';
  int _page = 1;
  bool _hasMore = true;
  final List<ListingEntity> _items = [];

  Future<void> fetch({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _items.clear();
      state = const AsyncValue.loading();
    }
    if (!_hasMore && !refresh) return;
    try {
      final params = <String, dynamic>{'page': _page, 'limit': 20};
      if (_category != null && _category != 'All') params['category'] = _category;
      if (_search.isNotEmpty) params['search'] = _search;
      final response = await _dio.get(ApiEndpoints.listings, queryParameters: params);
      final data = response.data;
      List<dynamic> items;
      if (data is Map<String, dynamic> && data['data'] is List) {
        items = data['data'] as List<dynamic>;
        _hasMore = (data['meta']?['hasNext'] as bool?) ?? false;
      } else if (data is List) {
        items = data;
        _hasMore = false;
      } else {
        items = [];
        _hasMore = false;
      }
      final newItems = items
          .map((e) => ListingEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      _items.addAll(newItems);
      _page++;
      state = AsyncValue.data(List<ListingEntity>.from(_items));
    } catch (e, st) {
      if (_items.isEmpty) state = AsyncValue.error(e, st);
    }
  }

  void filterByCategory(String? category) {
    _category = category;
    fetch(refresh: true);
  }

  void search(String query) {
    _search = query;
    fetch(refresh: true);
  }

  Future<void> refresh() => fetch(refresh: true);
}

final listingsProvider =
    StateNotifierProvider<ListingsNotifier, AsyncValue<List<ListingEntity>>>((ref) {
  return ListingsNotifier(ref.read(dioClientProvider));
});

final listingDetailProvider =
    FutureProvider.family<ListingEntity, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.listingById(id));
  return ListingEntity.fromJson(response.data as Map<String, dynamic>);
});
