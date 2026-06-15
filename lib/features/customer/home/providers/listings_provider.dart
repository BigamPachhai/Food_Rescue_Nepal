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
  final double? distance;

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
    this.distance,
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
        distance: (json['distance'] as num?)?.toDouble(),
      );

  int get discountPercent {
    if (originalPrice == 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }
}

class ListingsFilter {
  final String? category;
  final String search;
  final String sortBy;
  final int? minPrice;
  final int? maxPrice;
  final double? maxDistance;
  final double? minRating;
  final bool onlyAvailable;
  final double? userLat;
  final double? userLng;

  const ListingsFilter({
    this.category,
    this.search = '',
    this.sortBy = 'newest',
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.minRating,
    this.onlyAvailable = false,
    this.userLat,
    this.userLng,
  });

  bool get hasActiveFilters =>
      (category != null && category != 'All') ||
      minPrice != null ||
      maxPrice != null ||
      maxDistance != null ||
      minRating != null ||
      onlyAvailable ||
      sortBy != 'newest';

  ListingsFilter copyWith({
    String? category,
    String? search,
    String? sortBy,
    int? minPrice,
    int? maxPrice,
    double? maxDistance,
    double? minRating,
    bool? onlyAvailable,
    double? userLat,
    double? userLng,
    bool clearCategory = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMaxDistance = false,
    bool clearMinRating = false,
  }) =>
      ListingsFilter(
        category: clearCategory ? null : (category ?? this.category),
        search: search ?? this.search,
        sortBy: sortBy ?? this.sortBy,
        minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
        maxDistance: clearMaxDistance ? null : (maxDistance ?? this.maxDistance),
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
        onlyAvailable: onlyAvailable ?? this.onlyAvailable,
        userLat: userLat ?? this.userLat,
        userLng: userLng ?? this.userLng,
      );
}

class ListingsNotifier extends StateNotifier<AsyncValue<List<ListingEntity>>> {
  ListingsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch(refresh: true);
  }

  final Dio _dio;
  int _page = 1;
  bool _hasMore = true;
  final List<ListingEntity> _items = [];
  ListingsFilter _filter = const ListingsFilter();

  ListingsFilter get currentFilter => _filter;
  bool get hasMore => _hasMore;

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
      if (_filter.category != null && _filter.category != 'All') {
        params['category'] = _filter.category!.toUpperCase();
      }
      if (_filter.search.isNotEmpty) params['search'] = _filter.search;
      if (_filter.sortBy != 'newest') params['sortBy'] = _filter.sortBy;
      if (_filter.minPrice != null) params['minPrice'] = _filter.minPrice;
      if (_filter.maxPrice != null) params['maxPrice'] = _filter.maxPrice;
      if (_filter.minRating != null) params['minRating'] = _filter.minRating;
      if (_filter.onlyAvailable) params['onlyAvailable'] = 'true';
      if (_filter.userLat != null) params['lat'] = _filter.userLat;
      if (_filter.userLng != null) params['lng'] = _filter.userLng;
      if (_filter.maxDistance != null) params['radius'] = _filter.maxDistance;

      final response = await _dio.get(ApiEndpoints.listings, queryParameters: params);
      final body = response.data;

      List<dynamic> items = [];
      int? total;

      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is List) {
          // { data: [...] }
          items = data;
        } else if (data is Map<String, dynamic>) {
          // { data: { listings: [...], total, page } }
          final listingsRaw = data['listings'];
          if (listingsRaw is List) {
            items = listingsRaw;
            total = data['total'] as int?;
          }
        }
      } else if (body is List) {
        items = body;
      }

      final newItems = items
          .map((e) => ListingEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      _items.addAll(newItems);
      _page++;

      if (total != null) {
        _hasMore = _items.length < total;
      } else {
        _hasMore = newItems.length == 20;
      }

      state = AsyncValue.data(List<ListingEntity>.from(_items));
    } catch (e, st) {
      if (_items.isEmpty) state = AsyncValue.error(e, st);
    }
  }

  void applyFilter(ListingsFilter filter) {
    _filter = filter;
    fetch(refresh: true);
  }

  void filterByCategory(String? category) {
    _filter = _filter.copyWith(
      category: category,
      clearCategory: category == null || category == 'All',
    );
    fetch(refresh: true);
  }

  void search(String query) {
    _filter = _filter.copyWith(search: query);
    fetch(refresh: true);
  }

  void resetFilters() {
    _filter = const ListingsFilter();
    fetch(refresh: true);
  }

  Future<void> refresh() => fetch(refresh: true);
}

final listingsProvider =
    StateNotifierProvider<ListingsNotifier, AsyncValue<List<ListingEntity>>>((ref) {
  return ListingsNotifier(ref.read(dioClientProvider));
});

// Featured listings — top discounts, no pagination needed
final featuredListingsProvider = FutureProvider<List<ListingEntity>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.listings,
    queryParameters: {'sortBy': 'discount', 'limit': 8, 'page': 1, 'onlyAvailable': 'true'},
  );
  final body = response.data as Map<String, dynamic>;
  final data = body['data'];
  List<dynamic> items = [];
  if (data is List) items = data;
  if (data is Map<String, dynamic> && data['listings'] is List) {
    items = data['listings'] as List<dynamic>;
  }
  return items.map((e) => ListingEntity.fromJson(e as Map<String, dynamic>)).toList();
});

// Public vendor list for "Popular Vendors" section
final publicVendorsProvider = FutureProvider<List<VendorEntity>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendors);
  final body = response.data as Map<String, dynamic>;
  final data = body['data'];
  List<dynamic> items = data is List ? data : [];
  return items.map((e) => VendorEntity.fromJson(e as Map<String, dynamic>)).toList();
});

// Pre-sorted top-10 approved vendors — computed once when publicVendorsProvider settles.
final topVendorsProvider = Provider<AsyncValue<List<VendorEntity>>>((ref) {
  return ref.watch(publicVendorsProvider).whenData((vendors) {
    final approved = vendors.where((v) => v.status == 'APPROVED').toList()
      ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
    return approved.take(10).toList();
  });
});

final listingDetailProvider =
    FutureProvider.family<ListingEntity, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.listingById(id));
  final raw = response.data as Map<String, dynamic>;
  final data = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return ListingEntity.fromJson(data);
});
