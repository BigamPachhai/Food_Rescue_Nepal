import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
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
import '../../../notifications/providers/notifications_provider.dart';

final vendorIsOpenProvider = StateProvider<bool?>((ref) => null);

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
    final unreadCount = ref.watch(unreadCountProvider);

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
            SliverToBoxAdapter(child: _buildHeader(context, authState, unreadCount)),
            const SliverToBoxAdapter(child: _IsOpenToggle()),
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
              // Urgent orders alert
              SliverToBoxAdapter(
                child: ordersAsync.whenOrNull(
                  data: (orders) {
                    final urgent = orders.where((o) =>
                        o.status == 'PENDING' &&
                        o.listing?.pickupEnd != null &&
                        o.listing!.pickupEnd.difference(DateTime.now()).inMinutes <= 30 &&
                        o.listing!.pickupEnd.isAfter(DateTime.now())).length;
                    if (urgent == 0) return null;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
                      padding: const EdgeInsets.all(AppSizes.s3),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSizes.s2),
                          Expanded(
                            child: Text(
                              '$urgent order${urgent > 1 ? 's' : ''} closing in <30 min — act now!',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/vendor/orders'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2)),
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  },
                ) ?? const SizedBox.shrink(),
              ),
              // Low inventory alert
              SliverToBoxAdapter(
                child: listingsAsync.whenOrNull(
                  data: (listings) {
                    final lowStock = listings.where((l) => l.isActive && l.availableQty > 0 && l.availableQty <= 2).toList();
                    if (lowStock.isEmpty) return null;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
                      padding: const EdgeInsets.all(AppSizes.s3),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded, color: AppColors.accentAmber, size: 20),
                          const SizedBox(width: AppSizes.s2),
                          Expanded(
                            child: Text(
                              '${lowStock.length} listing${lowStock.length > 1 ? 's' : ''} almost sold out (≤2 left)',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentAmber, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/vendor/listings'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.accentAmber, padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2)),
                            child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  },
                ) ?? const SizedBox.shrink(),
              ),
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
            // Food impact card
            SliverToBoxAdapter(
              child: statsAsync.whenOrNull(
                data: (stats) => stats.completedPickups > 0
                    ? _FoodImpactCard(stats: stats)
                    : null,
              ) ?? const SizedBox.shrink(),
            ),
            // Best-selling listing
            SliverToBoxAdapter(
              child: listingsAsync.whenOrNull(
                data: (listings) {
                  if (listings.isEmpty) return null;
                  final sorted = [...listings]..sort((a, b) => b.soldCount.compareTo(a.soldCount));
                  final best = sorted.first;
                  if (best.soldCount == 0) return null;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s2, AppSizes.s4, 0),
                    child: _QuickLinkCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.success,
                      title: 'Best Seller: ${best.name}',
                      subtitle: '${best.soldCount} sold · ${best.discountPercent}% off',
                      onTap: () => context.push('/vendor/listings/${best.id}/edit'),
                    ),
                  );
                },
              ) ?? const SizedBox.shrink(),
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
            // Tip of the Week
            const SliverToBoxAdapter(child: _TipOfTheWeek()),
            // Store Tools section
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Store Tools', onSeeAll: () => context.push('/vendor/analytics')),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.s4, 0, AppSizes.s4, AppSizes.s2),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: [
                    _ToolCard(icon: Icons.bar_chart_rounded, label: 'Analytics', color: Colors.blue, onTap: () => context.push('/vendor/analytics')),
                    _ToolCard(icon: Icons.inventory_2_rounded, label: 'Inventory', color: Colors.orange, onTap: () => context.push('/vendor/inventory')),
                    _ToolCard(icon: Icons.local_offer_rounded, label: 'Promotions', color: Colors.purple, onTap: () => context.push('/vendor/promotions')),
                    _ToolCard(icon: Icons.schedule_rounded, label: 'Hours', color: Colors.teal, onTap: () => context.push('/vendor/hours')),
                    _ToolCard(icon: Icons.photo_library_rounded, label: 'Gallery', color: Colors.green, onTap: () => context.push('/vendor/gallery')),
                    _ToolCard(icon: Icons.stars_rounded, label: 'Loyalty', color: Colors.amber, onTap: () => context.push('/vendor/loyalty')),
                    _ToolCard(icon: Icons.people_rounded, label: 'Customers', color: Colors.indigo, onTap: () => context.push('/vendor/customers')),
                    _ToolCard(icon: Icons.help_outline_rounded, label: 'FAQ', color: Colors.grey, onTap: () => context.push('/vendor/faq')),
                    _ToolCard(icon: Icons.verified_rounded, label: 'Verification', color: Colors.cyan.shade700, onTap: () => context.push('/vendor/verification')),
                  ],
                ),
              ),
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

  Widget _buildHeader(BuildContext context, AuthState authState, int unreadCount) {
    final name =
        authState is AuthAuthenticated ? authState.user.name : 'Vendor';
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                Text(name, style: AppTextStyles.h4OnPrimary, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s2),
          // Quick add listing button
          GestureDetector(
            onTap: () => context.push('/vendor/listings/add'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('List Food', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s1),
          // Notification bell with unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@foodrescuenepal.com',
                  query: 'subject=Vendor Support Request',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
      margin: const EdgeInsets.only(bottom: AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s3, AppSizes.s3, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: listing.isActive ? AppColors.primarySurface : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    Icons.fastfood_rounded,
                    size: AppSizes.iconSm,
                    color: listing.isActive ? AppColors.primaryMedium : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.name,
                        style: AppTextStyles.h6,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: listing.isActive ? AppColors.success : AppColors.neutral300,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            listing.isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.caption.copyWith(
                              color: listing.isActive ? AppColors.success : AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s3),
          const Divider(height: 1),
          // Stats grid — 2 per row for breathing room
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s3, AppSizes.s3, 0),
            child: Row(
              children: [
                _PerfStat(
                  label: 'Orders',
                  value: '${listing.totalOrders}',
                  icon: Icons.receipt_outlined,
                ),
                _PerfStat(
                  label: 'Completed',
                  value: '${listing.completedOrders}',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s2, AppSizes.s3, AppSizes.s3),
            child: Row(
              children: [
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
          ),
          // Pickup rate bar — only when there are orders
          if (listing.totalOrders > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pickup rate', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      Text(
                        '$conversionRate%',
                        style: AppTextStyles.label.copyWith(color: convColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: conversionRate / 100,
                      backgroundColor: AppColors.neutral100,
                      valueColor: AlwaysStoppedAnimation<Color>(convColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 0),
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
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
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

// ─── Food Impact Card ────────────────────────────────────────────────────────

class _FoodImpactCard extends StatelessWidget {
  const _FoodImpactCard({required this.stats});
  final VendorStats stats;

  @override
  Widget build(BuildContext context) {
    final co2Saved = (stats.completedPickups * 2.5);
    final revenue = Formatters.formatNPR(stats.totalRevenuePaisa);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('Your Food Rescue Impact', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: AppSizes.s3),
          Row(
            children: [
              _DashImpactStat(value: '${stats.completedPickups}', label: 'Meals\nRescued', icon: Icons.restaurant_rounded),
              _DashImpactStat(value: '~${co2Saved.toStringAsFixed(1)} kg', label: 'CO₂\nAvoided', icon: Icons.cloud_off_rounded),
              _DashImpactStat(value: revenue, label: 'Total\nRevenue', icon: Icons.payments_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashImpactStat extends StatelessWidget {
  const _DashImpactStat({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h6.copyWith(color: Colors.white), textAlign: TextAlign.center),
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60, height: 1.3, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Tip of the Week ─────────────────────────────────────────────────────

class _TipOfTheWeek extends StatelessWidget {
  const _TipOfTheWeek();

  static const _tips = [
    (
      icon: Icons.access_time_rounded,
      color: Color(0xFF7C3AED),
      title: 'List early, sell more',
      body: 'Posting surplus food 2–3 hours before closing gives customers time to plan pickup.',
    ),
    (
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFDB2777),
      title: 'A photo is worth 10 sales',
      body: 'Listings with clear photos get up to 3× more reservations. Keep your gallery fresh.',
    ),
    (
      icon: Icons.local_offer_rounded,
      color: Color(0xFFD97706),
      title: 'Sweet-spot discounts',
      body: 'A 30–40% discount attracts the most buyers without cutting too deep into margin.',
    ),
    (
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF0284C7),
      title: 'Confirm orders fast',
      body: 'Accepting orders within 15 minutes builds trust and reduces cancellations.',
    ),
    (
      icon: Icons.star_rounded,
      color: Color(0xFFF59E0B),
      title: 'Reviews drive repeat visits',
      body: 'Ask happy customers to leave a review — even one 5-star rating boosts visibility.',
    ),
    (
      icon: Icons.eco_rounded,
      color: Color(0xFF16A34A),
      title: 'Share your impact',
      body: 'Every meal rescued saves ~2.5 kg of CO₂. Share your milestone on social to attract eco-conscious buyers.',
    ),
    (
      icon: Icons.schedule_rounded,
      color: Color(0xFF0891B2),
      title: 'Consistent hours win customers',
      body: 'Keeping your pickup window consistent each day builds customer habits and loyalty.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().weekday % _tips.length];
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(tip.icon, color: tip.color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tip of the week',
                      style: AppTextStyles.caption.copyWith(
                        color: tip.color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(tip.title, style: AppTextStyles.h6),
                const SizedBox(height: 4),
                Text(tip.body, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tool Card ────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ─── isOpen Toggle ────────────────────────────────────────────────────────────

class _IsOpenToggle extends ConsumerStatefulWidget {
  const _IsOpenToggle();

  @override
  ConsumerState<_IsOpenToggle> createState() => _IsOpenToggleState();
}

class _IsOpenToggleState extends ConsumerState<_IsOpenToggle> {
  bool _loading = false;

  Future<void> _toggle(bool current) async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.patch(ApiEndpoints.vendorToggleOpen);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
      ref.read(vendorIsOpenProvider.notifier).state = data['isOpen'] as bool? ?? !current;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(vendorIsOpenProvider) ?? true;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: isOpen ? AppColors.success : AppColors.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOpen ? 'Shop is Open' : 'Shop is Closed',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(isOpen ? 'Customers can see your listings' : 'Listings are hidden from customers',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(value: isOpen, onChanged: (_) => _toggle(isOpen)),
        ],
      ),
    );
  }
}
