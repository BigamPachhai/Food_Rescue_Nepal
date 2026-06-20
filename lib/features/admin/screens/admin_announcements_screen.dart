import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _Announcement {
  final String id, title, body, audience;
  final DateTime sentAt;
  final bool isDraft;
  const _Announcement({required this.id, required this.title, required this.body, required this.audience, required this.sentAt, this.isDraft = false});
}

final _announcements = [
  _Announcement(id: '1', title: '🎉 New Feature: Flash Sales', body: 'We\'re excited to launch Flash Sales! Check out limited-time deep discounts on food rescue items.', audience: 'All Users', sentAt: DateTime.now().subtract(const Duration(days: 1))),
  _Announcement(id: '2', title: '⚡ App Update Available', body: 'Version 2.0 is here with performance improvements and new features. Please update your app.', audience: 'All Users', sentAt: DateTime.now().subtract(const Duration(days: 3))),
  _Announcement(id: '3', title: '🏪 New Vendors in Thamel', body: 'Exciting news! 5 new vendors have joined Food Rescue Nepal in the Thamel area.', audience: 'Customers', sentAt: DateTime.now().subtract(const Duration(days: 7))),
  _Announcement(id: '4', title: '📊 Weekly Performance Report', body: 'Dear vendors, your weekly analytics report is ready. Check your dashboard for insights.', audience: 'Vendors', isDraft: true, sentAt: DateTime.now()),
];

class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primaryMedium,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('New Announcement', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnnouncementStats(),
          const SizedBox(height: 16),
          if (_announcements.any((a) => a.isDraft)) ...[
            Text('Drafts', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            ..._announcements.where((a) => a.isDraft).map((a) => _AnnouncementCard(a: a)),
            const SizedBox(height: 16),
          ],
          Text('Sent', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          ..._announcements.where((a) => !a.isDraft).map((a) => _AnnouncementCard(a: a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String audience = 'All Users';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Create Announcement', style: AppTextStyles.h5),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: audience,
            decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
            items: ['All Users', 'Customers', 'Vendors'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setSt(() => audience = v!),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save Draft'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement sent!'))); },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send Now'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white),
            )),
          ]),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }
}

class _AnnouncementStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    _AStat(value: '${_announcements.where((a) => !a.isDraft).length}', label: 'Sent', icon: Icons.send_rounded, color: AppColors.primaryMedium),
    const SizedBox(width: 10),
    _AStat(value: '${_announcements.where((a) => a.isDraft).length}', label: 'Drafts', icon: Icons.drafts_rounded, color: Colors.orange),
    const SizedBox(width: 10),
    const _AStat(value: '4,821', label: 'Reached', icon: Icons.people_rounded, color: Colors.blue),
  ]);
}

class _AStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _AStat({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h5.copyWith(color: AppColors.primaryDark)),
        Text(label, style: AppTextStyles.caption),
      ]),
    ),
  );
}

class _AnnouncementCard extends StatelessWidget {
  final _Announcement a;
  const _AnnouncementCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final audienceColor = a.audience == 'All Users' ? AppColors.primaryMedium : a.audience == 'Customers' ? Colors.blue : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: a.isDraft ? Border.all(color: Colors.orange.withValues(alpha: 0.4), style: BorderStyle.solid) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a.title, style: AppTextStyles.label)),
          if (a.isDraft)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Text('DRAFT', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 6),
        Text(a.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: audienceColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(a.audience, style: TextStyle(fontSize: 10, color: audienceColor, fontWeight: FontWeight.w600))),
          const Spacer(),
          Text(a.isDraft ? 'Draft' : '${DateTime.now().difference(a.sentAt).inDays}d ago', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}
