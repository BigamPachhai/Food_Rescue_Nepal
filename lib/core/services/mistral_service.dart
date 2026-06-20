import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../constants/api_endpoints.dart';

/// All AI calls go through the backend — the Mistral API key never leaves the server.
class MistralService {
  final Dio _dio;
  MistralService(this._dio);

  Future<String> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
      );
      final data = res.data as Map<String, dynamic>;
      return (data['result'] as String?) ?? (data['reply'] as String?) ?? '';
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] ?? e.message ?? 'AI unavailable';
      return '⚠️ AI is temporarily unavailable: $msg';
    }
  }

  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
  }) =>
      _post(ApiEndpoints.aiChat, {'message': message, 'history': history});

  Future<String> generateFoodDescription(
          String name, String category, double price) =>
      _post(ApiEndpoints.aiDescription,
          {'name': name, 'category': category, 'price': price});

  Future<String> suggestPrice(
          String name, double originalPrice, int quantityLeft) =>
      _post(ApiEndpoints.aiPricing,
          {'name': name, 'originalPrice': originalPrice, 'quantityLeft': quantityLeft});

  Future<String> suggestRecipes(List<String> ingredients) =>
      _post(ApiEndpoints.aiRecipes, {'ingredients': ingredients});

  Future<String> analyzeSentiment(List<String> reviews) =>
      _post(ApiEndpoints.aiSentiment, {'reviews': reviews});

  Future<String> predictDemand(String itemName, List<int> weeklySales) =>
      _post(ApiEndpoints.aiDemand,
          {'itemName': itemName, 'weeklySales': weeklySales});

  // Legacy signature kept for compatibility with existing screens
  Future<String> getPersonalizedRecommendations(
          List<String> previousOrders, String location) =>
      chat('Recommend food items for a customer in $location who previously ordered: '
          '${previousOrders.join(', ')}.');

  Future<String> analyzeWastePatterns(Map<String, int> cancelledByDay) =>
      _post(ApiEndpoints.aiDemand, {
        'itemName': 'waste analysis',
        'weeklySales': cancelledByDay.values.toList(),
      });
}

final mistralServiceProvider = Provider<MistralService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return MistralService(dio);
});
