import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class PlatformInsights {
  final int newUsers30d;
  final int newOrders30d;
  final int newListings30d;
  final int activeVendors;
  final int openDisputes;
  final List<Map<String, dynamic>> topTrending;

  const PlatformInsights({
    required this.newUsers30d,
    required this.newOrders30d,
    required this.newListings30d,
    required this.activeVendors,
    required this.openDisputes,
    required this.topTrending,
  });

  factory PlatformInsights.fromJson(Map<String, dynamic> j) => PlatformInsights(
        newUsers30d: (j['newUsers30d'] as num?)?.toInt() ?? 0,
        newOrders30d: (j['newOrders30d'] as num?)?.toInt() ?? 0,
        newListings30d: (j['newListings30d'] as num?)?.toInt() ?? 0,
        activeVendors: (j['activeVendors'] as num?)?.toInt() ?? 0,
        openDisputes: (j['openDisputes'] as num?)?.toInt() ?? 0,
        topTrending: (j['topTrending'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
}

final platformInsightsProvider = FutureProvider<PlatformInsights>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.adminInsights);
  final raw = res.data as Map<String, dynamic>;
  return PlatformInsights.fromJson(raw['data'] as Map<String, dynamic>? ?? {});
});

class AdminInsightsScreen extends ConsumerWidget {
  const AdminInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(platformInsightsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Insights'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(platformInsightsProvider))],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last 30 Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _InsightCard(label: 'New Users', value: '${data.newUsers30d}', icon: Icons.person_add, color: Colors.blue),
                  _InsightCard(label: 'New Orders', value: '${data.newOrders30d}', icon: Icons.receipt_long, color: Colors.green),
                  _InsightCard(label: 'New Listings', value: '${data.newListings30d}', icon: Icons.fastfood, color: Colors.orange),
                  _InsightCard(label: 'Active Vendors', value: '${data.activeVendors}', icon: Icons.store, color: Colors.purple),
                ],
              ),
              if (data.openDisputes > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Text('${data.openDisputes} open dispute${data.openDisputes > 1 ? 's' : ''} need review', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              if (data.topTrending.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Top Trending Listings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...data.topTrending.asMap().entries.map((e) {
                  final listing = e.value;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(child: Text('${e.key + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    title: Text(listing['name'] as String? ?? ''),
                    subtitle: Text((listing['vendor'] as Map<String, dynamic>?)?['businessName'] as String? ?? ''),
                    trailing: Text('Score: ${(listing['trendingScore'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InsightCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );
}
