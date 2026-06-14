import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class VendorProfile {
  final String id;
  final String businessName;
  final String businessType;
  final String address;
  final String? description;
  final String? logoUrl;
  final double? lat;
  final double? lng;
  final String status;
  final double avgRating;
  final int totalReviews;

  const VendorProfile({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.address,
    this.description,
    this.logoUrl,
    this.lat,
    this.lng,
    required this.status,
    required this.avgRating,
    required this.totalReviews,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) => VendorProfile(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        businessType: json['businessType'] as String,
        address: json['address'] as String,
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'PENDING',
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: json['totalReviews'] as int? ?? 0,
      );
}

final vendorProfileProvider = FutureProvider<VendorProfile>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorProfile);
  final raw = response.data as Map<String, dynamic>;
  final data = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
  return VendorProfile.fromJson(data);
});
