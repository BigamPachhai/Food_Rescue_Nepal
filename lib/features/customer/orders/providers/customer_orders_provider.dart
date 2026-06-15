import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../home/providers/listings_provider.dart';

class UserMinimal {
  final String id;
  final String name;
  final String email;
  const UserMinimal({required this.id, required this.name, required this.email});

  factory UserMinimal.fromJson(Map<String, dynamic> json) => UserMinimal(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

class OrderEntity {
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
  final VendorEntity? vendor;
  final UserMinimal? customer;

  const OrderEntity({
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
    this.vendor,
    this.customer,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) => OrderEntity(
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
        vendor: json['vendor'] != null
            ? VendorEntity.fromJson(json['vendor'] as Map<String, dynamic>)
            : null,
        customer: json['customer'] != null
            ? UserMinimal.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
      );

  bool get isActive =>
      status == 'PENDING' || status == 'ACCEPTED' || status == 'READY';
  bool get isTerminal =>
      status == 'COMPLETED' || status == 'CANCELLED' || status == 'REJECTED' || status == 'EXPIRED';
  bool get canShowQr => status == 'ACCEPTED' || status == 'READY';
  bool get canCancel {
    if (status != 'PENDING') return false;
    return DateTime.now().difference(createdAt).inMinutes < 10;
  }
}

class CustomerOrdersNotifier
    extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  CustomerOrdersNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }
  final Dio _dio;

  Future<void> fetch() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerOrders);
      final data = response.data;
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else if (data is Map && data['data'] is Map) {
        final inner = data['data'] as Map;
        items = inner['orders'] as List<dynamic>? ?? [];
      } else {
        items = [];
      }
      state = AsyncValue.data(
        items
            .map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final customerOrdersProvider =
    StateNotifierProvider<CustomerOrdersNotifier, AsyncValue<List<OrderEntity>>>(
        (ref) {
  return CustomerOrdersNotifier(ref.read(dioClientProvider));
});

final orderDetailProvider =
    FutureProvider.family<OrderEntity, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.orderById(id));
  final raw = response.data as Map<String, dynamic>;
  final data = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return OrderEntity.fromJson(data);
});
