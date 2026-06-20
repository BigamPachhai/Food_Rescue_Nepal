import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../home/providers/listings_provider.dart';
import '../../home/screens/customer_home_screen.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _sort = 'default';

  static const _sortOptions = {
    'default': 'Default',
    'name': 'Name A–Z',
    'price_asc': 'Lowest Price',
    'price_desc': 'Highest Price',
    'discount': 'Best Discount',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ListingEntity> _sorted(List<ListingEntity> favs) {
    final list = [...favs];
    switch (_sort) {
      case 'name': list.sort((a, b) => a.name.compareTo(b.name));
      case 'price_asc': list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
      case 'price_desc': list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
      case 'discount': list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final favAsync = ref.watch(favoritesProvider);
    final vendorFavAsync = ref.watch(vendorFavoritesProvider);

    final listingCount = favAsync.value?.length ?? 0;
    final vendorCount = vendorFavAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => _sortOptions.entries.map((e) => PopupMenuItem(
              value: e.key,
              child: Row(children: [
                if (_sort == e.key) ...[
                  const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryMedium),
                  const SizedBox(width: 8),
                ],
                Text(e.value),
              ]),
            )).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.h6.copyWith(color: Colors.white),
          unselectedLabelStyle:
              AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          tabs: [
            Tab(text: 'Food ($listingCount)'),
            Tab(text: 'Vendors ($vendorCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Food listings tab ──────────────────────────────────────
          favAsync.when(
            data: (favs) {
              if (favs.isEmpty) {
                return EmptyStateView(
                  icon: Icons.favorite_border,
                  title: 'No food favorites yet',
                  subtitle:
                      'Tap the ♥ on any listing card to save it here for quick access.',
                  ctaLabel: 'Explore Deals',
                  onCtaTap: () => context.go('/customer/home'),
                );
              }
              final sorted = _sorted(favs);
              return RefreshIndicator(
                color: AppColors.primaryMedium,
                onRefresh: () => ref.read(favoritesProvider.notifier).fetch(),
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => Dismissible(
                    key: ValueKey(sorted[i].id),
                    direction: DismissDirection.endToStart,
                    background: _swipeBackground(),
                    onDismissed: (_) async {
                      try {
                        await ref.read(favoritesProvider.notifier).toggle(sorted[i].id);
                        if (context.mounted) context.showSnackBar('Removed from favorites');
                      } catch (_) {
                        if (context.mounted) context.showErrorSnackBar('Could not remove favorite');
                      }
                    },
                    child: ListingCard(
                      listing: sorted[i],
                      onTap: () => context.push('/customer/listing/${sorted[i].id}'),
                    ),
                  ),
                ),
              );
            },
            loading: () => ListView.builder(
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ShimmerCard(height: 100),
              ),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(favoritesProvider.notifier).fetch(),
            ),
          ),

          // ── Vendor favorites tab ───────────────────────────────────
          vendorFavAsync.when(
            data: (vendors) {
              if (vendors.isEmpty) {
                return EmptyStateView(
                  icon: Icons.store_outlined,
                  title: 'No vendor favorites yet',
                  subtitle:
                      'Save vendors you love to quickly browse their listings.',
                  ctaLabel: 'Find Vendors',
                  onCtaTap: () => context.go('/customer/home'),
                );
              }
              return RefreshIndicator(
                color: AppColors.primaryMedium,
                onRefresh: () =>
                    ref.read(vendorFavoritesProvider.notifier).fetch(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: vendors.length,
                  itemBuilder: (_, i) => Dismissible(
                    key: ValueKey(vendors[i].id),
                    direction: DismissDirection.endToStart,
                    background: _swipeBackground(),
                    onDismissed: (_) async {
                      try {
                        await ref
                            .read(vendorFavoritesProvider.notifier)
                            .toggle(vendors[i].id);
                        if (context.mounted) context.showSnackBar('Vendor removed from favorites');
                      } catch (_) {
                        if (context.mounted) context.showErrorSnackBar('Could not remove favorite');
                      }
                    },
                    child: _VendorFavCard(vendor: vendors[i]),
                  ),
                ),
              );
            },
            loading: () => ListView.builder(
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ShimmerCard(height: 80),
              ),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () =>
                  ref.read(vendorFavoritesProvider.notifier).fetch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: Colors.white, size: 22),
          SizedBox(height: 2),
          Text('Remove', style: TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Vendor favorite card ──────────────────────────────────────────────────

class _VendorFavCard extends StatelessWidget {
  const _VendorFavCard({required this.vendor});
  final VendorEntity vendor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/customer/vendor/${vendor.id}'),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
              ),
              child: ClipOval(
                child: vendor.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: vendor.logoUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 104,
                        memCacheHeight: 104,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.store,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
                      )
                    : const Icon(Icons.store,
                        color: AppColors.primaryLight, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.businessName, style: AppTextStyles.h5),
                  Text(
                    vendor.businessType.replaceAll('_', ' '),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (vendor.address != null)
                    Text(
                      vendor.address!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.accentAmber),
                    const SizedBox(width: 2),
                    Text(
                      vendor.avgRating.toStringAsFixed(1),
                      style: AppTextStyles.h6,
                    ),
                  ],
                ),
                Text(
                  '${vendor.totalReviews} reviews',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
