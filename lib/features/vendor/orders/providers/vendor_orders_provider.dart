import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../customer/home/providers/listings_provider.dart';

class VendorOrder {
  final String id;
  final String customerId;
  final String vendorId;
  final String listingId;
  final int quantity;
  final int totalAmount;
  final String status;
  final String? pickupCode;
  final String? notes;
  final DateTime createdAt;
  final ListingEntity? listing;

  const VendorOrder({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.listingId,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    this.pickupCode,
    this.notes,
    required this.createdAt,
    this.listing,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) => VendorOrder(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        vendorId: json['vendorId'] as String,
        listingId: json['listingId'] as String,
        quantity: json['quantity'] as int,
        totalAmount: json['totalAmount'] as int,
        status: json['status'] as String,
        pickupCode: json['pickupCode'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        listing: json['listing'] != null
            ? ListingEntity.fromJson(json['listing'] as Map<String, dynamic>)
            : null,
      );
}

class VendorOrdersNotifier extends StateNotifier<AsyncValue<List<VendorOrder>>> {
  VendorOrdersNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    try {
      final response = await _dio.get(ApiEndpoints.vendorOrders);
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
        items.map((e) => VendorOrder.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> confirmOrder(String id) async {
    await _dio.patch('${ApiEndpoints.vendorOrderById(id)}/confirm');
    await fetch();
  }

  Future<void> markReady(String id) async {
    await _dio.patch('${ApiEndpoints.vendorOrderById(id)}/ready');
    await fetch();
  }

  Future<void> cancelOrder(String id) async {
    await _dio.patch('${ApiEndpoints.vendorOrderById(id)}/cancel');
    await fetch();
  }
}

final vendorOrdersProvider =
    StateNotifierProvider<VendorOrdersNotifier, AsyncValue<List<VendorOrder>>>((ref) {
  return VendorOrdersNotifier(ref.read(dioClientProvider));
});

final vendorOrderDetailProvider =
    FutureProvider.family<VendorOrder, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorOrderById(id));
  final raw = response.data as Map<String, dynamic>;
  final d = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return VendorOrder.fromJson(d);
});
