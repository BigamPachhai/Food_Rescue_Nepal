import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../listings/providers/vendor_listings_provider.dart';
import '../../orders/providers/vendor_orders_provider.dart';
import '../providers/vendor_stats_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final listingsAsync = ref.watch(vendorListingsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async {
          ref.invalidate(vendorStatsProvider);
          ref.invalidate(vendorOrdersProvider);
          ref.invalidate(vendorListingsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(authState)),
            // Pending vendor banner
            if (authState is AuthAuthenticated)
              SliverToBoxAdapter(child: _buildPendingBanner(authState)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: statsAsync.when(
                  data: (stats) => _StatsRow(stats: stats),
                  loading: () => const ShimmerCard(height: 90),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(vendorStatsProvider),
                  ),
                ),
              ),
            ),
            // Pending orders section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text('Pending Orders', style: AppTextStyles.h5),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/vendor/orders'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            ordersAsync.when(
              data: (orders) {
                final pending = orders
                    .where((o) => o.status == 'PENDING')
                    .take(3)
                    .toList();
                if (pending.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No pending orders',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PendingOrderCard(order: pending[i]),
                    childCount: pending.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: ShimmerCard(height: 80),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),
            // Active listings section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Active Listings', style: AppTextStyles.h5),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/vendor/listings'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            listingsAsync.when(
              data: (listings) {
                final active =
                    listings.where((l) => l.isActive).take(3).toList();
                if (active.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No active listings',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/vendor/listings/add'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Listing'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ActiveListingTile(listing: active[i]),
                    childCount: active.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: ShimmerCard(height: 70),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendor/listings/add'),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Listing',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(AuthState authState) {
    final name = authState is AuthAuthenticated
        ? authState.user.name
        : 'Vendor';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            radius: 24,
            child: Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back!',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
                Text(name,
                    style: AppTextStyles.h4
                        .copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner(AuthAuthenticated authState) {
    // Show banner if vendor status is PENDING (would need vendor data)
    return const SizedBox.shrink();
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final VendorStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's Orders",
            value: '${stats.todayOrders}',
            icon: Icons.receipt_long,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Earned Today',
            value: Formatters.formatNPR(stats.todayEarnedPaisa),
            icon: Icons.payments_outlined,
            color: AppColors.primaryMedium,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Food Saved',
            value: '${stats.foodSavedKg.toStringAsFixed(1)} kg',
            icon: Icons.eco_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.h6.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: AppTextStyles.caption, maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PendingOrderCard extends ConsumerWidget {
  const _PendingOrderCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusPending.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pending_outlined,
                color: AppColors.statusPending, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.listing?.name ?? 'Order #${order.id.substring(0, 6)}',
                  style: AppTextStyles.h6,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('x${order.quantity} · ${Formatters.formatNPR(order.totalAmount)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/vendor/orders/${order.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActiveListingTile extends StatelessWidget {
  const _ActiveListingTile({required this.listing});
  final VendorListing listing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.fastfood_outlined,
            color: AppColors.primaryLight, size: 22),
      ),
      title: Text(listing.name, style: AppTextStyles.h6),
      subtitle: Text(
        '${listing.availableQty} left · ${Formatters.formatNPR(listing.discountedPrice)}',
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary),
      onTap: () => context.push('/vendor/listings/${listing.id}/edit'),
    );
  }
}
