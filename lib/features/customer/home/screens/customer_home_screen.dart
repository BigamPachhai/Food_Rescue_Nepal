import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/widgets/verified_badge.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/listings_provider.dart';
import '../providers/location_provider.dart';

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
  bool _showScrollTop = false;

  static const _categories = [
    'All', 'Surprise Bag', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other',
  ];

  static const _categoryIcons = {
    'All': Icons.grid_view_rounded,
    'Surprise Bag': Icons.card_giftcard_rounded,
    'Bakery': Icons.bakery_dining_rounded,
    'Restaurant': Icons.restaurant_rounded,
    'Cafe': Icons.coffee_rounded,
    'Grocery': Icons.shopping_basket_rounded,
    'Sweets': Icons.cake_rounded,
    'Other': Icons.fastfood_rounded,
  };

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    Future.microtask(
      () => ref.read(locationProvider.notifier).getCurrentLocation(),
    );
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
    final shouldShow = _scrollCtrl.position.pixels > 400;
    if (shouldShow != _showScrollTop) setState(() => _showScrollTop = shouldShow);
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
    final locationLabel = ref.watch(locationProvider).label;

    ref.listen<LocationState>(locationProvider, (prev, next) {
      final pos = next.position.value;
      if (pos == null) return;
      final prevPos = prev?.position.value;
      if (prevPos?.latitude == pos.latitude && prevPos?.longitude == pos.longitude) return;
      final notifier = ref.read(listingsProvider.notifier);
      notifier.applyFilter(notifier.currentFilter.copyWith(
        userLat: pos.latitude,
        userLng: pos.longitude,
      ));
    });

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _showScrollTop ? Offset.zero : const Offset(0, 2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showScrollTop ? 1 : 0,
              child: FloatingActionButton.small(
                heroTag: 'scrollTop',
                onPressed: () => _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                backgroundColor: AppColors.primaryMedium,
                child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'aiChat',
            onPressed: () => context.push('/ai/chat'),
            backgroundColor: AppColors.primaryMedium,
            tooltip: 'AI Food Assistant',
            child: const Icon(Icons.psychology_rounded, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          final messenger = ScaffoldMessenger.of(context);
          await ref.read(listingsProvider.notifier).refresh();
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Feed refreshed')),
          );
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, unreadCount, locationLabel)),
            SliverToBoxAdapter(child: _buildSearchBar(filter.hasActiveFilters, filter)),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildLastCallSection()),
            SliverToBoxAdapter(child: _buildPopularVendors()),
            SliverToBoxAdapter(child: _buildFeaturedSection()),
            SliverToBoxAdapter(child: _buildFeedHeader(filter)),
            listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  final hasFilters = filter.hasActiveFilters;
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
                      child: EmptyStateView(
                        icon: hasFilters
                            ? Icons.filter_list_off_rounded
                            : Icons.fastfood_outlined,
                        title: hasFilters
                            ? 'No results for these filters'
                            : 'No listings nearby',
                        subtitle: hasFilters
                            ? 'Try widening your search or clearing filters.'
                            : 'More vendors are joining every week. Explore the map to see what\'s available near you.',
                        ctaLabel: hasFilters ? 'Clear Filters' : 'Explore the Map',
                        onCtaTap: hasFilters
                            ? () {
                                ref.read(listingsProvider.notifier).resetFilters();
                                setState(() => _selectedCategory = 'All');
                              }
                            : () => context.go('/customer/map'),
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
                        showFavorite: false,
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
                    child: ShimmerCard(height: 108),
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

  Widget _buildHeader(BuildContext context, int unreadCount, String locationLabel) {
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
            child: GestureDetector(
              onTap: () => _showLocationPicker(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rescue food near',
                    style: AppTextStyles.caption.copyWith(color: Colors.white60),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(locationLabel, style: AppTextStyles.h5OnPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70, size: 22),
            onPressed: () => context.push('/how-it-works'),
            tooltip: 'How it works',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
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
      padding: const EdgeInsets.fromLTRB(AppSizes.s4, 0, AppSizes.s4, AppSizes.s4),
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
                    const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: AppSizes.iconMd),
                    const SizedBox(width: AppSizes.s2),
                    Text(
                      'Search food, vendors…',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
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
      height: 56,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFFF7F8F7),
            Colors.transparent,
            Colors.transparent,
            Color(0xFFF7F8F7),
          ],
          stops: [0.0, 0.06, 0.92, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstOut,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s2),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final isSelected = cat == _selectedCategory;
            final icon = _categoryIcons[cat] ?? Icons.category_rounded;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.s2),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                  ref.read(listingsProvider.notifier)
                      .filterByCategory(cat == 'All' ? null : cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: AppSizes.s1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryMedium : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryMedium : AppColors.border,
                    ),
                    boxShadow: isSelected ? AppShadows.sm : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: AppSizes.s1),
                      Text(
                        cat,
                        style: AppTextStyles.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLastCallSection() {
    final listingsAsync = ref.watch(listingsProvider);
    final listings = listingsAsync.value ?? [];
    final now = DateTime.now();
    final lastCall = listings
        .where((l) =>
            l.availableQty > 0 &&
            l.pickupEnd.isAfter(now) &&
            l.pickupEnd.difference(now).inMinutes <= 60)
        .toList();
    if (lastCall.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, AppSizes.s2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('LAST CALL',
                        style: AppTextStyles.overline.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s2),
              Text('Closing within the hour', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
            itemCount: lastCall.length,
            itemBuilder: (_, i) {
              final l = lastCall[i];
              final minsLeft = l.pickupEnd.difference(now).inMinutes;
              return GestureDetector(
                onTap: () => context.push('/customer/listing/${l.id}'),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: AppSizes.s2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    boxShadow: AppShadows.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.s2),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          child: l.imageUrls.isNotEmpty
                              ? CachedNetworkImage(imageUrl: l.imageUrls.first, width: 72, height: 72, fit: BoxFit.cover)
                              : Container(width: 72, height: 72, color: AppColors.primarySurface,
                                  child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryLight, size: 28)),
                        ),
                        const SizedBox(width: AppSizes.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l.name, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Text(
                                Formatters.formatNPR(l.discountedPrice),
                                style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorSurface,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_rounded, size: 10, color: AppColors.error),
                                    const SizedBox(width: 3),
                                    Text('${minsLeft}m left',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.s2),
      ],
    );
  }

  Widget _buildPopularVendors() {
    final topAsync = ref.watch(topVendorsProvider);
    return topAsync.when(
      data: (vendors) {
        if (vendors.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s3),
              child: Row(
                children: [
                  Text('Popular Vendors', style: AppTextStyles.h4),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/customer/map'),
                    child: Row(
                      children: [
                        Text(
                          'See all',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.primaryMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                itemCount: vendors.length,
                itemBuilder: (_, i) {
                  final v = vendors[i];
                  if (v.id.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => context.push('/customer/vendor/${v.id}'),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: AppSizes.s3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
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
                                      memCacheWidth: 112,
                                      memCacheHeight: 112,
                                      errorWidget: (_, __, ___) => const Icon(
                                          Icons.store_rounded,
                                          color: AppColors.primaryLight,
                                          size: 24),
                                    )
                                  : const Icon(Icons.store_rounded,
                                      color: AppColors.primaryLight, size: 24),
                            ),
                          ),
                          const SizedBox(height: AppSizes.s1),
                          Text(
                            v.businessName,
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 10, color: AppColors.accentAmber),
                              const SizedBox(width: 2),
                              Text(
                                v.avgRating.toStringAsFixed(1),
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

  Widget _buildFeaturedSection() {
    final featuredAsync = ref.watch(featuredListingsProvider);
    return featuredAsync.when(
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();
        final cardW = Responsive.featuredCardWidth(context);
        final imageH = (cardW * 0.68).roundToDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Featured Deals', style: AppTextStyles.h4),
                          const SizedBox(width: AppSizes.s2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text('HOT', style: AppTextStyles.overline.copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text("Save big on today's surplus", style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(listingsProvider.notifier)
                        .applyFilter(const ListingsFilter(sortBy: 'discount')),
                    child: Row(
                      children: [
                        Text('See all', style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: imageH + 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                itemCount: listings.length,
                itemBuilder: (_, i) => _FeaturedCard(
                  listing: listings[i],
                  onTap: () => context.push('/customer/listing/${listings[i].id}'),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s2),
          ],
        );
      },
      loading: () {
        final cardW = Responsive.featuredCardWidth(context);
        final imageH = (cardW * 0.68).roundToDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Featured Deals', style: AppTextStyles.h4),
                  const SizedBox(height: 2),
                  Text("Save big on today's surplus", style: AppTextStyles.caption),
                ],
              ),
            ),
            SizedBox(
              height: imageH + 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                itemCount: 3,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s3),
                  child: SizedBox(
                    width: cardW,
                    child: ShimmerCard(height: imageH + 96, margin: EdgeInsets.zero),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s2),
          ],
        );
      },
      error: (e, __) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(featuredListingsProvider),
      ),
    );
  }

  Widget _buildFeedHeader(ListingsFilter filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s2, AppSizes.s2, AppSizes.s2),
      child: Row(
        children: [
          Text('Nearby Offers', style: AppTextStyles.h4),
          const Spacer(),
          _SortButton(
            currentSort: filter.sortBy,
            onSortChanged: (s) => ref.read(listingsProvider.notifier)
                .applyFilter(filter.copyWith(sortBy: s)),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    final cityCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusBottomSheet)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, AppSizes.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Text('Set Your Location', style: AppTextStyles.h4),
              const SizedBox(height: AppSizes.s4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(locationProvider.notifier).getCurrentLocation();
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Use my current location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s3),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
                  child: Text('or enter city', style: AppTextStyles.caption),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSizes.s3),
              TextField(
                controller: cityCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Pokhara, Lalitpur…',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onSubmitted: (val) {
                  final city = val.trim();
                  if (city.isNotEmpty) {
                    ref.read(locationProvider.notifier).setManualCity(city);
                    Navigator.pop(ctx);
                  }
                },
              ),
              const SizedBox(height: AppSizes.s3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final city = cityCtrl.text.trim();
                    if (city.isNotEmpty) {
                      ref.read(locationProvider.notifier).setManualCity(city);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
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
        margin: const EdgeInsets.only(right: AppSizes.s3, bottom: AppSizes.s1),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusCard)),
                  child: listing.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          width: cardW,
                          height: imageH,
                          fit: BoxFit.cover,
                          memCacheWidth: (cardW * 1.5).toInt(),
                          memCacheHeight: (imageH * 1.5).toInt(),
                          errorWidget: (_, __, ___) => _placeholder(cardW, imageH),
                        )
                      : _placeholder(cardW, imageH),
                ),
                // Gradient scrim so pickup badge is legible
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusCard)),
                    child: Container(
                      height: imageH * 0.4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black45],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.s2,
                  left: AppSizes.s2,
                  child: DiscountBadge(percent: listing.discountPercent),
                ),
                // Pickup window stamped on the image
                Positioned(
                  bottom: AppSizes.s2,
                  right: AppSizes.s2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 9, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          Formatters.formatPickupTime(listing.pickupStart, listing.pickupEnd),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s2, AppSizes.s3, AppSizes.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.name, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        Formatters.formatNPR(listing.discountedPrice),
                        style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                      ),
                      const SizedBox(width: AppSizes.s1),
                      Text(
                        Formatters.formatNPR(listing.originalPrice),
                        style: AppTextStyles.caption.copyWith(decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: listing.availableQty <= 3 ? AppColors.warningSurface : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '${listing.availableQty} left',
                      style: AppTextStyles.caption.copyWith(
                        color: listing.availableQty <= 3 ? AppColors.warning : AppColors.primaryMedium,
                        fontWeight: FontWeight.w600,
                      ),
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
        child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryLight, size: 36),
      );
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusBottomSheet)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s4, AppSizes.s4, AppSizes.s8),
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
                          color: currentSort == e.key ? AppColors.primaryMedium : AppColors.neutral300,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.primaryMedium),
            const SizedBox(width: AppSizes.s1),
            Text(
              _sorts[currentSort] ?? 'Sort',
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
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
    'All', 'Surprise Bag', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusBottomSheet)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
                          style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
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
                          _maxDistance >= _maxDistanceValue ? 'Any' : '${_maxDistance.toInt()} km',
                          style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
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
                          _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
                          style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Wrap(
                      spacing: AppSizes.s2,
                      children: [0.0, 3.0, 3.5, 4.0, 4.5]
                          .map((r) => _ChoiceChip(
                                label: r == 0 ? 'Any' : '⭐ ${r.toStringAsFixed(1)}+',
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
                          onChanged: (v) => setState(() => _onlyAvailable = v),
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
                          final cat = (_category == null || _category == 'All') ? null : _category;
                          widget.onApply(ListingsFilter(
                            category: cat,
                            sortBy: _sortBy,
                            minPrice: _priceRange.start > 0 ? (_priceRange.start * 100).toInt() : null,
                            maxPrice: _priceRange.end < _maxPriceValue ? (_priceRange.end * 100).toInt() : null,
                            maxDistance: _maxDistance < _maxDistanceValue ? _maxDistance : null,
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
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMedium : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: selected ? AppColors.primaryMedium : AppColors.border),
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
  Timer? _debounce;

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
  static const _catBgColors = [
    Color(0xFFFFF8E1),
    Color(0xFFFFEBEE),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFFBE9E7),
  ];
  static const _catIconColors = [
    Color(0xFFFF8F00),
    Color(0xFFD32F2F),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFBF360C),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = widget.controller.text.trim();
    if (q.isEmpty) {
      setState(() { _vendorResults = []; _loading = false; });
      ref.read(listingsProvider.notifier).search('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(q));
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
              padding: const EdgeInsets.fromLTRB(AppSizes.s2, AppSizes.s2, AppSizes.s4, AppSizes.s2),
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
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.neutral50,
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        suffixIcon: hasQuery
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.textSecondary,
                                onPressed: () => widget.controller.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  ? (_tab == 'food' ? _buildFoodResults(listingsAsync) : _buildVendorResults())
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
              Icon(icon, size: 16, color: selected ? AppColors.primaryMedium : AppColors.textSecondary),
              const SizedBox(width: AppSizes.s1),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? AppColors.primaryMedium : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.neutral300),
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
          padding: EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s1),
          child: ShimmerCard(height: 90),
        ),
      ),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(listingsProvider)),
    );
  }

  Widget _buildVendorResults() {
    if (_loading) {
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s1),
          child: ShimmerCard(height: 72),
        ),
      );
    }
    if (_vendorResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.neutral300),
              const SizedBox(height: AppSizes.s3),
              Text('No vendors found', style: AppTextStyles.h5),
              const SizedBox(height: AppSizes.s1),
              Text('Try a different name or category', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _vendorResults.length,
      itemBuilder: (_, i) {
        final v = _vendorResults[i];
        return GestureDetector(
          onTap: () {
            widget.onBack();
            context.push('/customer/vendor/${v.id}');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s1),
            padding: const EdgeInsets.all(AppSizes.s3),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                            errorWidget: (_, __, ___) => const Icon(Icons.store_rounded, color: AppColors.primaryLight),
                          )
                        : const Icon(Icons.store_rounded, color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(v.businessName, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (v.status == 'APPROVED') ...[
                            const SizedBox(width: 3),
                            const VerifiedBadge(size: 11),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(v.businessType, style: AppTextStyles.caption),
                      if (v.address != null && v.address!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                v.address!,
                                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.accentAmber),
                        const SizedBox(width: 2),
                        Text(v.avgRating.toStringAsFixed(1), style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                  ],
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 4),
          Text('Tap a category to explore deals', style: AppTextStyles.caption),
          const SizedBox(height: AppSizes.s4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.gridColumns(context, mobile: 3, tablet: 5),
              mainAxisSpacing: AppSizes.s3,
              crossAxisSpacing: AppSizes.s3,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onCategoryTap(_cats[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: _catBgColors[i],
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: _catBgColors[i].withValues(alpha: 0.6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _catIconColors[i].withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_catIcons[i], color: _catIconColors[i], size: 22),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      _cats[i],
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _catIconColors[i],
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

class ListingCard extends ConsumerStatefulWidget {
  const ListingCard({super.key, required this.listing, required this.onTap, this.showFavorite = true});

  final ListingEntity listing;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  bool _togglingFav = false;

  Future<void> _toggleFavorite() async {
    if (_togglingFav) return;
    HapticFeedback.lightImpact();
    setState(() => _togglingFav = true);
    final messenger = ScaffoldMessenger.of(context);
    final added = await ref.read(favoritesProvider.notifier).toggle(widget.listing.id);
    if (!mounted) return;
    setState(() => _togglingFav = false);
    messenger.showSnackBar(SnackBar(
      content: Text(added ? 'Added to favorites' : 'Removed from favorites'),
      duration: const Duration(seconds: 2),
    ));
  }

  ({String label, Color color, Color bgColor})? _urgency() {
    if (widget.listing.availableQty == 0) return null;
    final now = DateTime.now();
    final minutesLeft = widget.listing.pickupEnd.difference(now).inMinutes;
    if (minutesLeft <= 0) return null;
    if (minutesLeft <= 30) {
      return (label: 'Last chance!', color: AppColors.error, bgColor: AppColors.errorSurface);
    }
    if (minutesLeft <= 120) {
      return (label: 'Closing soon', color: AppColors.warning, bgColor: AppColors.warningSurface);
    }
    final isToday = widget.listing.pickupEnd.day == now.day &&
        widget.listing.pickupEnd.month == now.month &&
        widget.listing.pickupEnd.year == now.year;
    if (isToday) {
      return (label: 'Pickup today', color: AppColors.primaryMedium, bgColor: AppColors.primarySurface);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final isLowStock = listing.availableQty > 0 && listing.availableQty <= 3;
    final isSoldOut = listing.availableQty == 0;
    final isFav = ref.watch(
      favoritesProvider.select(
        (async) => async.value?.any((f) => f.id == listing.id) ?? listing.isFavorite,
      ),
    );
    final urgency = _urgency();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s1),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          splashColor: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail: 96x96 with sold-out overlay + badges ────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: listing.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.imageUrls.first,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(width: 96, height: 96, color: AppColors.primarySurface),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    // "New" badge for listings posted in the last 2 hours
                    if (listing.createdAt != null &&
                        DateTime.now().difference(listing.createdAt!).inHours < 2 &&
                        !isSoldOut)
                      Positioned(
                        bottom: AppSizes.s1,
                        left: AppSizes.s1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    // Surprise Bag overlay icon
                    if (listing.category == 'SURPRISE_BAG')
                      Positioned(
                        bottom: AppSizes.s1,
                        right: AppSizes.s1,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Icon(Icons.card_giftcard_rounded, size: 11, color: Colors.white),
                        ),
                      ),
                    // Sold-out overlay
                    if (isSoldOut)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                ),
                                child: const Text(
                                  'SOLD OUT',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (listing.discountPercent > 0)
                      Positioned(
                        top: AppSizes.s1,
                        left: AppSizes.s1,
                        child: DiscountBadge(percent: listing.discountPercent),
                      ),
                    if (widget.showFavorite)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _toggleFavorite,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: _togglingFav
                                ? const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                  )
                                : Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 17,
                                    color: isFav ? Colors.red.shade400 : Colors.white,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSizes.s3),
                // ── Info column ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text(listing.name, style: AppTextStyles.h5, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (listing.vendor != null)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  listing.vendor!.businessName,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (listing.vendor!.status == 'APPROVED') ...[
                                const SizedBox(width: 3),
                                const VerifiedBadge(size: 11),
                              ],
                            ],
                          ),
                        if (listing.category.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              Formatters.formatCategory(listing.category),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.accentAmber),
                            const SizedBox(width: 2),
                            Text(listing.vendor?.avgRating.toStringAsFixed(1) ?? '—', style: AppTextStyles.caption),
                            const SizedBox(width: AppSizes.s2),
                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                listing.distance != null ? '${listing.distance!.toStringAsFixed(1)} km' : '—',
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (urgency != null) ...[
                              const SizedBox(width: AppSizes.s1),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: urgency.bgColor,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                  ),
                                  child: Text(
                                    urgency.label,
                                    style: AppTextStyles.caption.copyWith(
                                      color: urgency.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ] else if (!isSoldOut && listing.availableQty > 0) ...[
                              const SizedBox(width: AppSizes.s1),
                              _CountdownChip(pickupEnd: listing.pickupEnd),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              Formatters.formatNPR(listing.discountedPrice),
                              style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                            ),
                            const SizedBox(width: AppSizes.s1),
                            Text(
                              Formatters.formatNPR(listing.originalPrice),
                              style: AppTextStyles.caption.copyWith(decoration: TextDecoration.lineThrough),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSoldOut
                                    ? AppColors.errorSurface
                                    : isLowStock
                                        ? AppColors.warningSurface
                                        : AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Text(
                                isSoldOut ? 'Sold out' : '${listing.availableQty} left',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 96,
        height: 96,
        color: AppColors.primarySurface,
        child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryLight, size: 32),
      );
}

// ─── Live countdown chip (shown on listing cards) ──────────────────────────

class _CountdownChip extends StatefulWidget {
  const _CountdownChip({required this.pickupEnd});
  final DateTime pickupEnd;

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  late Duration _remaining;
  Timer? _timer;

  Duration _timeLeft() {
    final d = widget.pickupEnd.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _remaining = _timeLeft();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _remaining = _timeLeft());
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
    final hours = _remaining.inHours;
    final mins = _remaining.inMinutes % 60;
    final isUrgent = _remaining.inMinutes <= 30;
    if (!isUrgent && hours > 3) return const SizedBox.shrink();
    final label = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final color = isUrgent ? AppColors.error : AppColors.warning;
    final bg = isUrgent ? AppColors.errorSurface : AppColors.warningSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 9, color: color),
          const SizedBox(width: 2),
          Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 9)),
        ],
      ),
    );
  }
}
