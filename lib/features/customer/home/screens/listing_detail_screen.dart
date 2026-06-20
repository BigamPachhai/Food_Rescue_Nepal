import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../customer/orders/providers/customer_orders_provider.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/listings_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _quantity = 1;
  bool _isReserving = false;
  bool _descExpanded = false;
  bool _allergenExpanded = false;
  bool _howToCollectExpanded = false;
  int _imageIndex = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _reserve(ListingEntity listing) async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReserveSheet(listing: listing, quantity: _quantity),
    );
    if (result == null || result['confirmed'] != true || !mounted) return;
    final notes = result['notes'] as String?;

    HapticFeedback.heavyImpact();
    setState(() => _isReserving = true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(ApiEndpoints.orders, data: {
        'listingId': listing.id,
        'quantity': _quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      final body = response.data as Map<String, dynamic>;
      final orderId = (body['data'] ?? body)['id'] as String;
      // Refresh the orders list so "My Reservations" shows the new order immediately
      ref.invalidate(customerOrdersProvider);
      ref.invalidate(listingDetailProvider(widget.listingId));
      if (mounted) context.push('/customer/orders/$orderId');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isReserving = false);
  }

  Future<void> _toggleFavorite(String listingId) async {
    HapticFeedback.lightImpact();
    try {
      final added = await ref.read(favoritesProvider.notifier).toggle(listingId);
      if (!mounted) return;
      context.showSnackBar(
        added ? 'Added to favorites ❤️' : 'Removed from favorites',
      );
    } catch (_) {}
  }

  void _share(ListingEntity listing) {
    final vendorName = listing.vendor?.businessName ?? 'a vendor';
    final price = Formatters.formatNPR(listing.discountedPrice);
    final original = Formatters.formatNPR(listing.originalPrice);
    final text =
        '🌿 Food Rescue Nepal\n\n${listing.name} from $vendorName\n$price (was $original) — ${listing.discountPercent}% off!\n\nPickup: ${Formatters.formatPickupTime(listing.pickupStart, listing.pickupEnd)}\n${listing.availableQty} portions available\n\nDownload Food Rescue Nepal to reserve!';
    Share.share(text, subject: listing.name);
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final favorites = ref.watch(favoritesProvider).value ?? [];

    return listingAsync.when(
      data: (listing) {
        final isFav = favorites.any((f) => f.id == listing.id);
        final isUrgent =
            listing.availableQty > 0 && listing.availableQty <= 3;
        final isSoldOut = listing.availableQty == 0;
        final savings =
            (listing.originalPrice - listing.discountedPrice) * _quantity;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(listingDetailProvider(widget.listingId)),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                        child: _buildImageGallery(listing, isFav)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.s4, AppSizes.s4, AppSizes.s4, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(listing.name,
                                      style: AppTextStyles.h3),
                                ),
                                const SizedBox(width: AppSizes.s2),
                                DiscountBadge(
                                    percent: listing.discountPercent,
                                    large: true),
                              ],
                            ),
                            const SizedBox(height: AppSizes.s2),
                            Wrap(
                              spacing: AppSizes.s2,
                              runSpacing: 6,
                              children: [
                                _InfoChip(
                                  icon: Icons.category_rounded,
                                  label: listing.category
                                      .replaceAll('_', ' ')
                                      .toLowerCase()
                                      .split(' ')
                                      .map((w) => w.isEmpty
                                          ? w
                                          : '${w[0].toUpperCase()}${w.substring(1)}')
                                      .join(' '),
                                  color: AppColors.primaryMedium,
                                  bgColor: AppColors.primarySurface,
                                ),
                                if (isSoldOut)
                                  const _InfoChip(
                                    icon: Icons.block_rounded,
                                    label: 'Sold Out',
                                    color: AppColors.error,
                                    bgColor: AppColors.errorSurface,
                                  )
                                else if (isUrgent)
                                  _InfoChip(
                                    icon: Icons.local_fire_department_rounded,
                                    label:
                                        'Only ${listing.availableQty} left!',
                                    color: AppColors.accentAmber,
                                    bgColor: AppColors.warningSurface,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.s4),
                            _buildPriceRow(listing),
                            const Divider(height: AppSizes.s6),
                            _buildStatsRow(listing),
                            const Divider(height: AppSizes.s6),
                            _buildPickupSection(listing),
                            const Divider(height: AppSizes.s6),
                            _buildVendorCard(listing),
                            if (listing.description != null &&
                                listing.description!.isNotEmpty) ...[
                              const Divider(height: AppSizes.s6),
                              _buildDescription(listing),
                            ],
                            const Divider(height: AppSizes.s6),
                            _buildCarbonSection(listing),
                            if (listing.dietaryTags.isNotEmpty ||
                                listing.conditionNotes != null) ...[
                              const Divider(height: AppSizes.s6),
                              _buildDietarySection(listing),
                            ],
                            const Divider(height: AppSizes.s6),
                            _buildHowToCollect(listing),
                            const Divider(height: AppSizes.s6),
                            _buildAllergenDisclaimer(),
                            if (isSoldOut) ...[
                              const Divider(height: AppSizes.s6),
                              _buildSoldOutAlternatives(),
                            ],
                            if (!isSoldOut) ...[
                              const Divider(height: AppSizes.s6),
                              _buildQuantitySection(listing),
                              const SizedBox(height: AppSizes.s2),
                              if (savings > 0)
                                _SavingsBanner(savings: savings),
                            ],
                            const SizedBox(height: 110),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(listing, isSoldOut),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: ShimmerListingDetail()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(listingDetailProvider(widget.listingId)),
        ),
      ),
    );
  }

  Widget _buildImageGallery(ListingEntity listing, bool isFav) {
    final images = listing.imageUrls;
    final hasImages = images.isNotEmpty;

    return SizedBox(
      height: Responsive.galleryHeight(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImages && images.length > 1)
            PageView.builder(
              controller: _pageCtrl,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemBuilder: (_, i) => _NetworkImage(url: images[i]),
            )
          else if (hasImages)
            _NetworkImage(url: images.first)
          else
            Container(
              color: AppColors.primarySurface,
              child: const Center(
                child: Icon(Icons.fastfood_rounded,
                    size: 80, color: AppColors.primaryLight),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSizes.s2,
            left: AppSizes.s2,
            child: _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSizes.s2,
            right: AppSizes.s2,
            child: Row(
              children: [
                _CircleIconButton(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isFav ? Colors.red.shade400 : Colors.white,
                  onTap: () => _toggleFavorite(listing.id),
                ),
                const SizedBox(width: AppSizes.s2),
                _CircleIconButton(
                  icon: Icons.share_rounded,
                  onTap: () => _share(listing),
                ),
              ],
            ),
          ),
          if (images.length > 1 && images.length <= 6)
            Positioned(
              bottom: AppSizes.s3,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _imageIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _imageIndex ? Colors.white : Colors.white54,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: AppSizes.s3,
              right: AppSizes.s3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s2, vertical: AppSizes.s1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${_imageIndex + 1}/${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(ListingEntity listing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          Formatters.formatNPR(listing.discountedPrice),
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryMedium),
        ),
        const SizedBox(width: AppSizes.s2),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            Formatters.formatNPR(listing.originalPrice),
            style: AppTextStyles.bodyMedium.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s3, vertical: AppSizes.s1),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Text(
            'Save ${Formatters.formatNPR(listing.originalPrice - listing.discountedPrice)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accentAmber,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ListingEntity listing) {
    final qtyColor = listing.availableQty == 0
        ? AppColors.error
        : listing.availableQty <= 3
            ? AppColors.accentAmber
            : AppColors.primaryMedium;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.inventory_2_rounded,
            label: 'Available',
            value: '${listing.availableQty} left',
            valueColor: qtyColor,
          ),
        ),
        Container(width: 1, height: 44, color: AppColors.border),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            label: 'Vendor Rating',
            value: listing.vendor != null
                ? '${listing.vendor!.avgRating.toStringAsFixed(1)} / 5'
                : '—',
            valueColor: AppColors.accentAmber,
          ),
        ),
        Container(width: 1, height: 44, color: AppColors.border),
        Expanded(
          child: _StatTile(
            icon: Icons.location_on_rounded,
            label: 'Distance',
            value: listing.distance != null
                ? '${listing.distance!.toStringAsFixed(1)} km'
                : 'Nearby',
            valueColor: AppColors.primaryMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupSection(ListingEntity listing) {
    final now = DateTime.now();
    final pickupToday = listing.pickupStart.day == now.day &&
        listing.pickupStart.month == now.month &&
        listing.pickupStart.year == now.year;
    final pickupTomorrow = listing.pickupStart.day ==
        now.add(const Duration(days: 1)).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pickup Window', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s3),
        Container(
          padding: const EdgeInsets.all(AppSizes.s3),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
                color: AppColors.primaryMedium.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppColors.primaryMedium, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSizes.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatPickupTime(
                          listing.pickupStart, listing.pickupEnd),
                      style: AppTextStyles.h6,
                    ),
                    Text(
                      pickupToday
                          ? 'Today'
                          : pickupTomorrow
                              ? 'Tomorrow'
                              : Formatters.formatDate(listing.pickupStart),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pickupToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text('Today', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  if (pickupToday && listing.pickupEnd.isAfter(DateTime.now())) ...[
                    const SizedBox(height: 4),
                    _DetailCountdown(pickupEnd: listing.pickupEnd),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(ListingEntity listing) {
    final vendor = listing.vendor;
    if (vendor == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vendor', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s3),
        GestureDetector(
          onTap: () => context.push('/customer/vendor/${vendor.id}'),
          child: Container(
          padding: const EdgeInsets.all(AppSizes.s3),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primarySurface,
                    backgroundImage: vendor.logoUrl != null
                        ? CachedNetworkImageProvider(vendor.logoUrl!)
                        : null,
                    child: vendor.logoUrl == null
                        ? const Icon(Icons.store_rounded,
                            size: 22, color: AppColors.primaryLight)
                        : null,
                  ),
                  const SizedBox(width: AppSizes.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.businessName, style: AppTextStyles.h5),
                        Text(
                          vendor.businessType.replaceAll('_', ' '),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: AppSizes.iconSm,
                              color: AppColors.accentAmber),
                          const SizedBox(width: 3),
                          Text(
                            vendor.avgRating.toStringAsFixed(1),
                            style: AppTextStyles.h5,
                          ),
                        ],
                      ),
                      Text(
                        '${vendor.totalReviews} reviews',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (vendor.address != null && vendor.address!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.s3),
                const Divider(height: 1),
                const SizedBox(height: AppSizes.s3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: AppSizes.iconSm,
                        color: AppColors.primaryMedium),
                    const SizedBox(width: AppSizes.s2),
                    Expanded(
                      child: Text(vendor.address!,
                          style: AppTextStyles.bodySmall),
                    ),
                    if (listing.distance != null) ...[
                      const SizedBox(width: AppSizes.s2),
                      Text(
                        '${listing.distance!.toStringAsFixed(1)} km',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.s3),
                Row(
                  children: [
                    // Get Directions button (Issue 7)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri? uri;
                          if (vendor.lat != null && vendor.lng != null) {
                            uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${vendor.lat},${vendor.lng}');
                          } else if (vendor.address != null &&
                              vendor.address!.isNotEmpty) {
                            uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(vendor.address!)}');
                          } else {
                            uri = null;
                          }
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
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s2, vertical: AppSizes.s2),
                          textStyle: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    // Phone call button (Issue 5)
                    if (vendor.phone != null && vendor.phone!.isNotEmpty) ...[
                      const SizedBox(width: AppSizes.s2),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: vendor.phone);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s2, vertical: AppSizes.s2),
                          textStyle: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s2),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: vendor.phone!));
                          context.showSnackBar('Phone number copied');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s2, vertical: AppSizes.s2),
                          textStyle: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildDescription(ListingEntity listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this listing', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s2),
        AnimatedCrossFade(
          firstChild: Text(
            listing.description!,
            style: AppTextStyles.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild:
              Text(listing.description!, style: AppTextStyles.bodySmall),
          crossFadeState: _descExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (listing.description!.length > 120)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSizes.s1),
              child: Text(
                _descExpanded ? 'Show less ↑' : 'Read more ↓',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.primaryMedium),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCarbonSection(ListingEntity listing) {
    final savedAmount = listing.originalPrice - listing.discountedPrice;
    final co2Saved = (savedAmount / 10000 * 2.5).clamp(0.1, 99.9);
    final mealsRescued = listing.quantity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Environmental Impact', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s3),
        Container(
          padding: const EdgeInsets.all(AppSizes.s3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ImpactStat(
                  icon: Icons.cloud_off_rounded,
                  value: '~${co2Saved.toStringAsFixed(1)} kg',
                  label: 'CO₂ saved',
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.success.withValues(alpha: 0.2)),
              Expanded(
                child: _ImpactStat(
                  icon: Icons.restaurant_rounded,
                  value: '$mealsRescued',
                  label: 'meals rescued',
                  color: AppColors.primaryMedium,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.success.withValues(alpha: 0.2)),
              Expanded(
                child: _ImpactStat(
                  icon: Icons.water_drop_rounded,
                  value: '~${(mealsRescued * 1.2).toStringAsFixed(0)} L',
                  label: 'water saved',
                  color: Colors.blue.shade400,
                ),
              ),
            ],
          ),
        ),
        if (listing.expiryTime != null) ...[
          const SizedBox(height: AppSizes.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: AppSizes.s2),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentAmber),
                const SizedBox(width: AppSizes.s2),
                Text(
                  'Best before: ${Formatters.formatDateTime(listing.expiryTime!)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentAmber),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDietarySection(ListingEntity listing) {
    const tagColors = {
      'VEGAN': (Color(0xFF2E7D32), Color(0xFFE8F5E9)),
      'VEGETARIAN': (Color(0xFF388E3C), Color(0xFFF1F8E9)),
      'HALAL': (Color(0xFF1565C0), Color(0xFFE3F2FD)),
      'GLUTEN_FREE': (Color(0xFFF57F17), Color(0xFFFFF8E1)),
      'DAIRY_FREE': (Color(0xFF6A1B9A), Color(0xFFF3E5F5)),
      'NUT_FREE': (Color(0xFFBF360C), Color(0xFFFBE9E7)),
      'ORGANIC': (Color(0xFF33691E), Color(0xFFF9FBE7)),
    };
    const tagIcons = {
      'VEGAN': Icons.eco_rounded,
      'VEGETARIAN': Icons.grass_rounded,
      'HALAL': Icons.verified_rounded,
      'GLUTEN_FREE': Icons.no_meals_rounded,
      'DAIRY_FREE': Icons.no_drinks_rounded,
      'NUT_FREE': Icons.do_not_disturb_rounded,
      'ORGANIC': Icons.nature_rounded,
    };
    const tagLabels = {
      'VEGAN': 'Vegan',
      'VEGETARIAN': 'Vegetarian',
      'HALAL': 'Halal',
      'GLUTEN_FREE': 'Gluten Free',
      'DAIRY_FREE': 'Dairy Free',
      'NUT_FREE': 'Nut Free',
      'ORGANIC': 'Organic',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listing.dietaryTags.isNotEmpty) ...[
          Text('Dietary Info', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s2),
          Wrap(
            spacing: AppSizes.s2,
            runSpacing: AppSizes.s2,
            children: listing.dietaryTags.map((tag) {
              final colors = tagColors[tag] ?? (AppColors.primaryMedium, AppColors.primarySurface);
              final icon = tagIcons[tag] ?? Icons.label_rounded;
              final label = tagLabels[tag] ?? tag;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.$2,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: colors.$1.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: colors.$1),
                    const SizedBox(width: 4),
                    Text(label, style: AppTextStyles.caption.copyWith(color: colors.$1, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        if (listing.conditionNotes != null && listing.conditionNotes!.isNotEmpty) ...[
          if (listing.dietaryTags.isNotEmpty) const SizedBox(height: AppSizes.s3),
          Text('Condition Notes', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.s3),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentAmber),
                const SizedBox(width: AppSizes.s2),
                Expanded(
                  child: Text(listing.conditionNotes!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentAmber)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHowToCollect(ListingEntity listing) {
    const steps = [
      (Icons.phone_android_rounded, 'Reserve in the app', 'Tap "Reserve Now" and confirm your order.'),
      (Icons.directions_walk_rounded, 'Head to the vendor', 'Go to the pickup location within the time window.'),
      (Icons.qr_code_scanner_rounded, 'Show your QR code', 'Present the QR code from your order to the staff.'),
      (Icons.lunch_dining_rounded, 'Collect and enjoy!', 'Pick up your food and reduce waste together.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _howToCollectExpanded = !_howToCollectExpanded),
          child: Row(
            children: [
              Text('How to Collect', style: AppTextStyles.h4),
              const Spacer(),
              Icon(
                _howToCollectExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryMedium,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              const SizedBox(height: AppSizes.s3),
              ...steps.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(s.$1, size: 18, color: AppColors.primaryMedium),
                      ),
                      const SizedBox(width: AppSizes.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: AppColors.primaryMedium, shape: BoxShape.circle),
                                child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                              ),
                              const SizedBox(width: AppSizes.s2),
                              Text(s.$2, style: AppTextStyles.h6),
                            ]),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Text(s.$3, style: AppTextStyles.caption),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          crossFadeState: _howToCollectExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildSoldOutAlternatives() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 16, color: AppColors.primaryMedium),
              const SizedBox(width: AppSizes.s2),
              Text('This item is sold out', style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium)),
            ],
          ),
          const SizedBox(height: AppSizes.s2),
          Text('Check out other deals nearby — new listings are added daily!',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.s3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/customer/home'),
              icon: const Icon(Icons.fastfood_rounded, size: 16),
              label: const Text('Browse more deals'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMedium,
                side: const BorderSide(color: AppColors.primaryMedium),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenDisclaimer() {
    return GestureDetector(
      onTap: () => setState(() => _allergenExpanded = !_allergenExpanded),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s3),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.s2),
                Expanded(child: Text('Allergen Notice', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary))),
                Icon(
                  _allergenExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16, color: AppColors.textTertiary,
                ),
              ],
            ),
            if (_allergenExpanded) ...[
              const SizedBox(height: AppSizes.s2),
              Text(
                'This food is prepared in a kitchen that may handle nuts, dairy, gluten, and other allergens. If you have severe allergies, please contact the vendor directly before reserving.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection(ListingEntity listing) {
    final total = listing.discountedPrice * _quantity;

    return Column(
      children: [
        Row(
          children: [
            Text('Quantity', style: AppTextStyles.h4),
            const Spacer(),
            _QuantityStepper(
              value: _quantity,
              max: listing.availableQty,
              onChanged: (v) => setState(() => _quantity = v),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s2),
        Row(
          children: [
            Text('Total:', style: AppTextStyles.bodyMedium),
            const SizedBox(width: AppSizes.s2),
            Text(
              Formatters.formatNPR(total),
              style:
                  AppTextStyles.h4.copyWith(color: AppColors.primaryMedium),
            ),
            const SizedBox(width: AppSizes.s2),
            Text(
              Formatters.formatNPR(listing.originalPrice * _quantity),
              style: AppTextStyles.caption
                  .copyWith(decoration: TextDecoration.lineThrough),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(ListingEntity listing, bool isSoldOut) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppShadows.bottomBar,
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.s4,
          AppSizes.s3,
          AppSizes.s4,
          MediaQuery.of(context).padding.bottom + AppSizes.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSoldOut)
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.block_rounded),
              label: const Text('Sold Out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
              ),
            )
          else
            Column(
              children: [
                // Savings highlight bar
                if (listing.discountedPrice < listing.originalPrice)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
                    margin: const EdgeInsets.only(bottom: AppSizes.s2),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.savings_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'You save ${Formatters.formatNPR((listing.originalPrice - listing.discountedPrice) * _quantity)} on this order!',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                AppButton(
                  label: 'Reserve Now — ${Formatters.formatNPR(listing.discountedPrice * _quantity)}',
                  onPressed: !_isReserving ? () => _reserve(listing) : null,
                  isLoading: _isReserving,
                ),
              ],
            ),
          const SizedBox(height: AppSizes.s2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: AppSizes.iconXs, color: AppColors.textSecondary),
              SizedBox(width: AppSizes.s1),
              Text('Cash on Pickup', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              SizedBox(width: AppSizes.s4),
              Icon(Icons.verified_outlined, size: AppSizes.iconXs, color: AppColors.textSecondary),
              SizedBox(width: AppSizes.s1),
              Text('Cancel before pickup', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────

class _SavingsBanner extends StatelessWidget {
  const _SavingsBanner({required this.savings});
  final int savings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s3, vertical: AppSizes.s2),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded,
              color: AppColors.success, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Text(
              'You save ${Formatters.formatNPR(savings)} and help reduce food waste!',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 800,
      memCacheHeight: 600,
      placeholder: (_, __) => Container(color: AppColors.primarySurface),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.primarySurface,
        child: const Center(
          child: Icon(Icons.fastfood_rounded,
              size: 64, color: AppColors.primaryLight),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s2, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXs, color: color),
          const SizedBox(width: AppSizes.s1),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: valueColor, size: AppSizes.iconLg),
        const SizedBox(height: AppSizes.s1),
        Text(
          value,
          style: AppTextStyles.h6.copyWith(color: valueColor),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper(
      {required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          enabled: value > 1,
          onTap: () => onChanged(value - 1),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.s4),
          child: Text('$value', style: AppTextStyles.h4),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconMd,
          color:
              enabled ? AppColors.primaryMedium : AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ─── Reserve confirmation sheet ─────────────────────────────────────────────

class _ReserveSheet extends StatefulWidget {
  const _ReserveSheet({required this.listing, required this.quantity});
  final ListingEntity listing;
  final int quantity;

  @override
  State<_ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<_ReserveSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.listing.discountedPrice * widget.quantity;
    final savings =
        (widget.listing.originalPrice - widget.listing.discountedPrice) * widget.quantity;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusBottomSheet)),
        ),
        padding: EdgeInsets.fromLTRB(
            AppSizes.s5,
            AppSizes.s4,
            AppSizes.s5,
            MediaQuery.of(context).padding.bottom + AppSizes.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            Text('Confirm Reservation', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.s4),
            _SheetRow(icon: Icons.fastfood_rounded, text: widget.listing.name),
            const SizedBox(height: AppSizes.s2),
            if (widget.listing.vendor != null)
              _SheetRow(
                  icon: Icons.store_rounded,
                  text: widget.listing.vendor!.businessName),
            const SizedBox(height: AppSizes.s2),
            _SheetRow(
              icon: Icons.shopping_bag_rounded,
              text: '${widget.quantity} portion${widget.quantity > 1 ? 's' : ''}',
            ),
            const SizedBox(height: AppSizes.s2),
            _SheetRow(
              icon: Icons.schedule_rounded,
              text: Formatters.formatPickupTime(
                  widget.listing.pickupStart, widget.listing.pickupEnd),
            ),
            const SizedBox(height: AppSizes.s3),
            const Divider(),
            const SizedBox(height: AppSizes.s3),
            // Order notes field
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Any special requests? (optional)',
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.note_outlined, size: 18, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: AppSizes.s2),
                counterStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: AppSizes.s3),
            Row(
              children: [
                const Icon(Icons.payments_rounded,
                    color: AppColors.primaryMedium, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatNPR(total),
                      style: AppTextStyles.h4.copyWith(color: AppColors.primaryMedium),
                    ),
                    if (savings > 0)
                      Text(
                        'You save ${Formatters.formatNPR(savings)}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.success),
                      ),
                  ],
                ),
                const Spacer(),
                Text('Cash on Pickup', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSizes.s3),
            Container(
              padding: const EdgeInsets.all(AppSizes.s3),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: AppSizes.s2),
                  Expanded(
                    child: Text(
                      'You\'re rescuing ${widget.quantity} meal${widget.quantity > 1 ? 's' : ''} from going to waste!',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'confirmed': true,
                      'notes': _notesCtrl.text.trim(),
                    }),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                    ),
                    child: const Text(
                      'Confirm & Reserve',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconMd, color: AppColors.primaryMedium),
        const SizedBox(width: AppSizes.s2),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h6.copyWith(color: color), textAlign: TextAlign.center),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── Detail page countdown timer ───────────────────────────────────────────

class _DetailCountdown extends StatefulWidget {
  const _DetailCountdown({required this.pickupEnd});
  final DateTime pickupEnd;

  @override
  State<_DetailCountdown> createState() => _DetailCountdownState();
}

class _DetailCountdownState extends State<_DetailCountdown> {
  late Duration _remaining;
  Timer? _timer;

  Duration _calc() {
    final d = widget.pickupEnd.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calc());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) return const SizedBox.shrink();
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final isUrgent = _remaining.inMinutes <= 30;
    final label = h > 0 ? '${h}h ${m}m remaining' : '${m}m ${s}s remaining';
    final color = isUrgent ? AppColors.error : AppColors.accentAmber;
    final bg = isUrgent ? AppColors.errorSurface : AppColors.warningSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
