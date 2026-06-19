import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('How It Works'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.h6.copyWith(color: Colors.white),
          unselectedLabelStyle:
              AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          tabs: const [
            Tab(text: 'For Customers'),
            Tab(text: 'For Vendors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CustomerTab(onGetStarted: () => context.push('/register')),
          _VendorTab(onGetStarted: () => context.push('/register')),
        ],
      ),
    );
  }
}

class _CustomerTab extends StatelessWidget {
  const _CustomerTab({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.s2),
          const _HeroCard(
            emoji: '🛒',
            title: 'Save up to 70% on great food',
            subtitle:
                'Rescue surplus food from local restaurants, bakeries, and cafes before it goes to waste.',
            bgColor: AppColors.primarySurface,
          ),
          const SizedBox(height: AppSizes.s5),
          Text('3 simple steps', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          const _Step(
            number: '1',
            icon: Icons.search_rounded,
            color: AppColors.primaryMedium,
            title: 'Browse deals near you',
            body:
                'Open the app and see what food is available near you right now. Filter by category, price, or pickup time.',
          ),
          const _Step(
            number: '2',
            icon: Icons.bookmark_add_rounded,
            color: AppColors.accentAmber,
            title: 'Reserve your bag',
            body:
                'Tap Reserve and pay cash when you pick up. No advance payment needed — just show up at the pickup window.',
          ),
          const _Step(
            number: '3',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.success,
            title: 'Pick up with your QR code',
            body:
                'Head to the vendor at the listed pickup time. Show your QR code and enjoy your food — you just rescued a meal!',
          ),
          const SizedBox(height: AppSizes.s5),
          const _ImpactSection(),
          const SizedBox(height: AppSizes.s5),
          const _SurpriseBagSection(),
          const SizedBox(height: AppSizes.s5),
          Text('Frequently asked questions', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          ..._customerFaqs.map((faq) => _FaqTile(faq: faq)),
          const SizedBox(height: AppSizes.s5),
          _CtaButton(
              label: 'Start saving food', onPressed: onGetStarted),
          const SizedBox(height: AppSizes.s4),
        ],
      ),
    );
  }
}

class _VendorTab extends StatelessWidget {
  const _VendorTab({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.s2),
          const _HeroCard(
            emoji: '🏪',
            title: 'Turn surplus food into revenue',
            subtitle:
                'List your unsold food at the end of each day and reach customers who are ready to pick it up.',
            bgColor: AppColors.warningSurface,
          ),
          const SizedBox(height: AppSizes.s5),
          Text('3 simple steps', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          const _Step(
            number: '1',
            icon: Icons.add_photo_alternate_rounded,
            color: AppColors.primaryMedium,
            title: 'List your surplus food',
            body:
                'Add a listing for your leftover food — set the discounted price, quantity, and pickup window. Takes under 2 minutes.',
          ),
          const _Step(
            number: '2',
            icon: Icons.notifications_rounded,
            color: AppColors.accentAmber,
            title: 'Customers reserve instantly',
            body:
                'You\'ll get notified when a customer reserves. Accept the order to confirm their spot.',
          ),
          const _Step(
            number: '3',
            icon: Icons.qr_code_2_rounded,
            color: AppColors.success,
            title: 'Scan & hand over',
            body:
                'When the customer arrives, scan their QR code to complete the pickup. Cash is collected at your counter.',
          ),
          const SizedBox(height: AppSizes.s4),
          const _StatRow(stats: [
            _StatItem(value: '0%', label: 'Commission fees'),
            _StatItem(value: '70%', label: 'Max discount offered'),
            _StatItem(value: '2 min', label: 'To add a listing'),
          ]),
          const SizedBox(height: AppSizes.s5),
          Text('Frequently asked questions', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.s3),
          ..._vendorFaqs.map((faq) => _FaqTile(faq: faq)),
          const SizedBox(height: AppSizes.s5),
          _CtaButton(label: 'Join as a vendor', onPressed: onGetStarted),
          const SizedBox(height: AppSizes.s4),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.s2),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.s1),
          Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          number,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s2),
                    Expanded(
                        child: Text(title, style: AppTextStyles.h5)),
                  ],
                ),
                const SizedBox(height: AppSizes.s1),
                Text(body,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});
  final ({String q, String a}) faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(widget.faq.q,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600))),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSizes.s2),
                Text(widget.faq.a,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});
  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(color: AppColors.primaryMedium)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s3 + 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusButton)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}

