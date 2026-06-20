import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class LoyaltyTransaction {
  final String id;
  final String type;
  final int points;
  final String description;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) => LoyaltyTransaction(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class LoyaltyState {
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final List<LoyaltyTransaction> transactions;

  const LoyaltyState({
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.transactions = const [],
  });

  factory LoyaltyState.fromJson(Map<String, dynamic> json) => LoyaltyState(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        totalEarned: (json['totalEarned'] as num?)?.toInt() ?? 0,
        totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

final loyaltyProvider = FutureProvider<LoyaltyState>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.loyalty);
  final raw = response.data as Map<String, dynamic>;
  final data = raw['data'] as Map<String, dynamic>? ?? raw;
  return LoyaltyState.fromJson(data);
});
