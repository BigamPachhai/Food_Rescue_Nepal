import 'package:cached_network_image/cached_network_image.dart';
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
    // Always fetch fresh orders when this screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(customerOrdersProvider);
    });
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
          final totalSaved = history
              .where((o) => o.status == 'COMPLETED')
              .fold<int>(0, (sum, o) {
                final orig = (o.listing?.originalPrice ?? 0) * o.quantity;
                return sum + (orig - o.totalAmount).clamp(0, orig);
              });
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(orders: active, isActive: true),
              _OrderList(orders: history, isActive: false, totalSaved: totalSaved),
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
  const _OrderList({required this.orders, required this.isActive, this.totalSaved = 0});
  final List<OrderEntity> orders;
  final bool isActive;
  final int totalSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () => ref.read(customerOrdersProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              icon: isActive
                  ? Icons.shopping_bag_outlined
                  : Icons.receipt_long_outlined,
              title: isActive
                  ? 'No active reservations'
                  : 'No reservation history',
              subtitle: isActive
                  ? 'Browse deals nearby and reserve your first item!'
                  : 'Your completed and cancelled reservations appear here.',
              ctaLabel: isActive ? 'Browse Food' : null,
              onCtaTap: isActive ? () => context.go('/customer/home') : null,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryMedium,
      onRefresh: () => ref.read(customerOrdersProvider.notifier).fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, AppSizes.s4),
        itemCount: orders.length + (!isActive && totalSaved > 0 ? 1 : 0),
        itemBuilder: (_, i) {
          if (!isActive && totalSaved > 0 && i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSizes.s3),
              padding: const EdgeInsets.all(AppSizes.s3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: AppSizes.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total saved: ${Formatters.formatNPR(totalSaved)}',
                          style: AppTextStyles.h5.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Across ${orders.where((o) => o.status == 'COMPLETED').length} completed rescues',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final idx = (!isActive && totalSaved > 0) ? i - 1 : i;
          return _OrderCard(order: orders[idx]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderEntity order;

  double _pickupProgress() {
    final listing = order.listing;
    if (listing == null || !order.isActive) return 0;
    final now = DateTime.now();
    final total = listing.pickupEnd.difference(listing.pickupStart).inSeconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(listing.pickupStart).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _pickupProgress();
    final isUrgent = order.isActive &&
        order.listing != null &&
        order.listing!.pickupEnd.difference(DateTime.now()).inMinutes <= 30;

    return GestureDetector(
      onTap: () => context.push('/customer/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s2),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.s3),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: order.listing?.imageUrls.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: order.listing!.imageUrls.first,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            memCacheWidth: 104,
                            memCacheHeight: 104,
                            errorWidget: (_, __, ___) => _thumbnail(),
                          )
                        : _thumbnail(),
                  ),
                  const SizedBox(width: AppSizes.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.listing?.name ?? 'Order #${order.id.substring(0, 6)}',
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
                        if (order.isActive && order.listing != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Pickup: ${Formatters.formatPickupTime(order.listing!.pickupStart, order.listing!.pickupEnd)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isUrgent ? AppColors.error : AppColors.primaryMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(Formatters.formatDateTime(order.createdAt), style: AppTextStyles.caption),
                        ],
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
                        style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSizes.s1),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400, size: AppSizes.iconMd),
                ],
              ),
            ),
            // Quick actions row — only show QR for orders vendor has accepted/readied
            if (order.isActive &&
                (order.status == 'ACCEPTED' || order.status == 'READY'))
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.s3, 0, AppSizes.s3, AppSizes.s2),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/customer/qr/${order.id}'),
                  icon: const Icon(Icons.qr_code_rounded, size: 14),
                  label: const Text('Show QR'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    foregroundColor: AppColors.primaryMedium,
                    side: const BorderSide(color: AppColors.primaryMedium),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
                    textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            // Reorder button on completed orders
            if (order.status == 'COMPLETED' && order.listing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.s3, 0, AppSizes.s3, AppSizes.s2),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/customer/listing/${order.listing!.id}'),
                    icon: const Icon(Icons.repeat_rounded, size: 14),
                    label: const Text('Order again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      foregroundColor: AppColors.primaryMedium,
                      side: const BorderSide(color: AppColors.primaryMedium),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
                      textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            // Pickup window progress bar for active orders
            if (order.isActive && order.listing != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSizes.radiusCard)),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.neutral100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? AppColors.error : AppColors.primaryMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() => Container(
        width: 52,
        height: 52,
        color: AppColors.primarySurface,
        child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryLight, size: AppSizes.iconLg),
      );
}
