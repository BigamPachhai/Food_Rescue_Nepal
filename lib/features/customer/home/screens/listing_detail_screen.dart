import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/listings_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _quantity = 1;
  bool _isReserving = false;
  bool _descExpanded = false;
  int _imageIndex = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _reserve(ListingEntity listing) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReserveSheet(listing: listing, quantity: _quantity),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isReserving = true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(ApiEndpoints.orders, data: {
        'listingId': listing.id,
        'quantity': _quantity,
      });
      final body = response.data as Map<String, dynamic>;
      final orderId = (body['data'] ?? body)['id'] as String;
      if (mounted) context.go('/customer/orders/$orderId');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isReserving = false);
  }

  Future<void> _toggleFavorite(String listingId) async {
    try {
      await ref.read(favoritesProvider.notifier).toggle(listingId);
      if (mounted) context.showSnackBar('Favorites updated');
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
        final isUrgent = listing.availableQty > 0 && listing.availableQty <= 3;
        final isSoldOut = listing.availableQty == 0;
        final savings = (listing.originalPrice - listing.discountedPrice) * _quantity;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(listingDetailProvider(widget.listingId)),
                child: CustomScrollView(
                  slivers: [
                  // Hero image area
                  SliverToBoxAdapter(child: _buildImageGallery(listing, isFav)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + discount
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(listing.name, style: AppTextStyles.h3),
                              ),
                              const SizedBox(width: 8),
                              DiscountBadge(percent: listing.discountPercent),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Category + status chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _InfoChip(
                                icon: Icons.category_outlined,
                                label: listing.category
                                    .replaceAll('_', ' ')
                                    .toLowerCase()
                                    .split(' ')
                                    .map((w) => w.isEmpty
                                        ? w
                                        : '${w[0].toUpperCase()}${w.substring(1)}')
                                    .join(' '),
                                color: AppColors.primaryMedium,
                              ),
                              if (isSoldOut)
                                const _InfoChip(
                                  icon: Icons.block,
                                  label: 'Sold Out',
                                  color: AppColors.error,
                                  bgColor: Color(0xFFFFEBEE),
                                )
                              else if (isUrgent)
                                _InfoChip(
                                  icon: Icons.local_fire_department,
                                  label: 'Only ${listing.availableQty} left!',
                                  color: Colors.orange.shade700,
                                  bgColor: Colors.orange.shade50,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Price row
                          _buildPriceRow(listing),
                          const Divider(height: 28),
                          // Stock + distance row
                          _buildStatsRow(listing),
                          const Divider(height: 28),
                          // Pickup window
                          _buildPickupSection(listing),
                          const Divider(height: 28),
                          // Vendor card
                          _buildVendorCard(listing),
                          const Divider(height: 28),
                          // Description
                          if (listing.description != null &&
                              listing.description!.isNotEmpty) ...[
                            _buildDescription(listing),
                            const Divider(height: 28),
                          ],
                          // Quantity stepper
                          if (!isSoldOut) ...[
                            _buildQuantitySection(listing),
                            const SizedBox(height: 8),
                            // Savings callout
                            if (savings > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.primaryLight.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🌿', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You save ${Formatters.formatNPR(savings)} and help reduce food waste!',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.primaryMedium),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
                ),
              ),
              // Bottom bar
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
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryMedium)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(listingDetailProvider(widget.listingId)),
        ),
      ),
    );
  }

  // ── Image gallery ──────────────────────────────────────────────────────────

  Widget _buildImageGallery(ListingEntity listing, bool isFav) {
    final images = listing.imageUrls;
    final hasImages = images.isNotEmpty;

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Images
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
                child: Icon(Icons.fastfood, size: 80, color: AppColors.primaryLight),
              ),
            ),
          // Gradient overlay at top for buttons
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
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          // Action buttons (favorite + share)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Row(
              children: [
                _CircleIconButton(
                  icon: isFav ? Icons.favorite : Icons.favorite_border,
                  iconColor: isFav ? Colors.red : Colors.white,
                  onTap: () => _toggleFavorite(listing.id),
                ),
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: Icons.share_outlined,
                  onTap: () => _share(listing),
                ),
              ],
            ),
          ),
          // Page indicator dots
          if (images.length > 1)
            Positioned(
              bottom: 12,
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          // Image counter badge
          if (images.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
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

  // ── Price row ─────────────────────────────────────────────────────────────

  Widget _buildPriceRow(ListingEntity listing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          Formatters.formatNPR(listing.discountedPrice),
          style: AppTextStyles.h2.copyWith(color: AppColors.primaryMedium),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            Formatters.formatNPR(listing.originalPrice),
            style: AppTextStyles.bodyMedium.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Save ${Formatters.formatNPR(listing.originalPrice - listing.discountedPrice)}',
            style: AppTextStyles.caption.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(ListingEntity listing) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.inventory_2_outlined,
            label: 'Available',
            value: '${listing.availableQty} portions',
            valueColor: listing.availableQty <= 3 && listing.availableQty > 0
                ? Colors.orange.shade700
                : listing.availableQty == 0
                    ? AppColors.error
                    : AppColors.primaryMedium,
          ),
        ),
        _verticalDivider(),
        Expanded(
          child: _StatTile(
            icon: Icons.star,
            label: 'Vendor Rating',
            value: listing.vendor != null
                ? '${listing.vendor!.avgRating.toStringAsFixed(1)} / 5'
                : '—',
            valueColor: AppColors.accentAmber,
          ),
        ),
        _verticalDivider(),
        Expanded(
          child: _StatTile(
            icon: Icons.location_on_outlined,
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

  Widget _verticalDivider() {
    return Container(width: 1, height: 44, color: const Color(0xFFEEEEEE));
  }

  // ── Pickup section ────────────────────────────────────────────────────────

  Widget _buildPickupSection(ListingEntity listing) {
    final now = DateTime.now();
    final pickupToday = listing.pickupStart.day == now.day &&
        listing.pickupStart.month == now.month &&
        listing.pickupStart.year == now.year;
    final pickupTomorrow = listing.pickupStart.day == now.add(const Duration(days: 1)).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pickup Window', style: AppTextStyles.h5),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.access_time, color: AppColors.primaryMedium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.formatPickupTime(listing.pickupStart, listing.pickupEnd),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    pickupToday
                        ? 'Today'
                        : pickupTomorrow
                            ? 'Tomorrow'
                            : Formatters.formatDate(listing.pickupStart),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (pickupToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Vendor card ───────────────────────────────────────────────────────────

  Widget _buildVendorCard(ListingEntity listing) {
    final vendor = listing.vendor;
    if (vendor == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vendor', style: AppTextStyles.h5),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBF8),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: const Color(0xFFE0E8E0)),
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
                        ? const Icon(Icons.store, size: 22, color: AppColors.primaryLight)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.businessName, style: AppTextStyles.h5),
                        Text(
                          vendor.businessType.replaceAll('_', ' '),
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.accentAmber),
                          const SizedBox(width: 3),
                          Text(
                            vendor.avgRating.toStringAsFixed(1),
                            style: AppTextStyles.h5,
                          ),
                        ],
                      ),
                      Text(
                        '${vendor.totalReviews} reviews',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              if (vendor.address != null && vendor.address!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primaryMedium),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(vendor.address!, style: AppTextStyles.bodySmall),
                    ),
                    if (listing.distance != null)
                      Text(
                        '${listing.distance!.toStringAsFixed(1)} km away',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Description ───────────────────────────────────────────────────────────

  Widget _buildDescription(ListingEntity listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this listing', style: AppTextStyles.h5),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            listing.description!,
            style: AppTextStyles.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(listing.description!, style: AppTextStyles.bodySmall),
          crossFadeState:
              _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (listing.description!.length > 120)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _descExpanded ? 'Show less ↑' : 'Read more ↓',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryMedium),
              ),
            ),
          ),
      ],
    );
  }

  // ── Quantity stepper ──────────────────────────────────────────────────────

  Widget _buildQuantitySection(ListingEntity listing) {
    final total = listing.discountedPrice * _quantity;

    return Column(
      children: [
        Row(
          children: [
            Text('Quantity', style: AppTextStyles.h5),
            const Spacer(),
            _QuantityStepper(
              value: _quantity,
              max: listing.availableQty,
              onChanged: (v) => setState(() => _quantity = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Total:', style: AppTextStyles.bodyMedium),
            const SizedBox(width: 8),
            Text(
              Formatters.formatNPR(total),
              style: AppTextStyles.h4.copyWith(color: AppColors.primaryMedium),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.formatNPR(listing.originalPrice * _quantity),
              style: AppTextStyles.caption.copyWith(
                  decoration: TextDecoration.lineThrough, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(ListingEntity listing, bool isSoldOut) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSoldOut)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.block),
                label: const Text('Sold Out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            AppButton(
              label: 'Reserve Now — ${Formatters.formatNPR(listing.discountedPrice * _quantity)}',
              onPressed: !_isReserving ? () => _reserve(listing) : null,
              isLoading: _isReserving,
            ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Cash on Pickup',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.verified_outlined, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Free cancellation',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────

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
      placeholder: (_, __) => Container(color: AppColors.primarySurface),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.primarySurface,
        child: const Center(
          child: Icon(Icons.fastfood, size: 64, color: AppColors.primaryLight),
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
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
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
        Icon(icon, color: valueColor, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.h6.copyWith(color: valueColor),
            textAlign: TextAlign.center),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
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
          icon: Icons.remove,
          enabled: value > 1,
          onTap: () => onChanged(value - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: AppTextStyles.h4),
        ),
        _StepBtn(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primaryMedium : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Reserve confirmation sheet ────────────────────────────────────────────

class _ReserveSheet extends StatelessWidget {
  const _ReserveSheet({required this.listing, required this.quantity});
  final ListingEntity listing;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final total = listing.discountedPrice * quantity;
    final savings = (listing.originalPrice - listing.discountedPrice) * quantity;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Confirm Reservation', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          _Row(icon: Icons.fastfood_outlined, text: listing.name),
          const SizedBox(height: 8),
          if (listing.vendor != null)
            _Row(icon: Icons.store_outlined, text: listing.vendor!.businessName),
          const SizedBox(height: 8),
          _Row(icon: Icons.shopping_bag_outlined, text: '$quantity portion${quantity > 1 ? 's' : ''}'),
          const SizedBox(height: 8),
          _Row(
            icon: Icons.access_time,
            text: Formatters.formatPickupTime(listing.pickupStart, listing.pickupEnd),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primaryMedium, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.formatNPR(total),
                      style: AppTextStyles.h4.copyWith(color: AppColors.primaryMedium)),
                  if (savings > 0)
                    Text('You save ${Formatters.formatNPR(savings)}',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.green.shade700)),
                ],
              ),
              const Spacer(),
              const Text('Cash on Pickup',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMedium,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm & Reserve',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryMedium),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}
