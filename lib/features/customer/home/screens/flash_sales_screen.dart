import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _FlashDeal {
  final String id, name, vendor, category;
  final double originalPrice, flashPrice;
  final int quantityLeft, totalQuantity;
  final Duration timeLeft;
  const _FlashDeal({required this.id, required this.name, required this.vendor, required this.category, required this.originalPrice, required this.flashPrice, required this.quantityLeft, required this.totalQuantity, required this.timeLeft});
  double get discountPct => ((originalPrice - flashPrice) / originalPrice * 100);
}

const _flashDeals = [
  _FlashDeal(id: '1', name: 'Mega Surprise Bag', vendor: 'Himalayan Bakes', category: 'Bakery', originalPrice: 500, flashPrice: 149, quantityLeft: 3, totalQuantity: 10, timeLeft: Duration(hours: 1, minutes: 23)),
  _FlashDeal(id: '2', name: 'Chef Special Box', vendor: 'Thakali Kitchen', category: 'Restaurant', originalPrice: 400, flashPrice: 129, quantityLeft: 5, totalQuantity: 15, timeLeft: Duration(hours: 2, minutes: 45)),
  _FlashDeal(id: '3', name: 'Fresh Fruit Bundle', vendor: 'Green Farm Store', category: 'Grocery', originalPrice: 350, flashPrice: 99, quantityLeft: 7, totalQuantity: 20, timeLeft: Duration(minutes: 45)),
  _FlashDeal(id: '4', name: 'Café Combo Pack', vendor: 'Mountain Brew', category: 'Cafe', originalPrice: 600, flashPrice: 199, quantityLeft: 2, totalQuantity: 8, timeLeft: Duration(minutes: 18)),
];

class FlashSalesScreen extends ConsumerStatefulWidget {
  const FlashSalesScreen({super.key});

  @override
  ConsumerState<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends ConsumerState<FlashSalesScreen> {
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Row(children: [
          const Text('⚡ ', style: TextStyle(fontSize: 20)),
          Text('Flash Sales', style: AppTextStyles.h5),
        ]),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FlashHeader(),
          const SizedBox(height: 16),
          Text('Active Deals', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ..._flashDeals.map((d) => _FlashDealCard(deal: d, tickSeconds: _seconds)),
          const SizedBox(height: 20),
          _UpcomingDealsCard(),
        ],
      ),
    );
  }
}

class _FlashHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade800, Colors.red.shade600]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flash Sales!', style: AppTextStyles.h3OnPrimary),
                Text('Limited-time deep discounts on surplus food', style: AppTextStyles.bodySmallOnPrimary),
                const SizedBox(height: 8),
                Text('Up to 75% OFF • Today Only', style: AppTextStyles.label.copyWith(color: Colors.yellow, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashDealCard extends StatelessWidget {
  final _FlashDeal deal;
  final int tickSeconds;
  const _FlashDealCard({required this.deal, required this.tickSeconds});

  String _formatTime(Duration d) {
    final adjusted = d - Duration(seconds: tickSeconds % 60);
    if (adjusted.isNegative) return '00:00:00';
    final h = adjusted.inHours.toString().padLeft(2, '0');
    final m = (adjusted.inMinutes % 60).toString().padLeft(2, '0');
    final s = (adjusted.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final stockPct = deal.quantityLeft / deal.totalQuantity;
    final isLow = deal.quantityLeft <= 3;
    return GestureDetector(
      onTap: () => context.push('/customer/listing/${deal.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLow ? Colors.red.withValues(alpha: 0.4) : Colors.transparent),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isLow ? Colors.red.shade700 : AppColors.primaryMedium,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(_formatTime(deal.timeLeft), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
                  ]),
                  if (isLow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Text('Only ${deal.quantityLeft} left!', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryMedium, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deal.name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(deal.vendor, style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('Rs. ${deal.flashPrice.toInt()}', style: AppTextStyles.h5.copyWith(color: Colors.red.shade700)),
                          const SizedBox(width: 8),
                          Text('Rs. ${deal.originalPrice.toInt()}', style: AppTextStyles.caption.copyWith(decoration: TextDecoration.lineThrough)),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('-${deal.discountPct.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stock: ${deal.quantityLeft}/${deal.totalQuantity}', style: AppTextStyles.caption),
                      Text('${(stockPct * 100).toInt()}% remaining', style: AppTextStyles.caption.copyWith(color: isLow ? Colors.red : AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stockPct, minHeight: 6,
                      backgroundColor: AppColors.backgroundLight,
                      valueColor: AlwaysStoppedAnimation<Color>(isLow ? Colors.red : AppColors.primaryMedium),
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

class _UpcomingDealsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Coming Up Next', style: AppTextStyles.h5),
          ]),
          const SizedBox(height: 12),
          Text('🎁 Mystery Dinner Box — starts in 2h 15m', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 6),
          Text('🍜 Noodle Soup Mega Bundle — starts in 4h', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_rounded),
              label: const Text('Notify Me for Upcoming Deals'),
            ),
          ),
        ],
      ),
    );
  }
}
