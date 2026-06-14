import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../home/providers/listings_provider.dart';

class FavoritesNotifier
    extends StateNotifier<AsyncValue<List<ListingEntity>>> {
  FavoritesNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerFavorites);
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
            .map((e) => ListingEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(String listingId) async {
    try {
      await _dio.post(ApiEndpoints.toggleFavorite(listingId));
      await fetch();
    } catch (_) {}
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<ListingEntity>>>(
        (ref) {
  return FavoritesNotifier(ref.read(dioClientProvider));
});
