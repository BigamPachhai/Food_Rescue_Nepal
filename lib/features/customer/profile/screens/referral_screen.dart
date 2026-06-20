import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  static const _referralCode = 'RESCUE2025';
  static const _referralLink = 'https://foodrescuenepal.app/join?ref=RESCUE2025';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(),
          const SizedBox(height: 20),
          const _ReferralCodeCard(code: _referralCode, link: _referralLink),
          const SizedBox(height: 20),
          _HowItWorks(),
          const SizedBox(height: 20),
          _ReferralStats(),
          const SizedBox(height: 20),
          const _ShareButtons(link: _referralLink),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('Invite Friends, Earn Rewards!', style: AppTextStyles.h4OnPrimary, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('You get 100 points, your friend gets 50 points on their first order!', style: AppTextStyles.bodySmallOnPrimary, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  final String code, link;
  const _ReferralCodeCard({required this.code, required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text('Your Referral Code', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.4), width: 2, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(code, style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark, letterSpacing: 4)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  color: AppColors.primaryMedium,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Or share your link', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(link, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied!')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works', style: AppTextStyles.h5),
          const SizedBox(height: 14),
          const _Step(number: '1', title: 'Share Your Code', desc: 'Send your referral code or link to friends'),
          const _Step(number: '2', title: 'Friend Joins', desc: 'They sign up and complete their first order'),
          const _Step(number: '3', title: 'Both Earn Rewards', desc: 'You get 100 pts, they get 50 pts automatically'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number, title, desc;
  const _Step({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: AppColors.primaryMedium, shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.label),
          Text(desc, style: AppTextStyles.caption),
        ])),
      ],
    ),
  );
}

class _ReferralStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Stats', style: AppTextStyles.h5),
          const SizedBox(height: 14),
          const Row(
            children: [
              _StatBox(value: '0', label: 'Friends Referred'),
              SizedBox(width: 12),
              _StatBox(value: '0', label: 'Points Earned'),
              SizedBox(width: 12),
              _StatBox(value: '0', label: 'Pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ShareButtons extends StatelessWidget {
  final String link;
  const _ShareButtons({required this.link});
  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Share.share('🌱 Join me on Food Rescue Nepal! Use my code RESCUE2025 or link: $link\n\nReduce food waste and save money!'),
        icon: const Icon(Icons.share_rounded),
        label: const Text('Share via Apps'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.message_rounded),
        label: const Text('Send via WhatsApp'),
      ),
    ),
  ]);
}
