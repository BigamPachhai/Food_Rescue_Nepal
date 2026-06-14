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
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          notifsAsync.when(
            data: (notifs) => notifs.isEmpty
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) async {
                      if (val == 'mark_all') {
                        ref.read(notificationsProvider.notifier).markAllRead();
                      } else if (val == 'delete_all') {
                        final ok = await _confirmDeleteAll(context);
                        if (ok) {
                          ref.read(notificationsProvider.notifier).deleteAll();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      if (unread > 0)
                        const PopupMenuItem(
                          value: 'mark_all',
                          child: Row(
                            children: [
                              Icon(Icons.done_all, size: 18, color: AppColors.primaryMedium),
                              SizedBox(width: 8),
                              Text('Mark all as read'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete all', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none_outlined,
              title: 'All caught up!',
              subtitle: 'No notifications yet.',
            );
          }

          final unreadList = notifs.where((n) => !n.isRead).toList();
          final readList = notifs.where((n) => n.isRead).toList();

          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () => ref.read(notificationsProvider.notifier).fetch(),
            child: ListView(
              children: [
                if (unreadList.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'New (${unreadList.length})',
                    action: TextButton(
                      onPressed: () =>
                          ref.read(notificationsProvider.notifier).markAllRead(),
                      child: const Text('Mark all read',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryMedium)),
                    ),
                  ),
                  ...unreadList.map(
                    (n) => _NotifTile(
                      notification: n,
                      onTap: () {
                        ref.read(notificationsProvider.notifier).markRead(n.id);
                        _navigate(context, n);
                      },
                      onDelete: () =>
                          ref.read(notificationsProvider.notifier).delete(n.id),
                    ),
                  ),
                ],
                if (readList.isNotEmpty) ...[
                  const _SectionHeader(label: 'Earlier'),
                  ...readList.map(
                    (n) => _NotifTile(
                      notification: n,
                      onTap: () => _navigate(context, n),
                      onDelete: () =>
                          ref.read(notificationsProvider.notifier).delete(n.id),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ShimmerCard(height: 72),
          ),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(notificationsProvider.notifier).fetch(),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, NotificationEntity notif) {
    final orderId = notif.data['orderId'] as String?;
    final listingId = notif.data['listingId'] as String?;
    if (orderId != null) {
      notif.type.startsWith('VENDOR_')
          ? context.push('/vendor/orders/$orderId')
          : context.push('/customer/orders/$orderId');
    } else if (listingId != null) {
      context.push('/customer/listing/$listingId');
    }
  }

  Future<bool> _confirmDeleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.action});
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ─── Notification tile with swipe-to-delete ────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotifIcon(type: notification.type, isRead: notification.isRead),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTextStyles.h6.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4, left: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryMedium,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.body,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.timeAgo(notification.createdAt),
                          style:
                              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Icon by notification type ─────────────────────────────────────────────

class _NotifIcon extends StatelessWidget {
  const _NotifIcon({required this.type, required this.isRead});
  final String type;
  final bool isRead;

  static const _typeConfig = <String, (IconData, Color)>{
    'ORDER_PLACED': (Icons.add_shopping_cart_outlined, AppColors.info),
    'ORDER_CONFIRMED': (Icons.check_circle_outline, AppColors.success),
    'ORDER_READY': (Icons.restaurant_outlined, AppColors.success),
    'ORDER_PICKED_UP': (Icons.done_all, AppColors.primaryMedium),
    'ORDER_CANCELLED': (Icons.cancel_outlined, AppColors.error),
    'VENDOR_NEW_ORDER': (Icons.notifications_active_outlined, AppColors.accentAmber),
    'VENDOR_ORDER_CANCELLED': (Icons.cancel_outlined, AppColors.error),
    'NEARBY_FOOD': (Icons.location_on_outlined, AppColors.primaryMedium),
    'RESERVATION_ACCEPTED': (Icons.check_circle_outline, AppColors.success),
    'RESERVATION_REJECTED': (Icons.cancel_outlined, AppColors.error),
    'PICKUP_REMINDER': (Icons.alarm_outlined, AppColors.accentAmber),
    'LISTING_EXPIRING': (Icons.hourglass_bottom_outlined, Colors.orange),
    'FOOD_SOLD_OUT': (Icons.inventory_2_outlined, AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig[type];
    final icon = config?.$1 ?? Icons.notifications_outlined;
    final color = config?.$2 ?? AppColors.textSecondary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF0F0F0) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: isRead ? AppColors.textSecondary : color, size: 22),
    );
  }
}
