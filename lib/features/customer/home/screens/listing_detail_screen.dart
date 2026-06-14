import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/error_view.dart';
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

  Future<void> _reserve(ListingEntity listing) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReserveBottomSheet(listing: listing, quantity: _quantity),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isReserving = true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(ApiEndpoints.orders, data: {
        'listingId': listing.id,
        'quantity': _quantity,
      });
      final orderId = (response.data as Map<String, dynamic>)['id'] as String;
      if (mounted) context.go('/customer/orders/$orderId');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isReserving = false);
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      data: (listing) => Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        listing.imageUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: listing.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.primarySurface),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.primarySurface,
                                  child: const Icon(Icons.fastfood,
                                      size: 80, color: AppColors.primaryLight),
                                ),
                              )
                            : Container(
                                color: AppColors.primarySurface,
                                child: const Icon(Icons.fastfood,
                                    size: 80, color: AppColors.primaryLight),
                              ),
                        Positioned(
                          top: 60,
                          right: 12,
                          child: DiscountBadge(percent: listing.discountPercent),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing.name, style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        if (listing.vendor != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primarySurface,
                                backgroundImage: listing.vendor!.logoUrl != null
                                    ? NetworkImage(listing.vendor!.logoUrl!)
                                    : null,
                                child: listing.vendor!.logoUrl == null
                                    ? const Icon(Icons.store,
                                        size: 16, color: AppColors.primaryLight)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(listing.vendor!.businessName,
                                    style: AppTextStyles.bodyMedium),
                              ),
                              const Icon(Icons.star,
                                  size: 14, color: AppColors.accentAmber),
                              const SizedBox(width: 2),
                              Text(listing.vendor!.avgRating.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        const SizedBox(height: 12),
                        if (listing.vendor?.address != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(listing.vendor!.address!,
                                    style: AppTextStyles.bodySmall),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildChip(
                              Icons.access_time,
                              Formatters.formatPickupTime(
                                  listing.pickupStart, listing.pickupEnd),
                            ),
                            _buildChip(Icons.category_outlined, listing.category),
                          ],
                        ),
                        if (listing.description != null &&
                            listing.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Description', style: AppTextStyles.h5),
                          const SizedBox(height: 4),
                          AnimatedCrossFade(
                            firstChild: Text(
                              listing.description!,
                              style: AppTextStyles.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(listing.description!,
                                style: AppTextStyles.bodySmall),
                            crossFadeState: _descExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _descExpanded = !_descExpanded),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text(
                              _descExpanded ? 'Show less' : 'Read more',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.primaryMedium),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Total:', style: AppTextStyles.h5),
                            const SizedBox(width: 8),
                            Text(
                              Formatters.formatNPR(
                                  listing.discountedPrice * _quantity),
                              style: AppTextStyles.h4
                                  .copyWith(color: AppColors.primaryMedium),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Formatters.formatNPR(
                                  listing.originalPrice * _quantity),
                              style: AppTextStyles.caption.copyWith(
                                  decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Reserve Now',
                      onPressed: listing.availableQty > 0 && !_isReserving
                          ? () => _reserve(listing)
                          : null,
                      isLoading: _isReserving,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '💵 Cash on Pickup',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryMedium),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(listingDetailProvider(widget.listingId)),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryMedium),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primaryMedium)),
        ],
      ),
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
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primaryMedium,
        ),
        Text('$value', style: AppTextStyles.h4),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primaryMedium,
        ),
      ],
    );
  }
}

class _ReserveBottomSheet extends StatelessWidget {
  const _ReserveBottomSheet(
      {required this.listing, required this.quantity});
  final ListingEntity listing;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Reservation', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.fastfood_outlined, color: AppColors.primaryMedium),
            const SizedBox(width: 8),
            Expanded(
                child: Text(listing.name, style: AppTextStyles.bodyMedium)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primaryMedium),
            const SizedBox(width: 8),
            Text('Quantity: $quantity', style: AppTextStyles.bodyMedium),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.payments_outlined, color: AppColors.primaryMedium),
            const SizedBox(width: 8),
            Text(
              Formatters.formatNPR(listing.discountedPrice * quantity),
              style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Payment: Cash on Pickup',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
