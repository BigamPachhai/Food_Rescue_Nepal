import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/discount_badge.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/constants/api_endpoints.dart';

class _AdminListing {
  final String id;
  final String name;
  final String category;
  final int discountedPrice;
  final int originalPrice;
  final bool isActive;
  final String vendorName;

  const _AdminListing({
    required this.id,
    required this.name,
    required this.category,
    required this.discountedPrice,
    required this.originalPrice,
    required this.isActive,
    required this.vendorName,
  });

  factory _AdminListing.fromJson(Map<String, dynamic> json) => _AdminListing(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        discountedPrice: json['discountedPrice'] as int,
        originalPrice: json['originalPrice'] as int,
        isActive: json['isActive'] as bool? ?? true,
        vendorName:
            (json['vendor'] as Map<String, dynamic>?)?['businessName']
                    as String? ??
                '',
      );

  int get discountPercent {
    if (originalPrice == 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }
}

final _adminListingsProvider =
    FutureProvider<List<_AdminListing>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.adminListings);
  final data = response.data;
  List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['data'] is List) {
    items = data['data'] as List<dynamic>;
  } else {
    items = [];
  }
  return items
      .map((e) => _AdminListing.fromJson(e as Map<String, dynamic>))
      .toList();
});

class AdminListingsScreen extends ConsumerWidget {
  const AdminListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(_adminListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Listings')),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const EmptyStateView(
              icon: Icons.restaurant_menu_outlined,
              title: 'No listings',
              subtitle: 'No food listings have been created yet.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () async =>
                ref.invalidate(_adminListingsProvider),
            child: ListView.builder(
              itemCount: listings.length,
              itemBuilder: (_, i) =>
                  _ListingTile(listing: listings[i]),
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => const ShimmerCard(height: 80),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(_adminListingsProvider),
        ),
      ),
    );
  }
}

class _ListingTile extends ConsumerWidget {
  const _ListingTile({required this.listing});
  final _AdminListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
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
        '${listing.vendorName} · ${Formatters.formatNPR(listing.discountedPrice)}',
        style: AppTextStyles.caption,
      ),
      trailing: listing.isActive
          ? IconButton(
              icon: const Icon(Icons.block, color: AppColors.error),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Deactivate Listing'),
                    content: Text('Deactivate "${listing.name}"? Customers will no longer see it.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Deactivate'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await ref.read(dioClientProvider).patch(
                      ApiEndpoints.adminDeactivateListing(listing.id));
                  ref.invalidate(_adminListingsProvider);
                  if (context.mounted) context.showSnackBar('Listing deactivated');
                } catch (e) {
                  if (context.mounted) context.showErrorSnackBar(e.toString());
                }
              },
              tooltip: 'Deactivate',
            )
          : const Icon(Icons.check_circle_outline,
              color: AppColors.textSecondary),
    );
  }
}
