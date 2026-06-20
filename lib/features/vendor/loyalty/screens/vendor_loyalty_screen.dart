import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class VendorLoyaltyScreen extends StatefulWidget {
  const VendorLoyaltyScreen({super.key});

  @override
  State<VendorLoyaltyScreen> createState() => _VendorLoyaltyScreenState();
}

class _VendorLoyaltyScreenState extends State<VendorLoyaltyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Customer Loyalty Program'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryMedium,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Rewards'), Tab(text: 'Members')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _RewardsTab(),
          _MembersTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _StatusCard(),
      const SizedBox(height: 16),
      _StatsGrid(),
      const SizedBox(height: 16),
      Text('How It Works', style: AppTextStyles.h5),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Column(children: [
          _HowItWorksStep(step: 1, title: 'Customers Earn Points', desc: 'Customers earn 10 points for every NPR 100 spent at your store.'),
          Divider(height: 20),
          _HowItWorksStep(step: 2, title: 'Points Accumulate', desc: 'Points never expire as long as customers order from you at least once per 3 months.'),
          Divider(height: 20),
          _HowItWorksStep(step: 3, title: 'Redeem for Discounts', desc: 'Customers can redeem 100 points for NPR 10 off their next order.'),
          Divider(height: 20),
          _HowItWorksStep(step: 4, title: 'You Get More Repeat Orders', desc: 'Loyal customers are 5× more likely to return and spend 67% more on average.'),
        ]),
      ),
      const SizedBox(height: 16),
      _EnableCard(),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
        const SizedBox(width: 8),
        Text('Loyalty Program', style: AppTextStyles.h4OnPrimary),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
        child: const Text('✓ ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 16),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _BannerStat('42', 'Active Members'),
        _BannerStat('1,280', 'Points Issued'),
        _BannerStat('840', 'Points Redeemed'),
      ]),
    ]),
  );
}

class _BannerStat extends StatelessWidget {
  final String value, label;
  const _BannerStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
  ]);
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
    children: const [
      _StatTile('67%', 'Repeat Rate', Colors.green),
      _StatTile('NPR 312', 'Avg Loyal Order', Colors.blue),
      _StatTile('8.3', 'Days Between Orders', Colors.orange),
      _StatTile('4.7★', 'Avg Rating from Loyals', Colors.amber),
    ],
  );
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatTile(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: AppTextStyles.h4.copyWith(color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _HowItWorksStep extends StatelessWidget {
  final int step;
  final String title, desc;
  const _HowItWorksStep({required this.step, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 28, height: 28,
      decoration: const BoxDecoration(color: AppColors.primaryMedium, shape: BoxShape.circle),
      child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.label),
      const SizedBox(height: 2),
      Text(desc, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
    ])),
  ]);
}

class _EnableCard extends StatefulWidget {
  @override
  State<_EnableCard> createState() => _EnableCardState();
}

class _EnableCardState extends State<_EnableCard> {
  bool _enabled = true;
  double _pointRate = 10;
  double _redeemRate = 100;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Program Settings', style: AppTextStyles.h5),
        const Spacer(),
        Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
      ]),
      if (_enabled) ...[
        const Divider(height: 20),
        Text('Points per NPR 100 spent: ${_pointRate.toInt()}', style: AppTextStyles.label),
        Slider(value: _pointRate, min: 5, max: 20, divisions: 3, onChanged: (v) => setState(() => _pointRate = v), activeColor: AppColors.primaryMedium),
        const SizedBox(height: 8),
        Text('Points needed to redeem NPR 10: ${_redeemRate.toInt()}', style: AppTextStyles.label),
        Slider(value: _redeemRate, min: 50, max: 200, divisions: 3, onChanged: (v) => setState(() => _redeemRate = v), activeColor: AppColors.primaryMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!'))),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
            child: const Text('Save Settings'),
          ),
        ),
      ],
    ]),
  );
}

class _RewardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Active Rewards', style: AppTextStyles.h5),
      const SizedBox(height: 12),
      ...[
        ('100 pts = NPR 10 off', 'Standard discount', Icons.local_offer_rounded, Colors.green),
        ('500 pts = Free Item', 'Any item up to NPR 80', Icons.card_giftcard_rounded, Colors.purple),
        ('1000 pts = 20% Off', 'Next order discount', Icons.percent_rounded, Colors.orange),
      ].map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: r.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(r.$3, color: r.$4)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$1, style: AppTextStyles.label),
            Text(r.$2, style: AppTextStyles.caption),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ]),
      )),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Custom Reward'),
      ),
    ],
  );
}

class _MembersTab extends StatelessWidget {
  static const _members = [
    ('Sita M.', 480, 'Gold', 12),
    ('Ram K.', 320, 'Silver', 9),
    ('Anita S.', 280, 'Silver', 8),
    ('Bikram T.', 140, 'Bronze', 5),
    ('Priya G.', 100, 'Bronze', 4),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Loyalty Members (42 total)', style: AppTextStyles.h5),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: _members.asMap().entries.map((e) {
            final m = e.value;
            final tierColor = m.$3 == 'Gold' ? Colors.amber : m.$3 == 'Silver' ? Colors.blueGrey : Colors.brown;
            return Column(children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15), child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primaryMedium, fontWeight: FontWeight.bold))),
                title: Text(m.$1, style: AppTextStyles.label),
                subtitle: Text('${m.$2} pts • ${m.$4} orders', style: AppTextStyles.caption),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tierColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(m.$3, style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              if (e.key < _members.length - 1) const Divider(height: 1, indent: 56),
            ]);
          }).toList(),
        ),
      ),
    ],
  );
}
