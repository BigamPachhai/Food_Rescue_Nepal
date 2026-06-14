import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class ReviewEntity {
  final String id;
  final String customerId;
  final String vendorId;
  final String orderId;
  final int rating;
  final String? comment;
  final String? vendorResponse;
  final DateTime? vendorRespondedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? vendor;

  const ReviewEntity({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.vendorResponse,
    this.vendorRespondedAt,
    required this.createdAt,
    this.customer,
    this.vendor,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) => ReviewEntity(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        vendorId: json['vendorId'] as String,
        orderId: json['orderId'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        vendorResponse: json['vendorResponse'] as String?,
        vendorRespondedAt: json['vendorRespondedAt'] != null
            ? DateTime.parse(json['vendorRespondedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        customer: json['customer'] as Map<String, dynamic>?,
        vendor: json['vendor'] as Map<String, dynamic>?,
      );

  String get customerName =>
      customer?['name'] as String? ?? 'Customer';
  String? get customerAvatar => customer?['avatarUrl'] as String?;
  String get vendorName =>
      vendor?['businessName'] as String? ?? 'Vendor';
}

// ── Vendor reviews provider (paginated list) ──────────────────────────────

class VendorReviewsNotifier extends StateNotifier<AsyncValue<List<ReviewEntity>>> {
  VendorReviewsNotifier(this._dio, this._vendorId)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  final Dio _dio;
  final String _vendorId;

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final response = await _dio.get(
        ApiEndpoints.vendorReviews(_vendorId),
        queryParameters: {'limit': 50},
      );
      final body = response.data as Map<String, dynamic>;
      final inner = body['data'];
      List<dynamic> items = [];
      if (inner is List) {
        items = inner;
      } else if (inner is Map<String, dynamic> && inner['reviews'] is List) {
        items = inner['reviews'] as List<dynamic>;
      }
      state = AsyncValue.data(
        items.map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addResponse(String reviewId, String response) async {
    await _dio.patch(ApiEndpoints.reviewRespond(reviewId),
        data: {'response': response});
    await fetch();
  }
}

final vendorReviewsProvider = StateNotifierProvider.family<
    VendorReviewsNotifier, AsyncValue<List<ReviewEntity>>, String>(
  (ref, vendorId) => VendorReviewsNotifier(ref.read(dioClientProvider), vendorId),
);

// ── Single order review provider ──────────────────────────────────────────

final orderReviewProvider =
    FutureProvider.family<ReviewEntity?, String>((ref, orderId) async {
  final dio = ref.read(dioClientProvider);
  try {
    final response = await dio.get(ApiEndpoints.reviewByOrder(orderId));
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data == null) return null;
    return ReviewEntity.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

// ── My reviews provider ───────────────────────────────────────────────────

final myReviewsProvider = FutureProvider<List<ReviewEntity>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.myReviews);
  final body = response.data as Map<String, dynamic>;
  final data = body['data'];
  final items = data is List ? data : <dynamic>[];
  return items
      .map((e) => ReviewEntity.fromJson(e as Map<String, dynamic>))
      .toList();
});
