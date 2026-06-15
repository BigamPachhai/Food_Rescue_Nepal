import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../providers/listings_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchMode = false;
  String _selectedCategory = 'All';

  static const _categories = [
    'All', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(listingsProvider.notifier).fetch();
    }
  }

  void _enterSearch() => setState(() => _isSearchMode = true);

  void _exitSearch() {
    setState(() => _isSearchMode = false);
    _searchCtrl.clear();
    ref.read(listingsProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final filter = ref.watch(listingsProvider.notifier).currentFilter;

    if (_isSearchMode) {
      return _SearchOverlay(
        controller: _searchCtrl,
        onBack: _exitSearch,
        onCategoryTap: (cat) {
          setState(() {
            _selectedCategory = cat;
            _isSearchMode = false;
          });
          ref.read(listingsProvider.notifier).filterByCategory(cat);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () => ref.read(listingsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, unreadCount)),
            SliverToBoxAdapter(child: _buildSearchBar(filter.hasActiveFilters, filter)),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildFeaturedSection()),
            SliverToBoxAdapter(child: _buildPopularVendorsSection()),
            SliverToBoxAdapter(child: _buildFeedHeader(filter)),
            listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyStateView(
                        icon: Icons.fastfood_outlined,
                        title: 'No listings found',
                        subtitle: 'Try adjusting filters or check back later.',
                      ),
                    ),
                  );
                }
                final hasMore = ref.read(listingsProvider.notifier).hasMore;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == listings.length) {
                        if (!hasMore) return const SizedBox(height: AppSizes.s4);
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.s4),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryMedium,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListingCard(
                        listing: listings[index],
                        onTap: () =>
                            context.push('/customer/listing/${listings[index].id}'),
                      );
                    },
                    childCount: listings.length + 1,
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.s4,
                      vertical: AppSizes.s1,
                    ),
                    child: ShimmerCard(height: 104),
                  ),
                  childCount: 4,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  error: e,
                  onRetry: () => ref.read(listingsProvider.notifier).refresh(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.s3,
        left: AppSizes.s4,
        right: AppSizes.s1,
        bottom: AppSizes.s4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: AppSizes.s1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: AppTextStyles.caption.copyWith(color: Colors.white60),
                ),
                Text('Kathmandu, Nepal', style: AppTextStyles.h5OnPrimary),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.accentAmber,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool hasFilters, ListingsFilter filter) {
    return Container(
      color: AppColors.primaryMedium,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s4, 0, AppSizes.s4, AppSizes.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _enterSearch,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSizes.s3),
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSizes.s2),
                    Text(
                      'Search food, vendors…',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s2),
          GestureDetector(
            onTap: () => _showFilterSheet(filter),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasFilters ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasFilters ? AppColors.primaryMedium : Colors.white,
                    size: AppSizes.iconMd,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s3,
          vertical: AppSizes.s2,
        ),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                ref
                    .read(listingsProvider.notifier)
                    .filterByCategory(cat == 'All' ? null : cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s3,
                  vertical: AppSizes.s1,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryMedium : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryMedium : AppColors.border,
                  ),
                  boxShadow: isSelected ? AppShadows.xs : [],
                ),
                child: Text(
                  cat,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featuredAsync = ref.watch(featuredListingsProvider);
    return featuredAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s3,
              ),
              child: Row(
                children: [
                  Text('Featured Deals', style: AppTextStyles.h4),
                  const SizedBox(width: AppSizes.s2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'HOT',
                      style: AppTextStyles.overline
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref
                        .read(listingsProvider.notifier)
                        .applyFilter(const ListingsFilter(sortBy: 'discount')),
                    child: Text(
                      'See all',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: Responsive.featuredCardWidth(context) * 0.68 + 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                itemCount: listings.length,
                itemBuilder: (_, i) => _FeaturedCard(
                  listing: listings[i],
                  onTap: () =>
                      context.push('/customer/listing/${listings[i].id}'),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s2),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.s4, AppSizes.s4, AppSizes.s4, 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Featured Deals', style: AppTextStyles.h4),
            const SizedBox(height: AppSizes.s3),
            const ShimmerCard(height: 210),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPopularVendorsSection() {
    final vendorsAsync = ref.watch(publicVendorsProvider);
    return vendorsAsync.when(
      data: (vendors) {
        final topVendors = vendors
            .where((v) => v.status == 'APPROVED')
            .toList()
          ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
        final featured = topVendors.take(10).toList();
        if (featured.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s4, AppSizes.s2, AppSizes.s4, AppSizes.s3,
              ),
              child: Text('Popular Vendors', style: AppTextStyles.h4),
            ),
            SizedBox(
              height: Responsive.isTablet(context) ? 120 : 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                itemCount: featured.length,
                itemBuilder: (_, i) => _VendorChip(vendor: featured[i]),
              ),
            ),
            const SizedBox(height: AppSizes.s2),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeedHeader(ListingsFilter filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s4, AppSizes.s2, AppSizes.s2, AppSizes.s2,
      ),
      child: Row(
        children: [
          Text('Nearby Offers', style: AppTextStyles.h4),
          const Spacer(),
          _SortButton(
            currentSort: filter.sortBy,
            onSortChanged: (s) => ref
                .read(listingsProvider.notifier)
                .applyFilter(filter.copyWith(sortBy: s)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(ListingsFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialFilter: currentFilter,
        onApply: (filter) {
          ref.read(listingsProvider.notifier).applyFilter(filter);
          setState(() => _selectedCategory = filter.category ?? 'All');
        },
        onReset: () {
          ref.read(listingsProvider.notifier).resetFilters();
          setState(() => _selectedCategory = 'All');
        },
      ),
    );
  }
}

// ─── Featured Card ─────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.listing, required this.onTap});
  final ListingEntity listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardW = Responsive.featuredCardWidth(context);
    final imageH = (cardW * 0.68).roundToDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardW,
        margin:
            const EdgeInsets.only(right: AppSizes.s3, bottom: AppSizes.s1),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusCard),
                  ),
                  child: listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          width: cardW,
                          height: imageH,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(cardW, imageH),
                        )
                      : _placeholder(cardW, imageH),
                ),
                Positioned(
                  top: AppSizes.s2,
                  left: AppSizes.s2,
                  child: DiscountBadge(percent: listing.discountPercent),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s2, AppSizes.s2, AppSizes.s2, AppSizes.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: AppTextStyles.h6,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        Formatters.formatNPR(listing.discountedPrice),
                        style: AppTextStyles.h6
                            .copyWith(color: AppColors.primaryMedium),
                      ),
                      const SizedBox(width: AppSizes.s1),
                      Text(
                        Formatters.formatNPR(listing.originalPrice),
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${listing.availableQty} left',
                    style: AppTextStyles.caption.copyWith(
                      color: listing.availableQty <= 3
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: listing.availableQty <= 3
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder([double? width, double? height]) => Container(
        width: width ?? 168,
        height: height ?? 114,
        color: AppColors.primarySurface,
        child: const Icon(
          Icons.fastfood_rounded,
          color: AppColors.primaryLight,
          size: 36,
        ),
      );
}

// ─── Vendor Chip ───────────────────────────────────────────────────────────

class _VendorChip extends StatelessWidget {
  const _VendorChip({required this.vendor});
  final VendorEntity vendor;

  @override
  Widget build(BuildContext context) {
    final avatarSize = Responsive.isTablet(context) ? 72.0 : 56.0;
    final chipWidth = avatarSize + 20;
    return Container(
      width: chipWidth,
      margin: const EdgeInsets.only(right: AppSizes.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: AppShadows.xs,
            ),
            child: ClipOval(
              child: vendor.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: vendor.logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: AppColors.primaryLight,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.store_rounded,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.s1),
          Text(
            vendor.businessName,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 10,
                color: AppColors.accentAmber,
              ),
              const SizedBox(width: 2),
              Text(
                vendor.avgRating.toStringAsFixed(1),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sort Button ───────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  const _SortButton({required this.currentSort, required this.onSortChanged});
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  static const _sorts = {
    'newest': 'Latest',
    'price_asc': 'Lowest Price',
    'price_desc': 'Highest Price',
    'discount': 'Best Discount',
    'popular': 'Most Popular',
    'nearest': 'Nearest',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusBottomSheet),
          ),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort By', style: AppTextStyles.h4),
              const SizedBox(height: AppSizes.s3),
              ..._sorts.entries.map(
                (e) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSortChanged(e.key);
                  },
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.s3),
                    child: Row(
                      children: [
                        Icon(
                          currentSort == e.key
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: currentSort == e.key
                              ? AppColors.primaryMedium
                              : AppColors.neutral300,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.s3),
                        Text(e.value, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 14,
              color: AppColors.primaryMedium,
            ),
            const SizedBox(width: AppSizes.s1),
            Text(
              _sorts[currentSort] ?? 'Sort',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Sheet ──────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialFilter,
    required this.onApply,
    required this.onReset,
  });
  final ListingsFilter initialFilter;
  final ValueChanged<ListingsFilter> onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _category;
  late String _sortBy;
  late RangeValues _priceRange;
  late double _maxDistance;
  late double _minRating;
  late bool _onlyAvailable;

  static const _maxPriceValue = 5000.0;
  static const _maxDistanceValue = 50.0;
  static const _categories = [
    'All', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    _category = f.category ?? 'All';
    _sortBy = f.sortBy;
    _priceRange = RangeValues(
      (f.minPrice ?? 0).toDouble() / 100,
      (f.maxPrice ?? (_maxPriceValue * 100).toInt()).toDouble() / 100,
    );
    _maxDistance = f.maxDistance ?? _maxDistanceValue;
    _minRating = f.minRating ?? 0;
    _onlyAvailable = f.onlyAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusBottomSheet),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s4, AppSizes.s3, AppSizes.s4, 0,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.s3),
                  Row(
                    children: [
                      Text('Filters', style: AppTextStyles.h4),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onReset();
                        },
                        child: const Text('Reset all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(AppSizes.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sort By', style: AppTextStyles.h5),
                    const SizedBox(height: AppSizes.s2),
                    Wrap(
                      spacing: AppSizes.s2,
                      runSpacing: AppSizes.s2,
                      children: {
                        'newest': 'Latest',
                        'discount': 'Best Discount',
                        'price_asc': 'Lowest Price',
                        'price_desc': 'Highest Price',
                        'popular': 'Most Popular',
                        'nearest': 'Nearest First',
                      }.entries.map((e) => _ChoiceChip(
                            label: e.value,
                            selected: _sortBy == e.key,
                            onTap: () => setState(() => _sortBy = e.key),
                          )).toList(),
                    ),
                    const SizedBox(height: AppSizes.s5),
                    Text('Category', style: AppTextStyles.h5),
                    const SizedBox(height: AppSizes.s2),
                    Wrap(
                      spacing: AppSizes.s2,
                      runSpacing: AppSizes.s2,
                      children: _categories
                          .map((c) => _ChoiceChip(
                                label: c,
                                selected: (_category ?? 'All') == c,
                                onTap: () => setState(() => _category = c),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSizes.s5),
                    Row(
                      children: [
                        Text('Price Range (NPR)', style: AppTextStyles.h5),
                        const Spacer(),
                        Text(
                          '${_priceRange.start.toInt()} – '
                          '${_priceRange.end >= _maxPriceValue ? 'Any' : _priceRange.end.toInt()}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _maxPriceValue,
                      divisions: 50,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                    const SizedBox(height: AppSizes.s3),
                    Row(
                      children: [
                        Text('Max Distance', style: AppTextStyles.h5),
                        const Spacer(),
                        Text(
                          _maxDistance >= _maxDistanceValue
                              ? 'Any'
                              : '${_maxDistance.toInt()} km',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1,
                      max: _maxDistanceValue,
                      divisions: 49,
                      onChanged: (v) => setState(() => _maxDistance = v),
                    ),
                    const SizedBox(height: AppSizes.s3),
                    Row(
                      children: [
                        Text('Vendor Rating', style: AppTextStyles.h5),
                        const Spacer(),
                        Text(
                          _minRating == 0
                              ? 'Any'
                              : '${_minRating.toStringAsFixed(1)}+',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Wrap(
                      spacing: AppSizes.s2,
                      children: [0.0, 3.0, 3.5, 4.0, 4.5]
                          .map((r) => _ChoiceChip(
                                label: r == 0
                                    ? 'Any'
                                    : '⭐ ${r.toStringAsFixed(1)}+',
                                selected: _minRating == r,
                                onTap: () => setState(() => _minRating = r),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSizes.s5),
                    Row(
                      children: [
                        Text('In-stock only', style: AppTextStyles.h5),
                        const Spacer(),
                        Switch(
                          value: _onlyAvailable,
                          onChanged: (v) =>
                              setState(() => _onlyAvailable = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s6),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final cat = (_category == null || _category == 'All')
                              ? null
                              : _category;
                          widget.onApply(ListingsFilter(
                            category: cat,
                            sortBy: _sortBy,
                            minPrice: _priceRange.start > 0
                                ? (_priceRange.start * 100).toInt()
                                : null,
                            maxPrice: _priceRange.end < _maxPriceValue
                                ? (_priceRange.end * 100).toInt()
                                : null,
                            maxDistance: _maxDistance < _maxDistanceValue
                                ? _maxDistance
                                : null,
                            minRating: _minRating > 0 ? _minRating : null,
                            onlyAvailable: _onlyAvailable,
                          ));
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMedium : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primaryMedium : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Search Overlay ────────────────────────────────────────────────────────

class _SearchOverlay extends ConsumerStatefulWidget {
  const _SearchOverlay({
    required this.controller,
    required this.onBack,
    required this.onCategoryTap,
  });
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onCategoryTap;

  @override
  ConsumerState<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<_SearchOverlay> {
  String _tab = 'food';
  List<VendorEntity> _vendorResults = [];
  bool _loading = false;

  static const _cats = [
    'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other',
  ];
  static const _catIcons = [
    Icons.bakery_dining_rounded,
    Icons.restaurant_rounded,
    Icons.coffee_rounded,
    Icons.shopping_basket_rounded,
    Icons.cake_rounded,
    Icons.fastfood_rounded,
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final q = widget.controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _vendorResults = [];
        _loading = false;
      });
      ref.read(listingsProvider.notifier).search('');
      return;
    }
    _doSearch(q);
  }

  Future<void> _doSearch(String q) async {
    setState(() => _loading = true);
    ref.read(listingsProvider.notifier).search(q);
    final allVendors = ref.read(publicVendorsProvider).value ?? [];
    final lower = q.toLowerCase();
    setState(() {
      _vendorResults = allVendors
          .where((v) =>
              v.businessName.toLowerCase().contains(lower) ||
              v.businessType.toLowerCase().contains(lower) ||
              (v.address?.toLowerCase().contains(lower) ?? false))
          .take(10)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final query = widget.controller.text.trim();
    final hasQuery = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.s2, AppSizes.s2, AppSizes.s4, AppSizes.s2,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textPrimary,
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      autofocus: true,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search food, vendors, categories…',
                        hintStyle: AppTextStyles.bodySmall,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: const BorderSide(
                            color: AppColors.borderFocus,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.neutral50,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: hasQuery
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                ),
                                color: AppColors.textSecondary,
                                onPressed: () => widget.controller.clear(),
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasQuery)
              Container(
                color: AppColors.surfaceLight,
                child: Row(
                  children: [
                    _buildTab('food', 'Food', Icons.fastfood_outlined),
                    _buildTab('vendors', 'Vendors', Icons.store_outlined),
                  ],
                ),
              ),
            Expanded(
              child: hasQuery
                  ? (_tab == 'food'
                      ? _buildFoodResults(listingsAsync)
                      : _buildVendorResults())
                  : _buildSuggestionsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final selected = _tab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryMedium : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.primaryMedium
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.s1),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected
                      ? AppColors.primaryMedium
                      : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodResults(AsyncValue<List<ListingEntity>> listingsAsync) {
    return listingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.neutral300,
                  ),
                  const SizedBox(height: AppSizes.s3),
                  Text('No results found', style: AppTextStyles.h5),
                  const SizedBox(height: AppSizes.s1),
                  Text('Try different keywords', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (_, i) => ListingCard(
            listing: listings[i],
            onTap: () {
              widget.onBack();
              context.push('/customer/listing/${listings[i].id}');
            },
          ),
        );
      },
      loading: () => ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.s4,
            vertical: AppSizes.s1,
          ),
          child: ShimmerCard(height: 90),
        ),
      ),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(listingsProvider),
      ),
    );
  }

  Widget _buildVendorResults() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMedium),
      );
    }
    if (_vendorResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 48,
                color: AppColors.neutral300,
              ),
              const SizedBox(height: AppSizes.s3),
              Text('No vendors found', style: AppTextStyles.h5),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _vendorResults.length,
      itemBuilder: (_, i) {
        final v = _vendorResults[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s4,
            vertical: AppSizes.s1,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: v.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: v.logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: AppColors.primaryLight,
                      ),
                    )
                  : const Icon(
                      Icons.store_rounded,
                      color: AppColors.primaryLight,
                    ),
            ),
          ),
          title: Text(v.businessName, style: AppTextStyles.h6),
          subtitle: Text(v.businessType, style: AppTextStyles.caption),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: AppColors.accentAmber,
              ),
              const SizedBox(width: 2),
              Text(v.avgRating.toStringAsFixed(1), style: AppTextStyles.caption),
            ],
          ),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildSuggestionsGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse by Category', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.gridColumns(context, mobile: 3, tablet: 5),
              mainAxisSpacing: AppSizes.s3,
              crossAxisSpacing: AppSizes.s3,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onCategoryTap(_cats[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.primarySurfaceDim),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _catIcons[i],
                      color: AppColors.primaryMedium,
                      size: 28,
                    ),
                    const SizedBox(height: AppSizes.s1),
                    Text(
                      _cats[i],
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryMedium,
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

// ─── Listing Card (public, reused across the app) ──────────────────────────

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final ListingEntity listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLowStock = listing.availableQty > 0 && listing.availableQty <= 3;
    final isSoldOut = listing.availableQty == 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.s4,
        vertical: AppSizes.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          splashColor: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      child: listing.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.imageUrls.first,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 88,
                                height: 88,
                                color: AppColors.primarySurface,
                              ),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    if (listing.discountPercent > 0)
                      Positioned(
                        top: AppSizes.s1,
                        left: AppSizes.s1,
                        child: DiscountBadge(
                            percent: listing.discountPercent),
                      ),
                  ],
                ),
                const SizedBox(width: AppSizes.s3),
                Expanded(
                  child: SizedBox(
                    height: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          style: AppTextStyles.h5,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (listing.vendor != null)
                          Text(
                            listing.vendor!.businessName,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.accentAmber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              listing.vendor?.avgRating.toStringAsFixed(1) ??
                                  '—',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(width: AppSizes.s2),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              listing.distance != null
                                  ? '${listing.distance!.toStringAsFixed(1)} km'
                                  : 'Nearby',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              Formatters.formatNPR(listing.discountedPrice),
                              style: AppTextStyles.h6.copyWith(
                                color: AppColors.primaryMedium,
                              ),
                            ),
                            const SizedBox(width: AppSizes.s1),
                            Text(
                              Formatters.formatNPR(listing.originalPrice),
                              style: AppTextStyles.caption.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSoldOut
                                    ? AppColors.errorSurface
                                    : isLowStock
                                        ? AppColors.warningSurface
                                        : AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                isSoldOut
                                    ? 'Sold out'
                                    : '${listing.availableQty} left',
                                style: AppTextStyles.caption.copyWith(
                                  color: isSoldOut
                                      ? AppColors.error
                                      : isLowStock
                                          ? AppColors.warning
                                          : AppColors.primaryMedium,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 88,
        height: 88,
        color: AppColors.primarySurface,
        child: const Icon(
          Icons.fastfood_rounded,
          color: AppColors.primaryLight,
          size: 32,
        ),
      );
}