// ─── Impact section ──────────────────────────────────────────────────────────

class _ImpactSection extends StatelessWidget {
  const _ImpactSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our community impact',
            style: AppTextStyles.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSizes.s1),
          Text(
            'Every rescue adds up. Together we\'re making a real difference.',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.s4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ImpactStat(value: '2,500+', label: 'Meals\nRescued', emoji: '🍱'),
              _ImpactStat(value: '6.2 t', label: 'CO₂\nSaved', emoji: '🌱'),
              _ImpactStat(value: '70%', label: 'Avg.\nDiscount', emoji: '💰'),
            ],
          ),
          const SizedBox(height: AppSizes.s3),
          Container(
            padding: const EdgeInsets.all(AppSizes.s3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 22)),
                const SizedBox(width: AppSizes.s2),
                Expanded(
                  child: Text(
                    'Saving 1 meal prevents ~2.5 kg of CO₂ emissions — the same as driving 10 km.',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.value,
    required this.label,
    required this.emoji,
  });
  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: AppSizes.s1),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Surprise Bag section ───────────────────────────────────────────────────

class _SurpriseBagSection extends StatelessWidget {
  const _SurpriseBagSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.accentAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 26)),
              const SizedBox(width: AppSizes.s2),
              Expanded(
                child: Text(
                  'What is a Surprise Bag?',
                  style: AppTextStyles.h4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            'A Surprise Bag is a mystery box of surplus food from a vendor — you don\'t know exactly what\'s inside, but it\'s always good quality and worth far more than the price you pay.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSizes.s3),
          ..._surpriseBagPerks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(perk.$1, style: const TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: AppSizes.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perk.$2, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        Text(perk.$3, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s2),
          Container(
            padding: const EdgeInsets.all(AppSizes.s3),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              '💡 Tip: Surprise Bags are great for adventurous eaters and anyone who loves a deal — vendors pack them with whatever is freshest that day.',
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

const _surpriseBagPerks = [
  ('🍽️', 'More food, less cost', 'Surprise Bags are typically 50–70% off the retail value of what\'s inside.'),
  ('🌱', 'Zero waste hero', 'Each bag you rescue keeps perfectly good food out of landfill.'),
  ('🎲', 'Fun mystery element', 'You\'ll get a mix of freshly made items — great for trying new things.'),
  ('⚡', 'Limited availability', 'Only a few bags are offered each day, so grab one while it\'s there.'),
];

// ─── FAQ data ────────────────────────────────────────────────────────────────

const _customerFaqs = [
  (
    q: 'Do I need to pay in advance?',
    a: 'No. All payments are cash on pickup. Reserve your bag in the app, then pay the vendor when you collect it.'
  ),
  (
    q: 'What if the food doesn\'t look right?',
    a: 'You can cancel any reservation before the pickup window starts. The vendor is notified and your slot is released.'
  ),
  (
    q: 'What types of food are available?',
    a: 'Bakery items, restaurant meals, cafe drinks, grocery items, and more. Each listing shows exactly what\'s included.'
  ),
  (
    q: 'How fresh is the food?',
    a: 'All listings are for same-day surplus food. Vendors list food that\'s freshly made but unsold — it\'s perfectly good, just needs a home.'
  ),
];

const _vendorFaqs = [
  (
    q: 'Is there a commission fee?',
    a: 'No. Food Rescue Nepal charges zero commission. You keep 100% of the sale price you set.'
  ),
  (
    q: 'How long does approval take?',
    a: 'Most businesses are approved within 1–2 business days. You\'ll receive a notification when your account is active.'
  ),
  (
    q: 'What if a customer doesn\'t show up?',
    a: 'If a customer cancels or misses pickup, you keep the food and the slot is reopened. Reservations automatically expire after the pickup window.'
  ),
  (
    q: 'Can I list food every day?',
    a: 'Yes! You can add new listings any time, including recurring deals. Many vendors list daily at the end of their service period.'
  ),
];
