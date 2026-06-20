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

  // [listing] is passed in so we can optimistically add/remove before the network call.
  Future<bool> toggle(String listingId, {ListingEntity? listing}) async {
    final snapshot = state.value ?? [];
    final wasInFavorites = snapshot.any((f) => f.id == listingId);

    // Optimistic update — instant UI change before any network call
    if (wasInFavorites) {
      state = AsyncValue.data(snapshot.where((f) => f.id != listingId).toList());
    } else if (listing != null) {
      state = AsyncValue.data([listing, ...snapshot]);
    }

    try {
      final response = await _dio.post(ApiEndpoints.toggleFavorite(listingId));
      final favorited = (response.data as Map<String, dynamic>)['data']['favorited'] as bool? ?? false;
      // If server disagrees with our optimistic state, correct it silently in background
      if (favorited != !wasInFavorites) fetch();
      return favorited;
    } catch (_) {
      // Revert optimistic change on error
      state = AsyncValue.data(snapshot);
      return wasInFavorites;
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

  Future<bool> toggle(String vendorId, {VendorEntity? vendor}) async {
    final snapshot = state.value ?? [];
    final wasInFavorites = snapshot.any((v) => v.id == vendorId);

    // Optimistic update
    if (wasInFavorites) {
      state = AsyncValue.data(snapshot.where((v) => v.id != vendorId).toList());
    } else if (vendor != null) {
      state = AsyncValue.data([vendor, ...snapshot]);
    }

    try {
      final response = await _dio.post(ApiEndpoints.toggleVendorFavorite(vendorId));
      final favorited = (response.data as Map<String, dynamic>)['data']['favorited'] as bool? ?? false;
      if (favorited != !wasInFavorites) fetch();
      return favorited;
    } catch (_) {
      state = AsyncValue.data(snapshot);
      return wasInFavorites;
    }
  }
}

final vendorFavoritesProvider =
    StateNotifierProvider<VendorFavoritesNotifier, AsyncValue<List<VendorEntity>>>((ref) {
  return VendorFavoritesNotifier(ref.read(dioClientProvider));
});
