import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/vendor_listings_provider.dart';

class VendorListingDetailScreen extends ConsumerStatefulWidget {
  const VendorListingDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<VendorListingDetailScreen> createState() =>
      _VendorListingDetailScreenState();
}

class _VendorListingDetailScreenState
    extends ConsumerState<VendorListingDetailScreen> {
  int _imageIndex = 0;
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(vendorListingDetailProvider(widget.listingId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(children: [
            ShimmerCard(height: 280),
            SizedBox(height: 16),
            ShimmerCard(height: 160),
            SizedBox(height: 16),
            ShimmerCard(height: 120),
          ]),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Listing Detail')),
        body: ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(vendorListingDetailProvider(widget.listingId)),
        ),
      ),
      data: (listing) => _ListingDetail(
        listing: listing,
        imageIndex: _imageIndex,
        pageCtrl: _pageCtrl,
        onImageChanged: (i) => setState(() => _imageIndex = i),
        onEdit: () => context.push('/vendor/listings/${listing.id}/edit'),
        onToggleActive: () => _confirmToggleActive(context, listing),
        onMarkSoldOut: () => _confirmMarkSoldOut(context, listing),
        onDelete: () => _confirmDelete(context, listing),
      ),
    );
  }

  void _confirmToggleActive(BuildContext context, VendorListing listing) {
    final pausing = listing.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pausing ? 'Pause Listing' : 'Activate Listing'),
        content: Text(
          pausing
              ? 'Pause "${listing.name}"? Customers will no longer see it.'
              : 'Activate "${listing.name}"? It will be visible to customers.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(vendorListingsProvider.notifier)
                    .toggleActive(listing.id, !listing.isActive);
                ref.invalidate(vendorListingDetailProvider(listing.id));
                if (context.mounted) {
                  context.showSnackBar(
                      pausing ? 'Listing paused' : 'Listing activated');
                }
              } catch (_) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to update listing');
                }
              }
            },
            child: Text(pausing ? 'Pause' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _confirmMarkSoldOut(BuildContext context, VendorListing listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Sold Out'),
        content: Text(
            'Mark "${listing.name}" as sold out? Available quantity will be set to 0.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(vendorListingsProvider.notifier)
                    .markSoldOut(listing.id);
                ref.invalidate(vendorListingDetailProvider(listing.id));
                if (context.mounted) {
                  context.showSnackBar('Marked as sold out');
                }
              } catch (_) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to mark sold out');
                }
              }
            },
            child: const Text('Mark Sold Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VendorListing listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(vendorListingsProvider.notifier)
                    .deleteListing(listing.id);
                if (context.mounted) {
                  context.showSnackBar('Listing deleted');
                  context.pop();
                }
              } catch (_) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to delete listing');
                }
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ListingDetail extends StatelessWidget {
  const _ListingDetail({
    required this.listing,
    required this.imageIndex,
    required this.pageCtrl,
    required this.onImageChanged,
    required this.onEdit,
    required this.onToggleActive,
    required this.onMarkSoldOut,
    required this.onDelete,
  });

  final VendorListing listing;
  final int imageIndex;
  final PageController pageCtrl;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onMarkSoldOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = listing.isSoldOut
        ? AppColors.error
        : listing.isActive
            ? AppColors.success
            : AppColors.warning;
    final statusLabel =
        listing.isSoldOut ? 'Sold Out' : listing.isActive ? 'Active' : 'Paused';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar with image ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'toggle') onToggleActive();
                  if (v == 'soldout') onMarkSoldOut();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                        listing.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(listing.isActive
                          ? 'Pause Listing'
                          : 'Activate Listing'),
                    ]),
                  ),
                  if (!listing.isSoldOut)
                    const PopupMenuItem(
                      value: 'soldout',
                      child: Row(children: [
                        Icon(Icons.remove_shopping_cart_outlined,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 10),
                        Text('Mark as Sold Out'),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Text('Delete Listing',
                          style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: listing.imageUrls.isEmpty
                  ? Container(
                      color: AppColors.primarySurface,
                      child: const Center(
                        child: Icon(Icons.fastfood_outlined,
                            color: AppColors.primaryLight, size: 64),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: pageCtrl,
                          itemCount: listing.imageUrls.length,
                          onPageChanged: onImageChanged,
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: listing.imageUrls[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primarySurface,
                              child: const Icon(Icons.fastfood_outlined,
                                  color: AppColors.primaryLight, size: 64),
                            ),
                          ),
                        ),
                        if (listing.imageUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                listing.imageUrls.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == imageIndex ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == imageIndex
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
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
                  // ── Title + status ──────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing.name, style: AppTextStyles.h3),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(color: statusColor, label: statusLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(
                      Formatters.formatCategory(listing.category),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DiscountBadge(percent: listing.discountPercent),
                  ]),

                  const SizedBox(height: 16),

                  // ── Pricing card ────────────────────────────────────
                  _SectionCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discounted Price',
                                style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatNPR(listing.discountedPrice),
                              style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primaryMedium),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: AppColors.neutral200),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Original Price',
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.formatNPR(listing.originalPrice),
                                style: AppTextStyles.h4.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // ── Stats row ───────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: _StatTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Available',
                      value:
                          '${listing.availableQty} / ${listing.quantity}',
                      color: listing.isSoldOut
                          ? AppColors.error
                          : AppColors.primaryMedium,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatTile(
                      icon: Icons.check_circle_outline,
                      label: 'Sold',
                      value: '${listing.soldCount}',
                      color: AppColors.success,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatTile(
                      icon: Icons.savings_outlined,
                      label: 'Revenue',
                      value: Formatters.formatNPR(
                          listing.soldCount * listing.discountedPrice),
                      color: AppColors.info,
                    )),
                  ]),

                  const SizedBox(height: 12),

                  // ── Stock progress ──────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stock Level',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${listing.availableQty} remaining',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: listing.quantity > 0
                                ? listing.availableQty / listing.quantity
                                : 0,
                            minHeight: 10,
                            backgroundColor: AppColors.primarySurface,
                            color: listing.isSoldOut
                                ? AppColors.error
                                : AppColors.primaryMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${listing.soldCount} of ${listing.quantity} items sold'
                          '  ·  ${listing.discountPercent}% OFF',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Expiry ──────────────────────────────────────────
                  if (listing.expiryTime != null)
                    _SectionCard(
                      child: _InfoRow(
                        icon: Icons.timer_outlined,
                        label: 'Expires',
                        value: Formatters.formatDateTime(listing.expiryTime!),
                        color: AppColors.warning,
                      ),
                    ),

                  // ── Description ─────────────────────────────────────
                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(listing.description!,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],

                  // ── Condition notes ─────────────────────────────────
                  if (listing.conditionNotes != null &&
                      listing.conditionNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Condition Notes',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(listing.conditionNotes!,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],

                  // ── Dietary tags ────────────────────────────────────
                  if (listing.dietaryTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dietary Tags',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: listing.dietaryTags
                                .map((tag) => Chip(
                                      label: Text(tag,
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.primaryMedium)),
                                      backgroundColor: AppColors.primarySurface,
                                      side: const BorderSide(
                                          color: AppColors.primarySurfaceDim),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ─────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleActive,
                icon: Icon(
                  listing.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 18,
                  color: AppColors.warning,
                ),
                label: Text(listing.isActive ? 'Pause' : 'Activate',
                    style: const TextStyle(color: AppColors.warning)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMedium,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.h6
                .copyWith(color: color, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label, style: AppTextStyles.caption),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}
