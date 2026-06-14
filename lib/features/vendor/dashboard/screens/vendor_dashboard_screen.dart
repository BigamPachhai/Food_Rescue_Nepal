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
import '../../profile/providers/vendor_profile_provider.dart';
import '../providers/vendor_stats_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final listingsAsync = ref.watch(vendorListingsProvider);
    final authState = ref.watch(authProvider);
    final vendorProfileAsync = ref.watch(vendorProfileProvider);

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
            // Vendor status banner
            SliverToBoxAdapter(
              child: vendorProfileAsync.whenOrNull(
                    data: (vendor) => _buildStatusBanner(vendor.status),
                  ) ??
                  const SizedBox.shrink(),
            ),
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _StatsPanel(stats: stats),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: ShimmerCard(height: 160),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(vendorStatsProvider),
                  ),
                ),
              ),
            ),
            // Reviews quick-link
            SliverToBoxAdapter(
              child: vendorProfileAsync.whenOrNull(
                    data: (vendor) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: InkWell(
                        onTap: () =>
                            context.push('/vendor/reviews/${vendor.id}'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_outline,
                                  color: AppColors.accentAmber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer Reviews',
                                        style: AppTextStyles.h6),
                                    Text(
                                      'See what customers are saying',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ) ??
                  const SizedBox.shrink(),
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
            // Listing performance section
            SliverToBoxAdapter(
              child: statsAsync.whenOrNull(
                    data: (stats) => stats.listingPerformance.isEmpty
                        ? const SizedBox.shrink()
                        : _ListingPerformanceSection(
                            listings: stats.listingPerformance),
                  ) ??
                  const SizedBox.shrink(),
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

  Widget _buildStatusBanner(String status) {
    if (status == 'APPROVED') return const SizedBox.shrink();
    final isPending = status == 'PENDING';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.block,
            color: isPending ? AppColors.warning : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Account Pending Approval' : 'Account Suspended',
                  style: AppTextStyles.h6.copyWith(
                    color: isPending ? AppColors.warning : AppColors.error,
                  ),
                ),
                Text(
                  isPending
                      ? 'Your business is under review. You can set up listings, but they won\'t be visible until approved.'
                      : 'Your account has been suspended. Please contact support.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats panel: today + all-time ────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});
  final VendorStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Snapshot", style: AppTextStyles.h5),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Orders',
                  value: '${stats.todayOrders}',
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Earned',
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
          ),
          const SizedBox(height: 16),
          Text('All-Time Impact', style: AppTextStyles.h5),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Reservations',
                  value: '${stats.totalReservations}',
                  icon: Icons.bookmark_outline,
                  color: AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Pickups Done',
                  value: '${stats.completedPickups}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Food Saved',
                  value: '${stats.totalFoodSavedKg.toStringAsFixed(1)} kg',
                  icon: Icons.eco,
                  color: AppColors.primaryMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Listing performance section ───────────────────────────────────────────

class _ListingPerformanceSection extends StatelessWidget {
  const _ListingPerformanceSection({required this.listings});
  final List<ListingPerf> listings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing Performance', style: AppTextStyles.h5),
          const SizedBox(height: 10),
          ...listings.map((l) => _PerfTile(listing: l)),
        ],
      ),
    );
  }
}

class _PerfTile extends StatelessWidget {
  const _PerfTile({required this.listing});
  final ListingPerf listing;

  @override
  Widget build(BuildContext context) {
    final conversionRate = listing.totalOrders > 0
        ? (listing.completedOrders / listing.totalOrders * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: listing.isActive
                      ? AppColors.primarySurface
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fastfood_outlined,
                  size: 18,
                  color: listing.isActive
                      ? AppColors.primaryMedium
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(listing.name,
                    style: AppTextStyles.h6,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: listing.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  listing.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.caption.copyWith(
                    color: listing.isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PerfStat(
                label: 'Orders',
                value: '${listing.totalOrders}',
                icon: Icons.receipt_outlined,
              ),
              _PerfStat(
                label: 'Pickups',
                value: '${listing.completedOrders}',
                icon: Icons.check_circle_outline,
              ),
              _PerfStat(
                label: 'Revenue',
                value: Formatters.formatNPR(listing.revenuePaisa),
                icon: Icons.payments_outlined,
              ),
              _PerfStat(
                label: 'Qty Left',
                value: '${listing.availableQty}',
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          if (listing.totalOrders > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: conversionRate / 100,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        conversionRate >= 70
                            ? AppColors.success
                            : conversionRate >= 40
                                ? AppColors.accentAmber
                                : AppColors.error,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$conversionRate% pickup rate',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfStat extends StatelessWidget {
  const _PerfStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
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
