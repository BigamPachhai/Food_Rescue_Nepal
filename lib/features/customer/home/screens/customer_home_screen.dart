import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
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

  static const _categories = ['All', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other'];

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

  void _enterSearch() {
    setState(() => _isSearchMode = true);
    FocusScope.of(context).requestFocus(FocusNode());
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: _isSearchMode
          ? _SearchOverlay(
              controller: _searchCtrl,
              onBack: _exitSearch,
              onCategoryTap: (cat) {
                setState(() {
                  _selectedCategory = cat;
                  _isSearchMode = false;
                });
                ref.read(listingsProvider.notifier).filterByCategory(cat);
              },
            )
          : RefreshIndicator(
              color: AppColors.primaryMedium,
              onRefresh: () => ref.read(listingsProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader(context, unreadCount)),
                  // Search bar
                  SliverToBoxAdapter(
                    child: _buildSearchBar(filter.hasActiveFilters, filter),
                  ),
                  // Category chips
                  SliverToBoxAdapter(child: _buildCategoryChips()),
                  // Featured section
                  SliverToBoxAdapter(child: _buildFeaturedSection()),
                  // Popular vendors section
                  SliverToBoxAdapter(child: _buildPopularVendorsSection()),
                  // Main feed header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                      child: Row(
                        children: [
                          Text('Nearby Offers 🌿', style: AppTextStyles.h4),
                          const Spacer(),
                          _SortButton(
                            currentSort: filter.sortBy,
                            onSortChanged: (s) {
                              ref.read(listingsProvider.notifier).applyFilter(
                                    filter.copyWith(sortBy: s),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Main listings
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
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == listings.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryMedium),
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
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ShimmerCard(height: 100),
                        ),
                        childCount: 4,
                      ),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.read(listingsProvider.notifier).refresh(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
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
          const Icon(Icons.location_on, color: Colors.white70, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Kathmandu, Nepal',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
                          fontSize: 9,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _enterSearch,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text('Search food, vendors…', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          GestureDetector(
            onTap: () => _showFilterSheet(filter),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasFilters ? AppColors.primaryMedium : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune,
                    color: hasFilters ? Colors.white : AppColors.textPrimary,
                    size: 20,
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
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = cat);
                ref.read(listingsProvider.notifier).filterByCategory(cat == 'All' ? null : cat);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryMedium,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: isSelected ? AppColors.primaryMedium : const Color(0xFFDDDDDD),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text('🔥 Featured Deals', style: AppTextStyles.h4),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(listingsProvider.notifier).applyFilter(
                            const ListingsFilter(sortBy: 'discount'),
                          );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: listings.length,
                itemBuilder: (_, i) => _FeaturedCard(
                  listing: listings[i],
                  onTap: () => context.push('/customer/listing/${listings[i].id}'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔥 Featured Deals', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            const ShimmerCard(height: 200),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text('⭐ Popular Vendors', style: AppTextStyles.h4),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: featured.length,
                itemBuilder: (_, i) => _VendorChip(vendor: featured[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          width: 160,
                          height: 110,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 160,
                            height: 110,
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.fastfood, color: AppColors.primaryLight, size: 36),
                          ),
                        )
                      : Container(
                          width: 160,
                          height: 110,
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.fastfood, color: AppColors.primaryLight, size: 36),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: DiscountBadge(percent: listing.discountPercent),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.name,
                      style: AppTextStyles.h6,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        Formatters.formatNPR(listing.discountedPrice),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatNPR(listing.originalPrice),
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${listing.availableQty} left',
                    style: AppTextStyles.caption.copyWith(
                      color: listing.availableQty <= 3 ? AppColors.error : AppColors.textSecondary,
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
}

// ─── Vendor Chip ───────────────────────────────────────────────────────────

class _VendorChip extends StatelessWidget {
  const _VendorChip({required this.vendor});
  final VendorEntity vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: vendor.logoUrl != null
                ? CachedNetworkImageProvider(vendor.logoUrl!)
                : null,
            child: vendor.logoUrl == null
                ? const Icon(Icons.store, color: AppColors.primaryLight, size: 24)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            vendor.businessName,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 10, color: AppColors.accentAmber),
              const SizedBox(width: 2),
              Text(vendor.avgRating.toStringAsFixed(1), style: AppTextStyles.caption),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort By', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              ..._sorts.entries.map(
                (e) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSortChanged(e.key);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          currentSort == e.key
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: currentSort == e.key
                              ? AppColors.primaryMedium
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 14, color: AppColors.primaryMedium),
            const SizedBox(width: 4),
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

  static const _categories = ['All', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other'];

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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReset();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text('Filters & Sort', style: AppTextStyles.h4),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort
                    const _SectionLabel(label: 'Sort By'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: {
                        'newest': 'Latest',
                        'discount': 'Best Discount',
                        'price_asc': 'Lowest Price',
                        'price_desc': 'Highest Price',
                        'popular': 'Most Popular',
                        'nearest': 'Nearest First',
                      }.entries.map((e) {
                        final selected = _sortBy == e.key;
                        return ChoiceChip(
                          label: Text(e.value),
                          selected: selected,
                          onSelected: (_) => setState(() => _sortBy = e.key),
                          selectedColor: AppColors.primaryMedium,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Category
                    const _SectionLabel(label: 'Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final selected = (_category ?? 'All') == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (_) => setState(() => _category = c),
                          selectedColor: AppColors.primaryMedium,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Price range
                    Row(
                      children: [
                        const _SectionLabel(label: 'Price Range (NPR)'),
                        const Spacer(),
                        Text(
                          '${_priceRange.start.toInt()} – ${_priceRange.end >= _maxPriceValue ? 'Any' : _priceRange.end.toInt()}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _maxPriceValue,
                      divisions: 50,
                      activeColor: AppColors.primaryMedium,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                    const SizedBox(height: 16),
                    // Max distance
                    Row(
                      children: [
                        const _SectionLabel(label: 'Max Distance'),
                        const Spacer(),
                        Text(
                          _maxDistance >= _maxDistanceValue ? 'Any' : '${_maxDistance.toInt()} km',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1,
                      max: _maxDistanceValue,
                      divisions: 49,
                      activeColor: AppColors.primaryMedium,
                      onChanged: (v) => setState(() => _maxDistance = v),
                    ),
                    const SizedBox(height: 16),
                    // Min rating
                    Row(
                      children: [
                        const _SectionLabel(label: 'Vendor Rating'),
                        const Spacer(),
                        Text(
                          _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium),
                        ),
                      ],
                    ),
                    Row(
                      children: [0.0, 3.0, 3.5, 4.0, 4.5].map((r) {
                        final selected = _minRating == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _minRating = r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primaryMedium : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.primaryMedium : const Color(0xFFDDDDDD),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (r > 0)
                                    Icon(Icons.star, size: 12,
                                        color: selected ? Colors.white : AppColors.accentAmber),
                                  if (r > 0) const SizedBox(width: 2),
                                  Text(
                                    r == 0 ? 'Any' : r.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Availability
                    Row(
                      children: [
                        const _SectionLabel(label: 'Availability'),
                        const Spacer(),
                        Switch(
                          value: _onlyAvailable,
                          onChanged: (v) => setState(() => _onlyAvailable = v),
                          activeThumbColor: AppColors.primaryMedium,
                          activeTrackColor: AppColors.primaryLight,
                        ),
                      ],
                    ),
                    Text('Only show in-stock listings', style: AppTextStyles.caption),
                    const SizedBox(height: 24),
                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final cat = (_category == null || _category == 'All') ? null : _category;
                          widget.onApply(ListingsFilter(
                            category: cat,
                            sortBy: _sortBy,
                            minPrice: _priceRange.start > 0
                                ? (_priceRange.start * 100).toInt()
                                : null,
                            maxPrice: _priceRange.end < _maxPriceValue
                                ? (_priceRange.end * 100).toInt()
                                : null,
                            maxDistance: _maxDistance < _maxDistanceValue ? _maxDistance : null,
                            minRating: _minRating > 0 ? _minRating : null,
                            onlyAvailable: _onlyAvailable,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMedium,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
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
  String _tab = 'food'; // 'food' | 'vendors'
  List<VendorEntity> _vendorResults = [];
  bool _loading = false;

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

    // Food search via listingsProvider
    ref.read(listingsProvider.notifier).search(q);

    // Vendor search from cached publicVendorsProvider data
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

  static const _cats = ['Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other'];
  static const _catIcons = [
    Icons.bakery_dining,
    Icons.restaurant,
    Icons.coffee,
    Icons.shopping_basket,
    Icons.cake,
    Icons.fastfood,
  ];

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final query = widget.controller.text.trim();
    final hasQuery = query.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search input row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.primarySurface,
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        suffixIcon: hasQuery
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => widget.controller.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasQuery)
              // Tab bar: Food / Vendors
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              Icon(icon, size: 16, color: selected ? AppColors.primaryMedium : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.primaryMedium : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No food listings found'),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ShimmerCard(height: 90),
        ),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildVendorResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryMedium));
    }
    if (_vendorResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No vendors found'),
        ),
      );
    }
    return ListView.builder(
      itemCount: _vendorResults.length,
      itemBuilder: (_, i) {
        final v = _vendorResults[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            backgroundImage:
                v.logoUrl != null ? CachedNetworkImageProvider(v.logoUrl!) : null,
            child: v.logoUrl == null
                ? const Icon(Icons.store, color: AppColors.primaryLight)
                : null,
          ),
          title: Text(v.businessName, style: AppTextStyles.h6),
          subtitle: Text(v.businessType, style: AppTextStyles.caption),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 13, color: AppColors.accentAmber),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse Categories', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onCategoryTap(_cats[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_catIcons[i], color: AppColors.primaryMedium, size: 28),
                    const SizedBox(height: 6),
                    Text(_cats[i], style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
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

// ─── Listing Card (public, reused) ─────────────────────────────────────────

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final ListingEntity listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: listing.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.imageUrls.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.primarySurface,
                                width: 80,
                                height: 80,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primarySurface,
                                width: 80,
                                height: 80,
                                child: const Icon(Icons.fastfood, color: AppColors.primaryLight),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fastfood, color: AppColors.primaryLight, size: 32),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: DiscountBadge(percent: listing.discountPercent),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
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
                        Text(listing.vendor!.businessName, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: AppColors.accentAmber),
                          const SizedBox(width: 2),
                          Text(
                            listing.vendor?.avgRating.toStringAsFixed(1) ?? '0.0',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
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
                        children: [
                          Text(
                            Formatters.formatNPR(listing.originalPrice),
                            style: AppTextStyles.caption.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatNPR(listing.discountedPrice),
                            style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              Formatters.formatPickupTime(listing.pickupStart, listing.pickupEnd),
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: listing.availableQty > 0
                                  ? AppColors.primarySurface
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${listing.availableQty} left',
                              style: AppTextStyles.caption.copyWith(
                                color: listing.availableQty > 0
                                    ? AppColors.primaryMedium
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

