import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _Faq {
  final String question, answer, category;
  const _Faq({required this.question, required this.answer, required this.category});
}

const _faqs = [
  _Faq(category: 'Getting Started', question: 'How do I list my surplus food?', answer: 'Go to your vendor dashboard, tap "Add Listing", fill in the item name, description, price, quantity, and pickup window. Your listing will go live immediately after submission.'),
  _Faq(category: 'Getting Started', question: 'What types of food can I list?', answer: 'You can list any surplus food that is safe for consumption — bakery items, prepared meals, raw ingredients, dairy, beverages, and more. Ensure all items meet local food safety standards.'),
  _Faq(category: 'Getting Started', question: 'How is the price set?', answer: 'You set the price. We recommend pricing at 30–70% off the original retail price to attract rescue-conscious customers. Our AI pricing tool can help suggest optimal prices.'),
  _Faq(category: 'Orders', question: 'How do I accept or reject orders?', answer: 'You will receive a push notification for each order. Open the Orders tab and tap "Accept" or "Reject". Orders auto-expire if not accepted within 15 minutes.'),
  _Faq(category: 'Orders', question: 'What if a customer does not show up?', answer: 'If a customer misses their pickup window, the order is marked as "Not Picked Up". You can mark the item as available again or report the no-show via the order detail screen.'),
  _Faq(category: 'Orders', question: 'Can I cancel an accepted order?', answer: 'Yes, but only before the pickup window starts. Frequent cancellations may affect your vendor rating. Cancellations after the window starts require admin approval.'),
  _Faq(category: 'Payments', question: 'When do I receive payment?', answer: 'Payments are processed within 24 hours of a completed order. Funds are transferred to your registered bank account or eSewa wallet every Monday and Thursday.'),
  _Faq(category: 'Payments', question: 'What commission does Food Rescue Nepal charge?', answer: 'We charge a flat 10% service fee on each completed order. There are no monthly fees or hidden charges. The fee covers platform maintenance and customer support.'),
  _Faq(category: 'Payments', question: 'How do I add a bank account for payouts?', answer: 'Go to Profile → Payment Settings → Add Bank Account. We support all major Nepali banks and eSewa. Verification takes 1–2 business days.'),
  _Faq(category: 'Ratings & Reviews', question: 'How is my vendor rating calculated?', answer: 'Your rating is the average of all customer reviews (1–5 stars). Factors like response time, order acceptance rate, and customer feedback also influence your visibility on the platform.'),
  _Faq(category: 'Ratings & Reviews', question: 'Can I respond to reviews?', answer: 'Yes! Go to Reviews → tap any review → "Reply". Responding to reviews, especially negative ones, shows professionalism and can improve customer trust.'),
  _Faq(category: 'Technical', question: 'Why is my listing not showing up?', answer: 'Listings only appear when the pickup window is active and quantity > 0. Check that your store is marked as "Open" in your profile and that the listing\'s scheduled time has begun.'),
  _Faq(category: 'Technical', question: 'How do I update my store hours?', answer: 'Go to Profile → Operating Hours. Set your regular weekly schedule and mark any holidays. This helps customers know when to expect your listings.'),
];

class VendorFaqScreen extends StatefulWidget {
  const VendorFaqScreen({super.key});

  @override
  State<VendorFaqScreen> createState() => _VendorFaqScreenState();
}

class _VendorFaqScreenState extends State<VendorFaqScreen> {
  String _search = '';
  String _category = 'All';
  final _categories = ['All', 'Getting Started', 'Orders', 'Payments', 'Ratings & Reviews', 'Technical'];

  List<_Faq> get _filtered {
    return _faqs.where((f) {
      final matchCat = _category == 'All' || f.category == _category;
      final matchSearch = _search.isEmpty || f.question.toLowerCase().contains(_search.toLowerCase()) || f.answer.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final groupedCats = filtered.map((f) => f.category).toSet().toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: AppColors.primaryMedium.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(color: _category == cat ? AppColors.primaryMedium : AppColors.textSecondary, fontSize: 12),
                  ),
                )).toList(),
              ),
            ),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('No results found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...groupedCats.expand((cat) {
                      final items = filtered.where((f) => f.category == cat).toList();
                      return <Widget>[
                        Text(cat, style: AppTextStyles.h5),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Column(children: items.map((f) => _FaqTile(faq: f, isLast: f == items.last)).toList()),
                        ),
                        const SizedBox(height: 16),
                      ];
                    }),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                      child: Column(children: [
                        const Icon(Icons.support_agent_rounded, size: 32, color: AppColors.primaryMedium),
                        const SizedBox(height: 8),
                        Text('Still have questions?', style: AppTextStyles.h5),
                        const SizedBox(height: 4),
                        Text('Our support team is available 9 AM – 6 PM, Mon–Sat', style: AppTextStyles.caption, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Contact Support'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
                        ),
                      ]),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  final bool isLast;
  const _FaqTile({required this.faq, required this.isLast});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(children: [
    InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: Text(widget.faq.question, style: AppTextStyles.label)),
          Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.primaryMedium),
        ]),
      ),
    ),
    if (_expanded)
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(widget.faq.answer, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ),
    if (!widget.isLast) const Divider(height: 1, indent: 14),
  ]);
}
