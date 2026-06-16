import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../home/providers/listings_provider.dart';
import '../../home/providers/location_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  double _radius = 10;
  List<VendorEntity> _vendors = [];
  bool _loading = true;
  Position? _userPosition;

  static const _kathmandu = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.vendors);
      final data = response.data;
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else {
        items = [];
      }
      setState(() {
        _vendors = items
            .map((e) => VendorEntity.fromJson(e as Map<String, dynamic>))
            .where((v) => v.lat != null && v.lng != null)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load vendors: ${e.toString()}')),
      );
    }
  }

  Future<void> _goToMyLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
    final posState = ref.read(locationProvider);
    posState.position.when(
      data: (pos) {
        if (pos != null) {
          setState(() => _userPosition = pos);
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location. Enable location services.')),
          );
        }
      },
      loading: () {},
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location error. Check permissions.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _kathmandu,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.foodrescue.nepal',
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _vendors.map((v) {
                  return Marker(
                    point: LatLng(v.lat!, v.lng!),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showVendorSheet(v),
                      child: const CircleAvatar(
                        backgroundColor: AppColors.primaryMedium,
                        child: Icon(Icons.store, color: Colors.white, size: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          // Top overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Search area...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                    Row(
                      children: [
                        Text('Radius: ${_radius.toInt()} km',
                            style: AppTextStyles.caption),
                        Expanded(
                          child: Slider(
                            value: _radius,
                            min: 5,
                            max: 20,
                            divisions: 3,
                            activeColor: AppColors.primaryMedium,
                            onChanged: (v) => setState(() => _radius = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryMedium),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: AppColors.primaryMedium,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _showVendorSheet(VendorEntity vendor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  radius: 24,
                  backgroundImage: vendor.logoUrl != null
                      ? NetworkImage(vendor.logoUrl!)
                      : null,
                  child: vendor.logoUrl == null
                      ? const Icon(Icons.store, color: AppColors.primaryLight)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.businessName, style: AppTextStyles.h5),
                      Text(vendor.businessType, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.accentAmber),
                    const SizedBox(width: 2),
                    Text(vendor.avgRating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            if (vendor.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(vendor.address!,
                          style: AppTextStyles.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View Listings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
