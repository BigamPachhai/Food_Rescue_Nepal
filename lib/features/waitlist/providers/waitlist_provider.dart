import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class WaitlistEntry {
  final String listingId;
  final String listingName;
  final List<String> imageUrls;
  final int discountedPrice;
  final int availableQty;

  const WaitlistEntry({
    required this.listingId,
    required this.listingName,
    required this.imageUrls,
    required this.discountedPrice,
    required this.availableQty,
  });

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>? ?? {};
    return WaitlistEntry(
      listingId: listing['id'] as String? ?? '',
      listingName: listing['name'] as String? ?? '',
      imageUrls: (listing['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      discountedPrice: (listing['discountedPrice'] as num?)?.toInt() ?? 0,
      availableQty: (listing['availableQty'] as num?)?.toInt() ?? 0,
    );
  }
}

class WaitlistNotifier extends StateNotifier<AsyncValue<List<WaitlistEntry>>> {
  WaitlistNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchMyWaitlist();
  }

  final Ref _ref;

  Future<void> fetchMyWaitlist() async {
    try {
      state = const AsyncValue.loading();
      final dio = _ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.myWaitlist);
      final raw = response.data as Map<String, dynamic>;
      final data = raw['data'];
      final items = data is List ? data : <dynamic>[];
      state = AsyncValue.data(
        items.map((e) => WaitlistEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> join(String listingId) async {
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.waitlistJoin(listingId));
      fetchMyWaitlist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leave(String listingId) async {
    try {
      final dio = _ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.waitlistLeave(listingId));
      fetchMyWaitlist();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final waitlistProvider =
    StateNotifierProvider<WaitlistNotifier, AsyncValue<List<WaitlistEntry>>>((ref) {
  return WaitlistNotifier(ref);
});

final waitlistStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, listingId) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.waitlistStatus(listingId));
  final raw = response.data as Map<String, dynamic>;
  return raw['data'] as Map<String, dynamic>? ?? {};
});
