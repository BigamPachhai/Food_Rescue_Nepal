import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
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

    final vendorStatus = vendorProfileAsync.value?.status;
    final isPendingVendor = vendorStatus == 'PENDING';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async {
          ref.invalidate(vendorStatsProvider);
          ref.invalidate(vendorOrdersProvider);
          ref.invalidate(vendorListingsProvider);
          ref.invalidate(vendorProfileProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, authState)),
            if (isPendingVendor) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: _VendorPendingState(
                  onRefresh: () => ref.invalidate(vendorProfileProvider),
                ),
              ),
            ] else ...[
              if (vendorStatus == 'SUSPENDED')
                SliverToBoxAdapter(child: _buildSuspendedBanner()),
              SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _StatsPanel(stats: stats),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s4, vertical: AppSizes.s3),
                  child: ShimmerCard(height: 180),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSizes.s4),
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(vendorStatsProvider),
                  ),
                ),
              ),
            ),
            // Reviews quick-link
            SliverToBoxAdapter(
              child: vendorProfileAsync.whenOrNull(
                    data: (vendor) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.s4, AppSizes.s2, AppSizes.s4, 0),
                      child: _QuickLinkCard(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.accentAmber,
                        title: 'Customer Reviews',
                        subtitle: 'See what customers are saying',
                        onTap: () =>
                            context.push('/vendor/reviews/${vendor.id}'),
                      ),
                    ),
                  ) ??
                  const SizedBox.shrink(),
            ),
            // Pending orders header
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Pending Orders',
                onSeeAll: () => context.go('/vendor/orders'),
              ),
            ),
            ordersAsync.when(
              data: (orders) {
                final pending =
                    orders.where((o) => o.status == 'PENDING').take(3).toList();
                if (pending.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.s4, vertical: AppSizes.s1),
                      child: _AllClearBanner(
                          message: 'No pending orders — all caught up!'),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.s4),
                  child: ShimmerCard(height: 76),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
                  child: _InlineError(
                    message: 'Could not load orders',
                    onRetry: () =>
                        ref.read(vendorOrdersProvider.notifier).fetch(),
                  ),
                ),
              ),
            ),
            // Active listings header
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Active Listings',
                onSeeAll: () => context.go('/vendor/listings'),
                topPadding: AppSizes.s4,
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
                          horizontal: AppSizes.s4, vertical: AppSizes.s2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No active listings yet',
                              style: AppTextStyles.bodySmall),
                          const SizedBox(height: AppSizes.s3),
                          SizedBox(
                            width: double.infinity,
                            height: AppSizes.buttonHeightSm,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/vendor/listings/add'),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add your first listing'),
                            ),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.s4),
                  child: ShimmerCard(height: 68),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4),
                  child: _InlineError(
                    message: 'Could not load listings',
                    onRetry: () =>
                        ref.read(vendorListingsProvider.notifier).fetch(),
                  ),
                ),
              ),
            ),
            // Performance section
            SliverToBoxAdapter(
              child: statsAsync.whenOrNull(
                    data: (stats) => stats.listingPerformance.isEmpty
                        ? const SizedBox.shrink()
                        : _ListingPerformanceSection(
                            listings: stats.listingPerformance,
                          ),
                  ) ??
                  const SizedBox.shrink(),
            ),
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 88),
              ),
            ], // end else
          ],
        ),
      ),
      floatingActionButton: isPendingVendor
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/vendor/listings/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Listing',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthState authState) {
    final name =
        authState is AuthAuthenticated ? authState.user.name : 'Vendor';
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.s3,
        left: AppSizes.s4,
        right: AppSizes.s4,
        bottom: AppSizes.s5,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child:
                const Icon(Icons.store_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                Text(
                  name,
                  style: AppTextStyles.h4OnPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspendedBanner() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded,
              color: AppColors.error, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Suspended',
                    style: AppTextStyles.h6.copyWith(color: AppColors.error)),
                const SizedBox(height: 2),
                Text(
                    'Your account has been suspended. Please contact support.',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vendor pending state ─────────────────────────────────────────────────

class _VendorPendingState extends StatelessWidget {
  const _VendorPendingState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.s4),
          // Hero status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.s5),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      size: 36, color: AppColors.warning),
                ),
                const SizedBox(height: AppSizes.s3),
                Text('Application Under Review',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.warning),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.s2),
                Text(
                  'Our team is verifying your business details. This usually takes 1–2 business days.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s5),
          Text('What happens next?', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          const _PendingStep(
            step: 1,
            title: 'Application submitted',
            subtitle: 'Your details are in our system',
            isDone: true,
          ),
          const _PendingStep(
            step: 2,
            title: 'Business verification',
            subtitle: 'We verify your business information',
            isDone: false,
            isCurrent: true,
          ),
          const _PendingStep(
            step: 3,
            title: 'Account activation',
            subtitle: 'Your listings go live to customers',
            isDone: false,
          ),
          const SizedBox(height: AppSizes.s5),
          Text('While you wait', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          const _TipCard(
            icon: Icons.photo_camera_rounded,
            text: 'Prepare high-quality photos of your food — listings with photos get 3× more clicks.',
          ),
          const SizedBox(height: AppSizes.s2),
          const _TipCard(
            icon: Icons.schedule_rounded,
            text: 'Plan your pickup windows. Customers prefer specific 30–60 minute slots.',
          ),
          const SizedBox(height: AppSizes.s5),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check approval status'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.s3),
                foregroundColor: AppColors.primaryMedium,
                side: const BorderSide(color: AppColors.primaryMedium),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusButton)),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s2),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Need help? Contact support',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingStep extends StatelessWidget {
  const _PendingStep({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isCurrent = false,
  });
  final int step;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.success
        : isCurrent
            ? AppColors.warning
            : AppColors.neutral300;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.success
                  : isCurrent
                      ? AppColors.warning
                      : AppColors.neutral100,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : AppColors.neutral400,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCurrent || isDone
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryMedium),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    this.topPadding = AppSizes.s3,
  });
  final String title;
  final VoidCallback onSeeAll;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSizes.s4, topPadding, AppSizes.s4, AppSizes.s2),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h4),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Panel ──────────────────────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});
  final VendorStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Snapshot", style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Orders',
                  value: '${stats.todayOrders}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.infoSurface,
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: _StatCard(
                  label: 'Earned',
                  value: Formatters.formatNPR(stats.todayEarnedPaisa),
                  icon: Icons.payments_rounded,
                  color: AppColors.primaryMedium,
                  bgColor: AppColors.primarySurface,
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: _StatCard(
                  label: 'Saved',
                  value: '${stats.foodSavedKg.toStringAsFixed(1)} kg',
                  icon: Icons.eco_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),
          Text('All-Time Impact', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Reservations',
                  value: '${stats.totalReservations}',
                  icon: Icons.bookmark_rounded,
                  color: AppColors.accentAmber,
                  bgColor: AppColors.warningSurface,
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: _StatCard(
                  label: 'Pickups',
                  value: '${stats.completedPickups}',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successSurface,
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: _StatCard(
                  label: 'Food Saved',
                  value:
                      '${stats.totalFoodSavedKg.toStringAsFixed(1)} kg',
                  icon: Icons.eco_rounded,
                  color: AppColors.primaryMedium,
                  bgColor: AppColors.primarySurface,
                ),
              ),
            ],
          ),
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
    required this.bgColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconSm),
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            value,
            style: AppTextStyles.h5.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Link Card ──────────────────────────────────────────────────────

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s4, vertical: AppSizes.s3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: AppShadows.xs,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h6),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
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

