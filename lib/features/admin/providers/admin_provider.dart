import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class AdminStats {
  final int totalUsers;
  final int totalVendors;
  final int totalOrders;
  final int totalRevenuePaisa;

  const AdminStats({
    required this.totalUsers,
    required this.totalVendors,
    required this.totalOrders,
    required this.totalRevenuePaisa,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['totalUsers'] as int? ?? 0,
        totalVendors: json['totalVendors'] as int? ?? 0,
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalRevenuePaisa: json['totalRevenue'] as int? ?? 0,
      );
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminVendor {
  final String id;
  final String businessName;
  final String businessType;
  final String? address;
  final String status;
  final String ownerName;
  final String ownerEmail;

  const AdminVendor({
    required this.id,
    required this.businessName,
    required this.businessType,
    this.address,
    required this.status,
    required this.ownerName,
    required this.ownerEmail,
  });

  factory AdminVendor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminVendor(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      businessType: json['businessType'] as String? ?? '',
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      ownerName: user?['name'] as String? ?? '',
      ownerEmail: user?['email'] as String? ?? '',
    );
  }
}

class AdminOrder {
  final String id;
  final int totalAmount;
  final String status;
  final DateTime createdAt;
  final String? listingName;
  final String? customerName;
  final String? vendorName;

  const AdminOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.listingName,
    this.customerName,
    this.vendorName,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        id: json['id'] as String,
        totalAmount: json['totalAmount'] as int? ?? 0,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        listingName:
            (json['listing'] as Map<String, dynamic>?)?['name'] as String?,
        customerName:
            (json['customer'] as Map<String, dynamic>?)?['name'] as String?,
        vendorName:
            (json['vendor'] as Map<String, dynamic>?)?['businessName']
                as String?,
      );
}

// Stats
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.adminStats);
  final raw = response.data as Map<String, dynamic>;
  final data = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return AdminStats.fromJson(data);
});

// Users
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, String>((ref, search) async {
  final dio = ref.read(dioClientProvider);
  final params = search.isNotEmpty ? {'search': search} : null;
  final response =
      await dio.get(ApiEndpoints.adminUsers, queryParameters: params);
  final body = response.data as Map<String, dynamic>;
  final paginated = body['data'] as Map<String, dynamic>;
  final items = paginated['users'] as List<dynamic>? ?? [];
  return items
      .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
      .toList();
});

final adminUserDetailProvider =
    FutureProvider.family<AdminUser, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.adminUserById(id));
  final raw = response.data as Map<String, dynamic>;
  final d = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return AdminUser.fromJson(d);
});

// Vendors
final adminVendorsProvider =
    FutureProvider.family<List<AdminVendor>, String>((ref, status) async {
  final dio = ref.read(dioClientProvider);
  final params = status.isNotEmpty ? {'status': status} : null;
  final response =
      await dio.get(ApiEndpoints.adminVendors, queryParameters: params);
  final body = response.data as Map<String, dynamic>;
  final paginated = body['data'] as Map<String, dynamic>;
  final items = paginated['vendors'] as List<dynamic>? ?? [];
  return items
      .map((e) => AdminVendor.fromJson(e as Map<String, dynamic>))
      .toList();
});

final adminVendorDetailProvider =
    FutureProvider.family<AdminVendor, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.adminVendorById(id));
  final raw = response.data as Map<String, dynamic>;
  final d = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return AdminVendor.fromJson(d);
});

class AdminOrderDetail {
  final String id;
  final int totalAmount;
  final String status;
  final int quantity;
  final DateTime createdAt;
  final String? listingName;
  final String? listingDescription;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? vendorName;
  final String? vendorAddress;
  final String? qrCode;

  const AdminOrderDetail({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.quantity,
    required this.createdAt,
    this.listingName,
    this.listingDescription,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.vendorName,
    this.vendorAddress,
    this.qrCode,
  });

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return AdminOrderDetail(
      id: json['id'] as String,
      totalAmount: json['totalAmount'] as int? ?? 0,
      status: json['status'] as String,
      quantity: json['quantity'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      listingName: listing?['name'] as String?,
      listingDescription: listing?['description'] as String?,
      customerName: customer?['name'] as String?,
      customerEmail: customer?['email'] as String?,
      customerPhone: customer?['phone'] as String?,
      vendorName: vendor?['businessName'] as String?,
      vendorAddress: vendor?['address'] as String?,
      qrCode: json['qrCode'] as String?,
    );
  }
}

final adminOrderDetailProvider =
    FutureProvider.family<AdminOrderDetail, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.adminOrderById(id));
  final raw = response.data as Map<String, dynamic>;
  final d = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return AdminOrderDetail.fromJson(d);
});

// Orders
final adminOrdersProvider =
    FutureProvider.family<List<AdminOrder>, String>((ref, status) async {
  final dio = ref.read(dioClientProvider);
  final params = status.isNotEmpty ? {'status': status} : null;
  final response =
      await dio.get(ApiEndpoints.adminOrders, queryParameters: params);
  final body = response.data as Map<String, dynamic>;
  final paginated = body['data'] as Map<String, dynamic>;
  final items = paginated['orders'] as List<dynamic>? ?? [];
  return items
      .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
      .toList();
});
