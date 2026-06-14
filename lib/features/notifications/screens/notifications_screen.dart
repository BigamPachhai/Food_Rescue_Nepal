import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).fetch(),
            child: ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _NotifTile(
                notification: notifs[i],
                onTap: () {
                  ref
                      .read(notificationsProvider.notifier)
                      .markRead(notifs[i].id);
                  _navigate(context, notifs[i]);
                },
              ),
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerCard(height: 72),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(notificationsProvider.notifier).fetch(),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, NotificationEntity notif) {
    final orderId = notif.data['orderId'] as String?;
    if (orderId != null) {
      // Determine customer vs vendor from notification type
      if (notif.type.startsWith('VENDOR_')) {
        context.push('/vendor/orders/$orderId');
      } else {
        context.push('/customer/orders/$orderId');
      }
    }
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notification,
    required this.onTap,
  });
  final NotificationEntity notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case 'ORDER_PLACED':
        return Icons.add_shopping_cart;
      case 'ORDER_CONFIRMED':
        return Icons.check_circle_outline;
      case 'ORDER_READY':
        return Icons.restaurant;
      case 'ORDER_PICKED_UP':
        return Icons.done_all;
      case 'ORDER_CANCELLED':
        return Icons.cancel_outlined;
      case 'VENDOR_NEW_ORDER':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.primarySurface
                    : AppColors.primaryMedium.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: notification.isRead
                    ? AppColors.textSecondary
                    : AppColors.primaryMedium,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.timeAgo(notification.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
