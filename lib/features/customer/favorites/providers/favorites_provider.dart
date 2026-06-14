import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../home/providers/listings_provider.dart';

// ── Listing favorites ────────────────────────────────────────────────────────

class FavoritesNotifier extends StateNotifier<AsyncValue<List<ListingEntity>>> {
  FavoritesNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final response = await _dio.get(ApiEndpoints.customerFavorites);
      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      final items = raw is List ? raw : <dynamic>[];
      state = AsyncValue.data(
        items.map((e) => ListingEntity.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggle(String listingId) async {
    try {
      final response = await _dio.post(ApiEndpoints.toggleFavorite(listingId));
      final favorited = (response.data as Map<String, dynamic>)['data']['favorited'] as bool? ?? false;
      await fetch();
      return favorited;
    } catch (_) {
      return false;
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<ListingEntity>>>((ref) {
  return FavoritesNotifier(ref.read(dioClientProvider));
});

// ── Vendor favorites ──────────────────────────────────────────────────────────

class VendorFavoritesNotifier extends StateNotifier<AsyncValue<List<VendorEntity>>> {
  VendorFavoritesNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final response = await _dio.get(ApiEndpoints.vendorFavorites);
      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      final items = raw is List ? raw : <dynamic>[];
      state = AsyncValue.data(
        items.map((e) => VendorEntity.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggle(String vendorId) async {
    try {
      final response = await _dio.post(ApiEndpoints.toggleVendorFavorite(vendorId));
      final favorited = (response.data as Map<String, dynamic>)['data']['favorited'] as bool? ?? false;
      await fetch();
      return favorited;
    } catch (_) {
      return false;
    }
  }
}

final vendorFavoritesProvider =
    StateNotifierProvider<VendorFavoritesNotifier, AsyncValue<List<VendorEntity>>>((ref) {
  return VendorFavoritesNotifier(ref.read(dioClientProvider));
});
