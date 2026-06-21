import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _Post {
  final String user, avatar, content, timeAgo;
  final int likes, comments;
  final bool isLiked;
  const _Post({required this.user, required this.avatar, required this.content, required this.timeAgo, this.likes = 0, this.comments = 0, this.isLiked = false});
}

final _mockPosts = [
  const _Post(user: 'Sita S.', avatar: 'S', content: '🎉 Just completed my 50th food rescue! Saved Rs. 2,400 and 125kg of CO₂. So proud to be part of this community!', timeAgo: '2h ago', likes: 34, comments: 8),
  const _Post(user: 'Ram T.', avatar: 'R', content: '💡 Tip: The bakery near New Baneshwor often lists fresh bread at 70% off after 6pm. Worth checking every evening!', timeAgo: '4h ago', likes: 56, comments: 12, isLiked: true),
  const _Post(user: 'Gita R.', avatar: 'G', content: '🍱 Made this amazing dal bhat with rescued vegetables from Food Rescue Nepal today! So delicious and zero waste!', timeAgo: '6h ago', likes: 28, comments: 5),
  const _Post(user: 'Maya T.', avatar: 'M', content: '🌱 Weekly challenge completed! Rescued food 7 days in a row. Who else is on a streak?', timeAgo: '1d ago', likes: 67, comments: 20),
  const _Post(user: 'Bikash K.', avatar: 'B', content: '📍 New vendor just joined in Thamel area — "Green Plate Cafe" has amazing salads at rescue prices. Highly recommend!', timeAgo: '1d ago', likes: 43, comments: 9),
];

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});
  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _likes = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(icon: const Icon(Icons.flag_rounded), onPressed: () => context.push('/customer/challenges'), tooltip: 'Challenges'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(context),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Share', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CommunityStats(),
          const SizedBox(height: 16),
          _WeeklyHighlight(),
          const SizedBox(height: 16),
          const SizedBox(height: 4),
          ..._mockPosts.asMap().entries.map((e) => _PostCard(
            post: e.value,
            isLiked: _likes.contains(e.key) || e.value.isLiked,
            onLike: () => setState(() {
              if (_likes.contains(e.key)) {
                _likes.remove(e.key);
              } else {
                _likes.add(e.key);
              }
            }),
          )),
        ],
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share with Community', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share a tip, achievement, or food rescue story...',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post shared with the community!')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
                  child: const Text('Post'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CommunityStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CStat(value: '2,847', label: 'Members'),
          _CStat(value: '14,230', label: 'Meals Rescued'),
          _CStat(value: '35.6t', label: 'CO₂ Saved'),
        ],
      ),
    );
  }
}

class _CStat extends StatelessWidget {
  final String value, label;
  const _CStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTextStyles.h4OnPrimary),
      Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
    ],
  );
}

class _WeeklyHighlight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rescuer of the Week', style: AppTextStyles.label.copyWith(color: Colors.amber.shade800)),
                Text('Sita Sharma — 28 orders this week!', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final bool isLiked;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.isLiked, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18, backgroundColor: AppColors.primaryMedium.withValues(alpha: 0.15),
                child: Text(post.avatar, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.user, style: AppTextStyles.label),
                  Text(post.timeAgo, style: AppTextStyles.caption),
                ],
              )),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.content, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionBtn(icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '${post.likes + (isLiked ? 1 : 0)}', color: isLiked ? Colors.red : null, onTap: onLike),
              const SizedBox(width: 16),
              _ActionBtn(icon: Icons.chat_bubble_outline_rounded, label: '${post.comments}', onTap: () {}),
              const SizedBox(width: 16),
              _ActionBtn(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Row(children: [
      Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption.copyWith(color: color ?? AppColors.textSecondary)),
    ]),
  );
}
