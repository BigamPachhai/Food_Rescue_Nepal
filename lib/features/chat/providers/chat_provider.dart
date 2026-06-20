import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: sender['id'] as String? ?? '',
      senderName: sender['name'] as String? ?? 'Unknown',
      senderAvatar: sender['avatarUrl'] as String?,
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, orderId) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.chatMessages(orderId));
  final raw = response.data as Map<String, dynamic>;
  final data = raw['data'];
  final items = data is List ? data : <dynamic>[];
  return items
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList();
});

final chatUnreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(ApiEndpoints.chatUnreadCount);
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});
