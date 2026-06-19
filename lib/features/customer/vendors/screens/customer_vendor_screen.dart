import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final data = raw.containsKey('data')
      ? raw['data'] as Map<String, dynamic>
      : raw;
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
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async {
          ref.invalidate(vendorDetailProvider(widget.vendorId));
          ref.invalidate(vendorPublicListingsProvider(widget.vendorId));
        },
        child: CustomScrollView(
          slivers: [
            // ── Vendor header ──────────────────────────────────────────
            vendorAsync.when(
              data: (vendor) => SliverToBoxAdapter(
                child: _VendorHeader(
                  vendor: vendor,
                  isFav: isFav,
                  onFavToggle: () async {
                    if (_isToggling.value) return;
                    _isToggling.value = true;
                    HapticFeedback.lightImpact();
                    final added = await ref
                        .read(vendorFavoritesProvider.notifier)
                        .toggle(widget.vendorId);
                    _isToggling.value = false;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(added
                            ? 'Vendor added to favorites'
                            : 'Vendor removed from favorites'),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  onReviews: () => context
                      .push('/customer/vendor/${widget.vendorId}/reviews'),
                ),
              ),
              loading: () =>
                  const SliverToBoxAdapter(child: _VendorHeaderShimmer()),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(vendorDetailProvider(widget.vendorId)),
                ),
              ),
            ),

            // ── Listings header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s2),
                child: Text('Active Listings', style: AppTextStyles.h4),
              ),
            ),

            // ── Listings ───────────────────────────────────────────────
            listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateView(
                      icon: Icons.fastfood_outlined,
                      title: 'No listings right now',
                      subtitle:
                          'This vendor has no active listings at the moment. Check back later!',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ListingCard(
                      listing: listings[i],
                      onTap: () =>
                          context.push('/customer/listing/${listings[i].id}'),
                    ),
                    childCount: listings.length,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.s4, vertical: AppSizes.s1),
                    child: ShimmerCard(height: 108),
                  ),
                  childCount: 3,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(
                      vendorPublicListingsProvider(widget.vendorId)),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Vendor Header ──────────────────────────────────────────────────────────

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({
    required this.vendor,
    required this.isFav,
    required this.onFavToggle,
    required this.onReviews,
  });

  final VendorEntity vendor;
  final bool isFav;
  final VoidCallback onFavToggle;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Green gradient hero ──────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryMedium],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Back + Actions row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.s2, AppSizes.s2, AppSizes.s2, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        tooltip: 'Share vendor',
                        onPressed: () {
                          final msg =
                              'Check out ${vendor.businessName} on Food Rescue Nepal! '
                              'Great deals on surplus food near you.';
                          Share.share(msg);
                        },
                      ),
                      IconButton(
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
                        onPressed: onFavToggle,
                      ),
                    ],
                  ),
                ),
                // Logo + name
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.s4, AppSizes.s2, AppSizes.s4, AppSizes.s5),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                          border:
                              Border.all(color: Colors.white30, width: 2),
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
                                  style: AppTextStyles.h6
                                      .copyWith(color: Colors.white),
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
              ],
            ),
          ),
        ),

        // ── Info card ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(AppSizes.s4),
          padding: const EdgeInsets.all(AppSizes.s4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              // Address row
              if (vendor.address != null && vendor.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: AppSizes.iconMd,
                        color: AppColors.primaryMedium),
                    const SizedBox(width: AppSizes.s2),
                    Expanded(
                      child: Text(vendor.address!,
                          style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s3),
              ],

              // Action buttons
              Row(
                children: [
                  // Directions
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = (vendor.lat != null && vendor.lng != null)
                            ? Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${vendor.lat},${vendor.lng}')
                            : vendor.address != null
                                ? Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vendor.address!)}')
                                : null;
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryMedium,
                        side: const BorderSide(color: AppColors.primaryMedium),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm)),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.s2),
                        textStyle: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Phone
                  if (vendor.phone != null &&
                      vendor.phone!.isNotEmpty) ...[
                    const SizedBox(width: AppSizes.s2),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: vendor.phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm)),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.s2),
                        textStyle: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  // Reviews
                  const SizedBox(width: AppSizes.s2),
                  OutlinedButton.icon(
                    onPressed: onReviews,
                    icon: const Icon(Icons.star_rounded, size: 16),
                    label: const Text('Reviews'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentAmber,
                      side:
                          const BorderSide(color: AppColors.accentAmber),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.s2),
                      textStyle: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
      height: 240,
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
