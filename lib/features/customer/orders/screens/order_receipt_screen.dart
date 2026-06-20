import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class OrderReceiptScreen extends StatelessWidget {
  final String orderId;
  const OrderReceiptScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Order Receipt'),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => _share(context)),
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => _download(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReceiptHeader(orderId: orderId, date: now),
          const SizedBox(height: 16),
          const _ReceiptCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel('Vendor'),
              _InfoRow('Name', 'Himalayan Bakehouse'),
              _InfoRow('Location', 'Thamel, Kathmandu'),
              _InfoRow('Pickup Time', '5:00 PM – 6:00 PM'),
            ]),
          ),
          const SizedBox(height: 12),
          _ReceiptCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionLabel('Items Ordered'),
              const SizedBox(height: 8),
              const _LineItem('Surprise Bakery Box', '1', 'NPR 250'),
              const _LineItem('Whole Wheat Bread', '2', 'NPR 120'),
              const _LineItem('Chocolate Muffin x3', '1', 'NPR 90'),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Subtotal', style: AppTextStyles.bodySmall),
                Text('NPR 460', style: AppTextStyles.label),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Platform Fee', style: AppTextStyles.bodySmall),
                Text('NPR 0', style: AppTextStyles.label),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Discount Applied', style: AppTextStyles.bodySmall.copyWith(color: Colors.green)),
                Text('- NPR 0', style: AppTextStyles.label.copyWith(color: Colors.green)),
              ]),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total Paid', style: AppTextStyles.h5),
                Text('NPR 460', style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _ReceiptCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionLabel('Payment Details'),
              const _InfoRow('Method', 'eSewa'),
              _InfoRow('Transaction ID', 'ESW-2025-${orderId.toUpperCase()}'),
              const _InfoRow('Status', 'Completed'),
              _InfoRow('Paid On', '${now.day}/${now.month}/${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
            ]),
          ),
          const SizedBox(height: 12),
          _ImpactCard(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('Need Help?'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.star_rate_rounded, size: 18),
                label: const Text('Rate Order'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Center(child: Text('Receipt #$orderId', style: AppTextStyles.caption)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing receipt...')));
  }

  void _download(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt saved to Downloads')));
  }
}

class _ReceiptHeader extends StatelessWidget {
  final String orderId;
  final DateTime date;
  const _ReceiptHeader({required this.orderId, required this.date});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryMedium, size: 36),
      ),
      const SizedBox(height: 12),
      Text('Order Completed!', style: AppTextStyles.h4OnPrimary),
      const SizedBox(height: 4),
      Text('Thank you for rescuing food 🌱', style: AppTextStyles.bodySmallOnPrimary),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: orderId));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order ID copied')));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Order #$orderId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
          ]),
        ),
      ),
    ]),
  );
}

class _ReceiptCard extends StatelessWidget {
  final Widget child;
  const _ReceiptCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySmall),
      Text(value, style: AppTextStyles.label),
    ]),
  );
}

class _LineItem extends StatelessWidget {
  final String name, qty, price;
  const _LineItem(this.name, this.qty, this.price);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Center(child: Text(qty, style: const TextStyle(color: AppColors.primaryMedium, fontSize: 11, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: AppTextStyles.bodySmall)),
      Text(price, style: AppTextStyles.label),
    ]),
  );
}

class _ImpactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('🌿', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text('Your Impact This Order', style: AppTextStyles.h5.copyWith(color: Colors.green[700])),
      ]),
      const SizedBox(height: 12),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _ImpactStat('0.5 kg', 'CO₂ Saved'),
        _ImpactStat('12 L', 'Water Saved'),
        _ImpactStat('1', 'Meal Rescued'),
      ]),
    ]),
  );
}

class _ImpactStat extends StatelessWidget {
  final String value, label;
  const _ImpactStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h5.copyWith(color: Colors.green[700])),
    Text(label, style: AppTextStyles.caption),
  ]);
}
