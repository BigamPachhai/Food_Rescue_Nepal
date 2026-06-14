import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/vendor_listings_provider.dart';

class VendorListingsScreen extends ConsumerStatefulWidget {
  const VendorListingsScreen({super.key});

  @override
  ConsumerState<VendorListingsScreen> createState() =>
      _VendorListingsScreenState();
}

class _VendorListingsScreenState extends ConsumerState<VendorListingsScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(vendorListingsProvider);

    return Scaffold(
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
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryMedium
                          : AppColors.primarySurface,
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
                  if (_filter == 'Active') return l.isActive;
                  if (_filter == 'Inactive') return !l.isActive;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No listings yet',
                    subtitle: 'Add your first food listing to get started.',
                    ctaLabel: 'Add Listing',
                    onCtaTap: () => context.push('/vendor/listings/add'),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryMedium,
                  onRefresh: () =>
                      ref.read(vendorListingsProvider.notifier).fetch(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ListingTile(
                      listing: filtered[i],
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Listing'),
                            content: Text(
                                'Delete "${filtered[i].name}"? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(
                                        color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(vendorListingsProvider.notifier)
                              .deleteListing(filtered[i].id);
                        }
                      },
                    ),
                  ),
                );
              },
              loading: () => ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => const ShimmerCard(height: 80),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(vendorListingsProvider.notifier).fetch(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vendor/listings/add'),
        backgroundColor: AppColors.primaryMedium,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.onDelete});
  final VendorListing listing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(listing.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fastfood_outlined,
              color: AppColors.primaryLight),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(listing.name,
                  style: AppTextStyles.h6,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            DiscountBadge(percent: listing.discountPercent),
          ],
        ),
        subtitle: Text(
          '${listing.availableQty} left · ${Formatters.formatNPR(listing.discountedPrice)} · ${listing.category}',
          style: AppTextStyles.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: listing.isActive
                    ? AppColors.success
                    : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
        onTap: () => context.push('/vendor/listings/${listing.id}/edit'),
      ),
    );
  }
}
