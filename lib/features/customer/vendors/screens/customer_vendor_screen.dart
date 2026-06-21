import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../customer/favorites/providers/favorites_provider.dart';
import '../../../customer/home/providers/listings_provider.dart';
import '../../../customer/home/screens/customer_home_screen.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final vendorDetailProvider =
    FutureProvider.family<VendorEntity, String>((ref, id) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.vendorPublicById(id));
  final raw = response.data as Map<String, dynamic>;
  Map<String, dynamic> data;
  if (raw['data'] is Map<String, dynamic>) {
    data = raw['data'] as Map<String, dynamic>;
  } else {
    data = raw;
  }
  return VendorEntity.fromJson(data);
});

final vendorPublicListingsProvider =
    FutureProvider.family<List<ListingEntity>, String>((ref, vendorId) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(
    ApiEndpoints.listings,
    queryParameters: {'vendorId': vendorId, 'limit': 50, 'page': 1},
  );
  final body = response.data as Map<String, dynamic>;
  final data = body['data'];
  List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map<String, dynamic> && data['listings'] is List) {
    items = data['listings'] as List<dynamic>;
  } else {
    items = [];
  }
  return items
      .map((e) => ListingEntity.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────

class CustomerVendorScreen extends ConsumerStatefulWidget {
  const CustomerVendorScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  ConsumerState<CustomerVendorScreen> createState() =>
      _CustomerVendorScreenState();
}

class _CustomerVendorScreenState extends ConsumerState<CustomerVendorScreen> {
  final _isToggling = ValueNotifier(false);

  @override
  void dispose() {
    _isToggling.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(VendorEntity? vendor) async {
    if (_isToggling.value) return;
    _isToggling.value = true;
    HapticFeedback.lightImpact();
    final added = await ref
        .read(vendorFavoritesProvider.notifier)
        .toggle(widget.vendorId, vendor: vendor);
    _isToggling.value = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added
            ? 'Vendor added to favorites'
            : 'Vendor removed from favorites'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));
    final listingsAsync =
        ref.watch(vendorPublicListingsProvider(widget.vendorId));
    final vendorFavs = ref.watch(vendorFavoritesProvider);
    final isFav =
        vendorFavs.value?.any((v) => v.id == widget.vendorId) ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () async {
              ref.invalidate(vendorDetailProvider(widget.vendorId));
              ref.invalidate(vendorPublicListingsProvider(widget.vendorId));
            },
            child: CustomScrollView(
              slivers: [
                // Reserve space so content starts below the floating bar
                const SliverToBoxAdapter(child: _AppBarSpacer()),

                if (vendorAsync.isLoading)
                  const SliverToBoxAdapter(child: _VendorHeaderShimmer())
                else if (vendorAsync.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      error: vendorAsync.error,
                      onRetry: () =>
                          ref.invalidate(vendorDetailProvider(widget.vendorId)),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _VendorHeader(
                      vendor: vendorAsync.value!,
                      onReviews: () => context
                          .push('/customer/vendor/${widget.vendorId}/reviews'),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s2),
                      child: Text('Active Listings', style: AppTextStyles.h4),
                    ),
                  ),

                  if (listingsAsync.isLoading)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.s4, vertical: AppSizes.s1),
                          child: ShimmerCard(height: 108),
                        ),
                        childCount: 3,
                      ),
                    )
                  else if (listingsAsync.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(
                        error: listingsAsync.error,
                        onRetry: () => ref.invalidate(
                            vendorPublicListingsProvider(widget.vendorId)),
                      ),
                    )
                  else if (listingsAsync.value?.isEmpty ?? true)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: EmptyStateView(
                          icon: Icons.fastfood_outlined,
                          title: 'No listings right now',
                          subtitle:
                              'This vendor has no active listings at the moment. Check back later!',
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ListingCard(
                          listing: listingsAsync.value![i],
                          onTap: () => context.push(
                              '/customer/listing/${listingsAsync.value![i].id}'),
                        ),
                        childCount: listingsAsync.value!.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            ),
          ),

          // ── Floating action bar — always on top, outside scroll arena ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white),
                      tooltip: 'Share vendor',
                      onPressed: () {
                        final name =
                            vendorAsync.value?.businessName ?? 'this vendor';
                        Share.share(
                          'Check out $name on Food Rescue Nepal! '
                          'Great deals on surplus food near you.',
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isToggling,
                      builder: (_, toggling, __) => IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(isFav),
                            color: isFav ? Colors.red.shade300 : Colors.white,
                          ),
                        ),
                        tooltip: isFav
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        onPressed: toggling
                            ? null
                            : () => _toggleFavorite(vendorAsync.value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reserves space equal to the floating action bar so scroll content
// starts below it rather than hidden underneath.
class _AppBarSpacer extends StatelessWidget {
  const _AppBarSpacer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.of(context).padding.top + 48);
  }
}

// ── Vendor Header ──────────────────────────────────────────────────────────

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({
    required this.vendor,
    required this.onReviews,
  });

  final VendorEntity vendor;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Vendor identity section ──────────────────────────────────────
        Container(
          width: double.infinity,
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s5),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primarySurface,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: ClipOval(
                    child: vendor.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: vendor.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.store_rounded,
                                color: AppColors.primaryLight,
                                size: 36),
                          )
                        : const Icon(Icons.store_rounded,
                            color: AppColors.primaryLight, size: 36),
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vendor.businessName,
                              style: AppTextStyles.h3OnPrimary,
                              maxLines: 2,
                            ),
                          ),
                          if (vendor.status == 'APPROVED') ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor.businessType.replaceAll('_', ' '),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.accentAmber),
                          const SizedBox(width: 3),
                          Text(
                            vendor.avgRating.toStringAsFixed(1),
                            style:
                                AppTextStyles.h6.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${vendor.totalReviews} reviews)',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Location chip ────────────────────────────────────────────────
        if (vendor.address != null && vendor.address!.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s3, vertical: AppSizes.s2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppColors.primaryMedium),
                const SizedBox(width: AppSizes.s2),
                Expanded(
                  child: Text(vendor.address!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

      ],
    );
  }
}

// ── Shimmer for header ─────────────────────────────────────────────────────

class _VendorHeaderShimmer extends StatelessWidget {
  const _VendorHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
