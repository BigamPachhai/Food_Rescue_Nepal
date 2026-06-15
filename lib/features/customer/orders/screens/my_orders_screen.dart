import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabCtrl,
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
          padding: const EdgeInsets.all(AppSizes.s4),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.s2),
            child: ShimmerCard(height: 88),
          ),
        ),
        error: (e, _) => ErrorView(
          error: e,
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
        title: isActive ? 'No active reservations' : 'No reservation history',
        subtitle: isActive
            ? 'Reserve food from the home screen.'
            : 'Your completed reservations appear here.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryMedium,
      onRefresh: () => ref.read(customerOrdersProvider.notifier).fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.s4, AppSizes.s3, AppSizes.s4, AppSizes.s4),
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
    return GestureDetector(
      onTap: () => context.push('/customer/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s2),
        padding: const EdgeInsets.all(AppSizes.s3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.fastfood_rounded,
                color: AppColors.primaryLight,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(width: AppSizes.s3),
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
                  if (order.vendor?.businessName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.vendor!.businessName,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatDateTime(order.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: order.status, compact: true),
                const SizedBox(height: AppSizes.s1),
                Text(
                  Formatters.formatNPR(order.totalAmount),
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.primaryMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSizes.s1),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral400,
              size: AppSizes.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}
