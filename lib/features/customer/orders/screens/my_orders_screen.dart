import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/customer_orders_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          final active = orders.where((o) => o.isActive).toList();
          final history = orders.where((o) => !o.isActive).toList();
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(orders: active, isActive: true),
              _OrderList(orders: history, isActive: false),
            ],
          );
        },
        loading: () => ListView.builder(
          itemCount: 3,
          itemBuilder: (_, __) => const ShimmerCard(height: 100),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(customerOrdersProvider.notifier).fetch(),
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders, required this.isActive});
  final List<OrderEntity> orders;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: isActive ? 'No active orders' : 'No order history',
        subtitle: isActive
            ? 'Reserve food from the home screen.'
            : 'Your completed orders appear here.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryMedium,
      onRefresh: () => ref.read(customerOrdersProvider.notifier).fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/customer/orders/${order.id}'),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood_outlined,
                  color: AppColors.primaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.listing?.name ??
                        'Order #${order.id.substring(0, 6)}',
                    style: AppTextStyles.h6,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(order.vendor?.businessName ?? '',
                      style: AppTextStyles.caption),
                  Text(Formatters.formatDateTime(order.createdAt),
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: order.status),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatNPR(order.totalAmount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
