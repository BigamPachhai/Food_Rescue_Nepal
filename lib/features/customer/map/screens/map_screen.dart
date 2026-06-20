import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../home/providers/listings_provider.dart';
import '../../home/providers/location_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  List<VendorEntity> _vendors = [];
  List<VendorEntity> _filtered = [];
  final Map<String, double> _distancesM = {};
  bool _loading = true;
  String? _error;
  double _radius = 10;
  String _sort = 'distance'; // distance | rating | name
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _loadVendors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVendors({int attempt = 1}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.vendors);
      final data = response.data;
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else if (data is Map &&
          data['data'] is Map &&
          (data['data'] as Map)['vendors'] is List) {
        items = (data['data'] as Map)['vendors'] as List<dynamic>;
      } else {
        items = [];
      }
      final vendors = items
          .map((e) => VendorEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _vendors = vendors;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      // Auto-retry up to 3 times on timeout/network errors before showing error
      final isTransient = e.toString().contains('timed out') ||
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('network');
      if (isTransient && attempt < 3) {
        await Future.delayed(Duration(seconds: attempt * 2));
        if (mounted) _loadVendors(attempt: attempt + 1);
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    final userPos = ref.read(locationProvider).position.value;

    // Compute distances once
    if (userPos != null) {
      for (final v in _vendors) {
        if (v.lat != null && v.lng != null) {
          _distancesM[v.id] = Geolocator.distanceBetween(
            userPos.latitude, userPos.longitude, v.lat!, v.lng!,
          );
        }
      }
    }

    var result = _vendors.where((v) {
      final matchQuery = q.isEmpty ||
          v.businessName.toLowerCase().contains(q) ||
          v.businessType.toLowerCase().contains(q) ||
          (v.address?.toLowerCase().contains(q) ?? false);
      final distM = _distancesM[v.id];
      final matchRadius = (userPos == null || distM == null) ? true : distM <= _radius * 1000;
      return matchQuery && matchRadius;
    }).toList();

    // Apply sort
    switch (_sort) {
      case 'rating':
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      case 'name':
        result.sort((a, b) => a.businessName.compareTo(b.businessName));
      default: // distance
        result.sort((a, b) {
          final da = _distancesM[a.id] ?? double.infinity;
          final db = _distancesM[b.id] ?? double.infinity;
          return da.compareTo(db);
        });
    }

    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final hasLocation = locationState.position.value != null;
    final locationError = locationState.position.hasError;

    // Re-apply filter whenever location changes so distances update
    ref.listen(locationProvider, (prev, next) {
      if (next.position.value != prev?.position.value) {
        _applyFilter();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            if (locationError)
              Container(
                margin: const EdgeInsets.fromLTRB(AppSizes.s3, AppSizes.s2, AppSizes.s3, 0),
                padding: const EdgeInsets.all(AppSizes.s2),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_off_outlined, color: AppColors.warning, size: 16),
                    SizedBox(width: AppSizes.s2),
                    Expanded(
                      child: Text(
                        'Location unavailable. Enable location for distance-based results.',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            _buildRadiusRow(hasLocation),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryMedium,
                onRefresh: _loadVendors,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s4, AppSizes.s3, AppSizes.s2, AppSizes.s2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nearby Vendors',
                    style: AppTextStyles.h5OnPrimary),
                Text('Tap a vendor to browse their listings',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Text(
            '${_filtered.length} found',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 20),
            tooltip: 'Sort',
            onSelected: (v) { setState(() => _sort = v); _applyFilter(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'distance', child: Row(children: [
                if (_sort == 'distance') const Icon(Icons.check, size: 14, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('By distance'),
              ])),
              PopupMenuItem(value: 'rating', child: Row(children: [
                if (_sort == 'rating') const Icon(Icons.check, size: 14, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('By rating'),
              ])),
              PopupMenuItem(value: 'name', child: Row(children: [
                if (_sort == 'name') const Icon(Icons.check, size: 14, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('A – Z'),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryMedium,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s4, 0, AppSizes.s4, AppSizes.s3),
      child: TextField(
        controller: _searchCtrl,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search vendors or areas…',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppSizes.radiusFull),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildRadiusRow(bool hasLocation) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s4, AppSizes.s2, AppSizes.s4, 0),
      child: Row(
        children: [
          Icon(
            Icons.radar_rounded,
            size: 16,
            color: hasLocation
                ? AppColors.primaryMedium
                : AppColors.neutral400,
          ),
          const SizedBox(width: AppSizes.s2),
          Text(
            hasLocation
                ? 'Radius: ${_radius.toInt()} km'
                : 'Radius: ${_radius.toInt()} km (enable location)',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: hasLocation
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
          ),
          Expanded(
            child: Slider(
              value: _radius,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: hasLocation
                  ? AppColors.primaryMedium
                  : AppColors.neutral300,
              onChanged: (v) {
                setState(() => _radius = v);
                _applyFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primaryMedium),
      );
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 56, color: AppColors.neutral300),
                const SizedBox(height: AppSizes.s3),
                Text('Failed to load vendors', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.s1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s6),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                TextButton.icon(
                  onPressed: () { setState(() => _error = null); _loadVendors(); },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_vendors.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined,
                    size: 56, color: AppColors.neutral300),
                const SizedBox(height: AppSizes.s3),
                Text('No vendors yet', style: AppTextStyles.h5),
              ],
            ),
          ),
        ],
      );
    }
    if (_filtered.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 56,
                    color: AppColors.neutral300),
                const SizedBox(height: AppSizes.s3),
                Text('No vendors match your search',
                    style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.s1),
                Text(
                  'Try different keywords or increase the radius',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _VendorLocationTile(
        vendor: _filtered[i],
        distanceM: _distancesM[_filtered[i].id],
        onTap: () => context.push('/customer/vendor/${_filtered[i].id}'),
      ),
    );
  }
}

class _VendorLocationTile extends StatelessWidget {
  const _VendorLocationTile(
      {required this.vendor, required this.onTap, this.distanceM});
  final VendorEntity vendor;
  final VoidCallback onTap;
  final double? distanceM;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.s4, vertical: AppSizes.s1),
        padding: const EdgeInsets.all(AppSizes.s3),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius:
              BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(
                child: vendor.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: vendor.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.store_rounded,
                            color: AppColors.primaryLight),
                      )
                    : const Icon(Icons.store_rounded,
                        color: AppColors.primaryLight),
              ),
            ),
            const SizedBox(width: AppSizes.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor.businessName,
                          style: AppTextStyles.h6,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendor.status == 'APPROVED') ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 11),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(vendor.businessType,
                      style: AppTextStyles.caption),
                  if (vendor.address != null &&
                      vendor.address!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            vendor.address!,
                            style: AppTextStyles.caption
                                .copyWith(
                                    color:
                                        AppColors.textTertiary),
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
                    const Icon(Icons.star_rounded,
                        size: 13,
                        color: AppColors.accentAmber),
                    const SizedBox(width: 2),
                    Text(
                      vendor.avgRating.toStringAsFixed(1),
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (vendor.totalReviews > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${vendor.totalReviews} reviews',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10),
                  ),
                ],
                if (distanceM != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatDistance(distanceM!),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryMedium,
                        fontWeight: FontWeight.w600,
                        fontSize: 10),
                  ),
                ],
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
