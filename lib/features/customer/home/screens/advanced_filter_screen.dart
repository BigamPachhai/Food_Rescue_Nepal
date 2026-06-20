import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class FilterOptions {
  final RangeValues priceRange;
  final List<String> categories;
  final List<String> dietaryTags;
  final double maxDistanceKm;
  final bool openNow;
  final bool hasDiscount;
  final String sortBy;

  const FilterOptions({
    this.priceRange = const RangeValues(0, 2000),
    this.categories = const [],
    this.dietaryTags = const [],
    this.maxDistanceKm = 10,
    this.openNow = false,
    this.hasDiscount = false,
    this.sortBy = 'distance',
  });

  FilterOptions copyWith({
    RangeValues? priceRange,
    List<String>? categories,
    List<String>? dietaryTags,
    double? maxDistanceKm,
    bool? openNow,
    bool? hasDiscount,
    String? sortBy,
  }) => FilterOptions(
    priceRange: priceRange ?? this.priceRange,
    categories: categories ?? this.categories,
    dietaryTags: dietaryTags ?? this.dietaryTags,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    openNow: openNow ?? this.openNow,
    hasDiscount: hasDiscount ?? this.hasDiscount,
    sortBy: sortBy ?? this.sortBy,
  );
}

class AdvancedFilterScreen extends StatefulWidget {
  final FilterOptions initial;
  const AdvancedFilterScreen({super.key, required this.initial});

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen> {
  late FilterOptions _opts;

  static const _allCategories = ['Surprise Bag', 'Bakery', 'Restaurant', 'Cafe', 'Grocery', 'Sweets', 'Other'];
  static const _allDietary = ['Vegetarian', 'Vegan', 'Halal', 'Gluten-Free', 'Dairy-Free', 'Nut-Free', 'Spicy', 'Non-Spicy'];
  static const _sortOptions = [
    ('distance', 'Nearest First'),
    ('price_asc', 'Price: Low to High'),
    ('price_desc', 'Price: High to Low'),
    ('discount', 'Best Discount'),
    ('newest', 'Newest First'),
    ('rating', 'Highest Rated'),
  ];

  @override
  void initState() {
    super.initState();
    _opts = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Advanced Filters'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _opts = const FilterOptions()),
            child: const Text('Reset'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _opts),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Sort By', _buildSortBy()),
          _Section('Price Range (Rs.)', _buildPriceRange()),
          _Section('Distance (km)', _buildDistance()),
          _Section('Categories', _buildCategories()),
          _Section('Dietary Requirements', _buildDietary()),
          _Section('Quick Filters', _buildQuickFilters()),
        ],
      ),
    );
  }

  Widget _buildSortBy() => RadioGroup<String>(
    groupValue: _opts.sortBy,
    onChanged: (v) => setState(() => _opts = _opts.copyWith(sortBy: v)),
    child: Column(
      children: _sortOptions.map((opt) => RadioListTile<String>(
        title: Text(opt.$2, style: AppTextStyles.bodyMedium),
        value: opt.$1,
        activeColor: AppColors.primaryMedium,
        contentPadding: EdgeInsets.zero,
      )).toList(),
    ),
  );

  Widget _buildPriceRange() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Rs. ${_opts.priceRange.start.toInt()}', style: AppTextStyles.label),
          Text('Rs. ${_opts.priceRange.end.toInt()}', style: AppTextStyles.label),
        ],
      ),
      RangeSlider(
        values: _opts.priceRange,
        min: 0, max: 2000,
        divisions: 40,
        activeColor: AppColors.primaryMedium,
        onChanged: (v) => setState(() => _opts = _opts.copyWith(priceRange: v)),
      ),
    ],
  );

  Widget _buildDistance() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Up to ${_opts.maxDistanceKm.toInt()} km', style: AppTextStyles.label),
        ],
      ),
      Slider(
        value: _opts.maxDistanceKm,
        min: 1, max: 50,
        divisions: 49,
        activeColor: AppColors.primaryMedium,
        label: '${_opts.maxDistanceKm.toInt()} km',
        onChanged: (v) => setState(() => _opts = _opts.copyWith(maxDistanceKm: v)),
      ),
    ],
  );

  Widget _buildCategories() => Wrap(
    spacing: 8, runSpacing: 8,
    children: _allCategories.map((cat) {
      final selected = _opts.categories.contains(cat);
      return FilterChip(
        label: Text(cat),
        selected: selected,
        selectedColor: AppColors.primaryMedium.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primaryDark,
        onSelected: (v) {
          final list = [..._opts.categories];
          if (v) { list.add(cat); } else { list.remove(cat); }
          setState(() => _opts = _opts.copyWith(categories: list));
        },
      );
    }).toList(),
  );

  Widget _buildDietary() => Wrap(
    spacing: 8, runSpacing: 8,
    children: _allDietary.map((tag) {
      final selected = _opts.dietaryTags.contains(tag);
      return FilterChip(
        label: Text(tag),
        selected: selected,
        selectedColor: Colors.green.withValues(alpha: 0.2),
        checkmarkColor: Colors.green.shade700,
        onSelected: (v) {
          final list = [..._opts.dietaryTags];
          if (v) { list.add(tag); } else { list.remove(tag); }
          setState(() => _opts = _opts.copyWith(dietaryTags: list));
        },
      );
    }).toList(),
  );

  Widget _buildQuickFilters() => Column(
    children: [
      SwitchListTile(
        title: Text('Available Now', style: AppTextStyles.bodyMedium),
        subtitle: Text('Show only listings with pickup available now', style: AppTextStyles.caption),
        value: _opts.openNow,
        activeThumbColor: AppColors.primaryMedium,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _opts = _opts.copyWith(openNow: v)),
      ),
      SwitchListTile(
        title: Text('Discounted Items Only', style: AppTextStyles.bodyMedium),
        subtitle: Text('Show listings with significant discounts', style: AppTextStyles.caption),
        value: _opts.hasDiscount,
        activeThumbColor: AppColors.primaryMedium,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _opts = _opts.copyWith(hasDiscount: v)),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section(this.title, this.child);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.h5),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: child,
      ),
      const SizedBox(height: 16),
    ],
  );
}
