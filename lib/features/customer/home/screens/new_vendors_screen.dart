import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _NewVendor {
  final String id, name, category, location, joinedAgo, rating;
  final int totalListings;
  final bool isOpen;
  const _NewVendor({required this.id, required this.name, required this.category, required this.location, required this.joinedAgo, required this.rating, required this.totalListings, required this.isOpen});
}

const _vendors = [
  _NewVendor(id: 'v1', name: 'Patan Sweets Corner', category: 'Bakery & Sweets', location: 'Patan, Lalitpur', joinedAgo: '2 days ago', rating: 'New', totalListings: 4, isOpen: true),
  _NewVendor(id: 'v2', name: 'Bouddha Bowl Kitchen', category: 'Prepared Meals', location: 'Bouddha, Kathmandu', joinedAgo: '5 days ago', rating: 'New', totalListings: 6, isOpen: true),
  _NewVendor(id: 'v3', name: 'Kirtipur Dairy Farm', category: 'Dairy & Eggs', location: 'Kirtipur', joinedAgo: '1 week ago', rating: '4.8', totalListings: 3, isOpen: false),
  _NewVendor(id: 'v4', name: 'Boudhanath Café', category: 'Café & Beverages', location: 'Boudhanath', joinedAgo: '1 week ago', rating: '4.6', totalListings: 8, isOpen: true),
  _NewVendor(id: 'v5', name: 'Newari Kitchen House', category: 'Traditional Food', location: 'Asan, Kathmandu', joinedAgo: '2 weeks ago', rating: '4.9', totalListings: 5, isOpen: true),
  _NewVendor(id: 'v6', name: 'Baneshwor Bakehouse', category: 'Bakery', location: 'Baneshwor', joinedAgo: '2 weeks ago', rating: '4.5', totalListings: 7, isOpen: false),
];

class NewVendorsScreen extends StatelessWidget {
  const NewVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('New Vendors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NewVendorBanner(),
          const SizedBox(height: 16),
          Row(children: [
            Text('${_vendors.length} New Vendors This Month', style: AppTextStyles.h5),
          ]),
          const SizedBox(height: 12),
          ..._vendors.map((v) => _VendorCard(vendor: v)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.store_mall_directory_rounded, color: AppColors.primaryMedium),
              const SizedBox(width: 10),
              Expanded(child: Text('Are you a food vendor? Join us and reach hundreds of rescue-conscious customers.', style: AppTextStyles.bodySmall)),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: const Text('Join')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _NewVendorBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade400]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('6 New Vendors', style: AppTextStyles.h4OnPrimary),
        const SizedBox(height: 4),
        const Text('joined this month! Be among the first to try their food.', style: TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Text('Early Supporter Bonus: +20 pts per order', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ])),
      const SizedBox(width: 12),
      const Text('🏪', style: TextStyle(fontSize: 48)),
    ]),
  );
}

class _VendorCard extends StatelessWidget {
  final _NewVendor vendor;
  const _VendorCard({required this.vendor});

  static const _catColors = {
    'Bakery & Sweets': Colors.orange,
    'Prepared Meals': Colors.purple,
    'Dairy & Eggs': Colors.blue,
    'Café & Beverages': Colors.teal,
    'Traditional Food': Colors.green,
    'Bakery': Colors.deepOrange,
  };

  @override
  Widget build(BuildContext context) {
    final color = _catColors[vendor.category] ?? AppColors.primaryMedium;
    return GestureDetector(
      onTap: () => context.push('/customer/vendor/${vendor.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.store_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(vendor.name, style: AppTextStyles.label, overflow: TextOverflow.ellipsis)),
              if (vendor.isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('OPEN', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 3),
            Text(vendor.category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text(vendor.location, style: AppTextStyles.caption),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text('Joined ${vendor.joinedAgo}', style: AppTextStyles.caption),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(vendor.rating == 'New' ? '✨ New' : '⭐ ${vendor.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text('${vendor.totalListings} items available', style: AppTextStyles.caption),
            ]),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }
}
