import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _TrendingItem {
  final String id, name, vendor, category, image;
  final int ordersToday;
  final double discount, price;
  const _TrendingItem({required this.id, required this.name, required this.vendor, required this.category, required this.image, required this.ordersToday, required this.discount, required this.price});
}

const _trending = [
  _TrendingItem(id: '1', name: 'Surprise Bakery Bag', vendor: 'Himalayan Bakes', category: 'Bakery', image: '', ordersToday: 48, discount: 60, price: 180),
  _TrendingItem(id: '2', name: 'Dal Bhat Set', vendor: 'Thakali Kitchen', category: 'Restaurant', image: '', ordersToday: 41, discount: 50, price: 120),
  _TrendingItem(id: '3', name: 'Fresh Vegetables Mix', vendor: 'Green Farm Store', category: 'Grocery', image: '', ordersToday: 35, discount: 45, price: 200),
  _TrendingItem(id: '4', name: 'Café Pastry Box', vendor: 'Mountain Brew Café', category: 'Cafe', image: '', ordersToday: 29, discount: 55, price: 250),
  _TrendingItem(id: '5', name: 'Mithai Assortment', vendor: 'Sweet Nepal', category: 'Sweets', image: '', ordersToday: 24, discount: 40, price: 300),
  _TrendingItem(id: '6', name: 'Noodle Soup Set', vendor: 'Tibetan Kitchen', category: 'Restaurant', image: '', ordersToday: 21, discount: 35, price: 150),
];

class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Trending Now 🔥')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TrendingBanner(),
          const SizedBox(height: 16),
          Text('Most Ordered Today', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ..._trending.asMap().entries.map((e) => _TrendingCard(item: e.value, rank: e.key + 1)),
        ],
      ),
    );
  }
}

class _TrendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepOrange.shade700, Colors.orange.shade500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Hot Picks", style: AppTextStyles.h4OnPrimary),
                Text('${_trending.fold(0, (s, i) => s + i.ordersToday)} orders rescued today!', style: AppTextStyles.bodySmallOnPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final _TrendingItem item;
  final int rank;
  const _TrendingCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final rankLabel = rank <= 3 ? medals[rank - 1] : '#$rank';
    return GestureDetector(
      onTap: () => context.push('/customer/listing/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            SizedBox(width: 36, child: Text(rankLabel, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)),
            const SizedBox(width: 10),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryMedium, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(item.vendor, style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text('${item.ordersToday} orders today', style: AppTextStyles.caption.copyWith(color: Colors.orange.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  child: Text('-${item.discount.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('Rs. ${item.price.toInt()}', style: AppTextStyles.h6.copyWith(color: AppColors.primaryDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
