import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) => NotificationEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String? ?? 'GENERAL',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        title: title,
        body: body,
        type: type,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  NotificationsNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Dio _dio;

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final response = await _dio.get(ApiEndpoints.notifications);
      final body = response.data as Map<String, dynamic>;
      final inner = body['data'];
      List<dynamic> items = [];
      if (inner is List) {
        items = inner;
      } else if (inner is Map<String, dynamic>) {
        final notifs = inner['notifications'];
        if (notifs is List) items = notifs;
      }
      state = AsyncValue.data(
        items.map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch(ApiEndpoints.markRead(id));
      state.whenData((list) {
        state = AsyncValue.data(
          list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
        );
      });
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch(ApiEndpoints.markAllRead);
      state.whenData((list) {
        state = AsyncValue.data(list.map((n) => n.copyWith(isRead: true)).toList());
      });
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.deleteNotification(id));
      state.whenData((list) {
        state = AsyncValue.data(list.where((n) => n.id != id).toList());
      });
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    try {
      await _dio.delete(ApiEndpoints.deleteAllNotifications);
      state = const AsyncValue.data([]);
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationEntity>>>((ref) {
  return NotificationsNotifier(ref.read(dioClientProvider));
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).when(
        data: (list) => list.where((n) => !n.isRead).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
