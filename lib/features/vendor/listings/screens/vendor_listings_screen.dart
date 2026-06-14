import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/vendor_listings_provider.dart';

class VendorListingsScreen extends ConsumerStatefulWidget {
  const VendorListingsScreen({super.key});

  @override
  ConsumerState<VendorListingsScreen> createState() => _VendorListingsScreenState();
}

class _VendorListingsScreenState extends ConsumerState<VendorListingsScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Active', 'Paused', 'Sold Out'];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(vendorListingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/vendor/listings/add'),
            tooltip: 'Add listing',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected ? AppColors.primaryMedium : const Color(0xFFDDDDDD),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                final filtered = listings.where((l) {
                  if (_filter == 'Active') return l.isActive && !l.isSoldOut;
                  if (_filter == 'Paused') return !l.isActive;
                  if (_filter == 'Sold Out') return l.isSoldOut;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.restaurant_menu_outlined,
                    title: listings.isEmpty ? 'No listings yet' : 'No $_filter listings',
                    subtitle: listings.isEmpty
                        ? 'Add your first food listing to start reducing waste.'
                        : 'Try switching to a different filter.',
                    ctaLabel: listings.isEmpty ? 'Add Listing' : null,
                    onCtaTap: listings.isEmpty ? () => context.push('/vendor/listings/add') : null,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryMedium,
                  onRefresh: () => ref.read(vendorListingsProvider.notifier).fetch(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ListingCard(
                      listing: filtered[i],
                      onEdit: () => context.push('/vendor/listings/${filtered[i].id}/edit'),
                      onToggleActive: () => ref
                          .read(vendorListingsProvider.notifier)
                          .toggleActive(filtered[i].id, !filtered[i].isActive),
                      onMarkSoldOut: () => ref
                          .read(vendorListingsProvider.notifier)
                          .markSoldOut(filtered[i].id),
                      onDuplicate: () async {
                        await ref
                            .read(vendorListingsProvider.notifier)
                            .duplicateListing(filtered[i]);
                        if (context.mounted) context.showSnackBar('Listing duplicated!');
                      },
                      onDelete: () => _confirmDelete(context, filtered[i]),
                      onAnalytics: () => _showAnalytics(context, filtered[i]),
                    ),
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerCard(height: 110),
                ),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(vendorListingsProvider.notifier).fetch(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendor/listings/add'),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Listing', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VendorListing listing) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(vendorListingsProvider.notifier).deleteListing(listing.id);
              if (context.mounted) context.showSnackBar('Listing deleted');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAnalytics(BuildContext context, VendorListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnalyticsSheet(listing: listing),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.onEdit,
    required this.onToggleActive,
    required this.onMarkSoldOut,
    required this.onDuplicate,
    required this.onDelete,
    required this.onAnalytics,
  });

  final VendorListing listing;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onMarkSoldOut;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    final statusColor = listing.isSoldOut
        ? AppColors.error
        : listing.isActive
            ? AppColors.success
            : AppColors.warning;

    final statusLabel = listing.isSoldOut
        ? 'Sold Out'
        : listing.isActive
            ? 'Active'
            : 'Paused';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + status row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.fastfood_outlined,
                                color: AppColors.primaryLight, size: 32),
                          ),
                        )
                      : Container(
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.fastfood_outlined,
                              color: AppColors.primaryLight, size: 32),
                        ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              listing.name,
                              style: AppTextStyles.h6,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Options menu
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              padding: EdgeInsets.zero,
                              onPressed: () => _showOptions(context),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            listing.category,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          DiscountBadge(percent: listing.discountPercent),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            Formatters.formatNPR(listing.discountedPrice),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatNPR(listing.originalPrice),
                            style: AppTextStyles.caption.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom info row
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Stock
                const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${listing.availableQty}/${listing.quantity} left',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                // Pickup time
                const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${_fmtTime(listing.pickupStart)} – ${_fmtTime(listing.pickupEnd)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Stock progress bar
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: LinearProgressIndicator(
              value: listing.quantity > 0 ? listing.availableQty / listing.quantity : 0,
              minHeight: 3,
              backgroundColor: AppColors.primarySurface,
              color: listing.isSoldOut ? AppColors.error : AppColors.primaryMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(listing.name, style: AppTextStyles.h5, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Listing',
              color: AppColors.textPrimary,
              onTap: () { Navigator.pop(sheetCtx); onEdit(); },
            ),
            _OptionTile(
              icon: listing.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              label: listing.isActive ? 'Pause Listing' : 'Activate Listing',
              color: AppColors.warning,
              onTap: () { Navigator.pop(sheetCtx); onToggleActive(); },
            ),
            if (!listing.isSoldOut)
              _OptionTile(
                icon: Icons.remove_shopping_cart_outlined,
                label: 'Mark as Sold Out',
                color: AppColors.error,
                onTap: () { Navigator.pop(sheetCtx); onMarkSoldOut(); },
              ),
            _OptionTile(
              icon: Icons.copy_outlined,
              label: 'Duplicate Listing',
              color: AppColors.info,
              onTap: () { Navigator.pop(sheetCtx); onDuplicate(); },
            ),
            _OptionTile(
              icon: Icons.bar_chart_outlined,
              label: 'View Analytics',
              color: AppColors.primaryMedium,
              onTap: () { Navigator.pop(sheetCtx); onAnalytics(); },
            ),
            const Divider(height: 1),
            _OptionTile(
              icon: Icons.delete_outline,
              label: 'Delete Listing',
              color: AppColors.error,
              onTap: () { Navigator.pop(sheetCtx); onDelete(); },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }
}

class _AnalyticsSheet extends StatelessWidget {
  const _AnalyticsSheet({required this.listing});
  final VendorListing listing;

  @override
  Widget build(BuildContext context) {
    final sold = listing.soldCount;
    final revenue = sold * listing.discountedPrice;
    final savedAmount = sold * (listing.originalPrice - listing.discountedPrice);
    final foodSavedKg = (sold * 0.3);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.bar_chart_outlined, color: AppColors.primaryMedium),
              const SizedBox(width: 8),
              Expanded(child: Text('Analytics', style: AppTextStyles.h4)),
            ],
          ),
          const SizedBox(height: 4),
          Text(listing.name, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _StatCard(
                label: 'Items Sold',
                value: '$sold / ${listing.quantity}',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.primaryMedium,
              ),
              _StatCard(
                label: 'Revenue',
                value: Formatters.formatNPR(revenue),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              _StatCard(
                label: 'Customer Savings',
                value: Formatters.formatNPR(savedAmount),
                icon: Icons.savings_outlined,
                color: AppColors.accentAmber,
              ),
              _StatCard(
                label: 'Food Saved',
                value: '~${foodSavedKg.toStringAsFixed(1)} kg',
                icon: Icons.eco_outlined,
                color: AppColors.primaryMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stock bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stock', style: AppTextStyles.caption),
              Text('${listing.availableQty} remaining', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: listing.quantity > 0 ? listing.availableQty / listing.quantity : 0,
              minHeight: 8,
              backgroundColor: AppColors.primarySurface,
              color: listing.isSoldOut ? AppColors.error : AppColors.primaryMedium,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${listing.discountPercent}% OFF', style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600)),
              Text('Pickup: ${_fmtDate(listing.pickupStart)} – ${_fmtDate(listing.pickupEnd)}', style: AppTextStyles.caption),
            ],
          ),
          if (listing.expiryTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('Expires: ${_fmtDate(listing.expiryTime!)}', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTextStyles.h6.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: AppTextStyles.caption, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
