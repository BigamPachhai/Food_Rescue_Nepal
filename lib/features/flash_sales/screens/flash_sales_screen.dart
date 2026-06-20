import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class FlashSaleItem {
  final String id;
  final int salePrice;
  final int originalPrice;
  final DateTime startsAt;
  final DateTime endsAt;
  final String listingId;
  final String listingName;
  final List<String> imageUrls;
  final String category;
  final int availableQty;
  final String vendorName;
  final String? vendorLogo;

  const FlashSaleItem({
    required this.id,
    required this.salePrice,
    required this.originalPrice,
    required this.startsAt,
    required this.endsAt,
    required this.listingId,
    required this.listingName,
    required this.imageUrls,
    required this.category,
    required this.availableQty,
    required this.vendorName,
    this.vendorLogo,
  });

  factory FlashSaleItem.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>? ?? {};
    final vendor = json['vendor'] as Map<String, dynamic>? ?? {};
    return FlashSaleItem(
      id: json['id'] as String? ?? '',
      salePrice: (json['salePrice'] as num?)?.toInt() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
      endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ?? DateTime.now(),
      listingId: listing['id'] as String? ?? '',
      listingName: listing['name'] as String? ?? '',
      imageUrls: (listing['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      category: listing['category'] as String? ?? '',
      availableQty: (listing['availableQty'] as num?)?.toInt() ?? 0,
      vendorName: vendor['businessName'] as String? ?? '',
      vendorLogo: vendor['logoUrl'] as String?,
    );
  }

  int get discountPercent {
    if (originalPrice == 0) return 0;
    return (((originalPrice - salePrice) / originalPrice) * 100).round();
  }
}

final flashSalesProvider = FutureProvider<List<FlashSaleItem>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final response = await dio.get(ApiEndpoints.flashSales, queryParameters: {'limit': 20});
  final raw = response.data as Map<String, dynamic>;
  final data = raw['data'];
  final items = (data is Map ? data['items'] : data) ?? [];
  return (items as List<dynamic>)
      .map((e) => FlashSaleItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

class FlashSalesScreen extends ConsumerStatefulWidget {
  const FlashSalesScreen({super.key});

  @override
  ConsumerState<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends ConsumerState<FlashSalesScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(flashSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Flash Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(flashSalesProvider),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active flash sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('Check back soon for limited-time deals!'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(flashSalesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              itemBuilder: (context, i) => _FlashSaleCard(
                item: sales[i],
                now: DateTime.now(),
                onTap: () => context.push('/customer/listing/${sales[i].listingId}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  final FlashSaleItem item;
  final DateTime now;
  final VoidCallback onTap;

  const _FlashSaleCard({required this.item, required this.now, required this.onTap});

  String _formatCountdown() {
    final remaining = item.endsAt.difference(now);
    if (remaining.isNegative) return 'Ended';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final countdown = _formatCountdown();
    final isUrgent = item.endsAt.difference(now).inMinutes < 30;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                item.imageUrls.isNotEmpty
                    ? Image.network(item.imageUrls.first, height: 160, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 48)),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: Text('-${item.discountPercent}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.red[800] : Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(countdown, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.listingName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item.vendorName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'NPR ${(item.salePrice / 100).toStringAsFixed(0)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NPR ${(item.originalPrice / 100).toStringAsFixed(0)}',
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13),
                      ),
                      const Spacer(),
                      Text('${item.availableQty} left', style: TextStyle(color: item.availableQty < 3 ? Colors.red : Colors.green[700], fontSize: 12)),
                    ],
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
