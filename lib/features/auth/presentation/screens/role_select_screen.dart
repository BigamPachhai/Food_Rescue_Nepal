import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Food Rescue Nepal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Who are you?', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text('Select your role to get started', style: AppTextStyles.bodySmall),
              const SizedBox(height: 32),
              _RoleCard(
                emoji: '🛒',
                iconColor: AppColors.primaryLight,
                title: 'Customer',
                subtitle: 'Discover discounted food near you and rescue it from waste.',
                onTap: () => context.go('/register/customer'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                emoji: '🏪',
                iconColor: AppColors.accentAmber,
                title: 'Vendor',
                subtitle: 'List your surplus food, reduce waste, and reach more customers.',
                onTap: () => context.go('/register/vendor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
