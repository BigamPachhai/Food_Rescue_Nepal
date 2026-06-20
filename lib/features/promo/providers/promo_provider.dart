import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class PromoResult {
  final bool valid;
  final String promoCodeId;
  final int discountAmount;
  final int finalAmount;
  final String? description;

  const PromoResult({
    required this.valid,
    required this.promoCodeId,
    required this.discountAmount,
    required this.finalAmount,
    this.description,
  });

  factory PromoResult.fromJson(Map<String, dynamic> json) => PromoResult(
        valid: json['valid'] as bool? ?? false,
        promoCodeId: json['promoCodeId'] as String? ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
        finalAmount: (json['finalAmount'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
      );
}

final activePromoProvider = StateProvider<PromoResult?>((ref) => null);

Future<PromoResult?> validatePromoCode(Ref ref, String code, int orderAmount) async {
  try {
    final dio = ref.read(dioClientProvider);
    final response = await dio.post(ApiEndpoints.validatePromo, data: {
      'code': code,
      'orderAmount': orderAmount,
    });
    final raw = response.data as Map<String, dynamic>;
    return PromoResult.fromJson(raw['data'] as Map<String, dynamic>? ?? raw);
  } catch (_) {
    return null;
  }
}