// ─── All-Clear Banner ─────────────────────────────────────────────────────

class _AllClearBanner extends StatelessWidget {
  const _AllClearBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s3, vertical: AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.s2),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending Order Card ───────────────────────────────────────────────────

class _PendingOrderCard extends ConsumerWidget {
  const _PendingOrderCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4, vertical: AppSizes.s1),
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
            color: AppColors.statusPending.withValues(alpha: 0.25)),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.statusPendingSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: AppColors.statusPending,
              size: AppSizes.iconMd,
            ),
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
                Text(
                  'x${order.quantity} · ${Formatters.formatNPR(order.totalAmount)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s2),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => context.push('/vendor/orders/${order.id}'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTextStyles.buttonSm,
              ),
              child: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Listing Tile ──────────────────────────────────────────────────

class _ActiveListingTile extends StatelessWidget {
  const _ActiveListingTile({required this.listing});
  final VendorListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4, vertical: AppSizes.s1),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppShadows.xs,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: const Icon(
            Icons.fastfood_rounded,
            color: AppColors.primaryLight,
            size: AppSizes.iconMd,
          ),
        ),
        title: Text(listing.name, style: AppTextStyles.h6),
        subtitle: Text(
          '${listing.availableQty} left · ${Formatters.formatNPR(listing.discountedPrice)}',
          style: AppTextStyles.caption,
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.neutral400,
        ),
        onTap: () => context.push('/vendor/listings/${listing.id}/edit'),
      ),
    );
  }
}

// ─── Listing Performance Section ──────────────────────────────────────────

class _ListingPerformanceSection extends StatelessWidget {
  const _ListingPerformanceSection({required this.listings});
  final List<ListingPerf> listings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s4, AppSizes.s4, AppSizes.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing Performance', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
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
    final convColor = conversionRate >= 70
        ? AppColors.success
        : conversionRate >= 40
            ? AppColors.accentAmber
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s2),
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppShadows.xs,
        border: Border.all(color: AppColors.border),
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
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  Icons.fastfood_rounded,
                  size: AppSizes.iconSm,
                  color: listing.isActive
                      ? AppColors.primaryMedium
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: Text(
                  listing.name,
                  style: AppTextStyles.h6,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s2, vertical: 3),
                decoration: BoxDecoration(
                  color: listing.isActive
                      ? AppColors.successSurface
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
          const SizedBox(height: AppSizes.s3),
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
            const SizedBox(height: AppSizes.s3),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: conversionRate / 100,
                      backgroundColor: AppColors.neutral100,
                      valueColor: AlwaysStoppedAnimation<Color>(convColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.s2),
                Text(
                  '$conversionRate% pickup rate',
                  style: AppTextStyles.caption.copyWith(
                    color: convColor,
                    fontWeight: FontWeight.w600,
                  ),
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
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(
            value,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ─── Inline error banner ───────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s2, AppSizes.s1, AppSizes.s2),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.s2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
