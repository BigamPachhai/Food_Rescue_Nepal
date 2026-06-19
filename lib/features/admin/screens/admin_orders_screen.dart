import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _statusFilter = '';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_statusFilter));

    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                '',
                'PENDING',
                'ACCEPTED',
                'READY',
                'COMPLETED',
                'CANCELLED',
                'REJECTED',
              ].map((s) {
                final label = s.isEmpty
                    ? 'All'
                    : s.replaceAll('_', ' ')[0] +
                        s
                            .replaceAll('_', ' ')
                            .substring(1)
                            .toLowerCase();
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _statusFilter = s),
                    selectedColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryMedium
                          : AppColors.primarySurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders found',
                    subtitle: 'Try adjusting your filter.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primaryMedium,
                  onRefresh: () async => ref
                      .invalidate(adminOrdersProvider(_statusFilter)),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, i) =>
                        _AdminOrderTile(order: orders[i]),
                  ),
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const ShimmerCard(height: 80),
              ),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(adminOrdersProvider(_statusFilter)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  const _AdminOrderTile({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/admin/orders/${order.id}'),
      leading: const CircleAvatar(
        backgroundColor: AppColors.primarySurface,
        child: Icon(Icons.receipt_long,
            color: AppColors.primaryLight, size: 20),
      ),
      title: Text(
        order.listingName ?? 'Order #${order.id.substring(0, 6)}',
        style: AppTextStyles.h6,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${order.customerName ?? ''} → ${order.vendorName ?? ''} · ${Formatters.formatDate(order.createdAt)}',
        style: AppTextStyles.caption,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: order.status, compact: true),
            const SizedBox(height: 2),
            Text(
              Formatters.formatNPR(order.totalAmount),
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
