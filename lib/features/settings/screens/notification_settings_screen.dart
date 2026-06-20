import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _NotifSetting {
  final String key, title, subtitle, category;
  const _NotifSetting({required this.key, required this.title, required this.subtitle, required this.category});
}

const _settings = [
  _NotifSetting(key: 'notif_new_listing', title: 'New Listings', subtitle: 'When new food items are listed nearby', category: 'Listings'),
  _NotifSetting(key: 'notif_flash_sale', title: 'Flash Sales', subtitle: 'When limited-time flash deals go live', category: 'Listings'),
  _NotifSetting(key: 'notif_fav_vendor', title: 'Favourite Vendor Updates', subtitle: 'When your favourite vendors add new items', category: 'Listings'),
  _NotifSetting(key: 'notif_order_status', title: 'Order Status Updates', subtitle: 'When your order is accepted, ready, or completed', category: 'Orders'),
  _NotifSetting(key: 'notif_pickup_reminder', title: 'Pickup Reminders', subtitle: '30 minutes before your pickup window', category: 'Orders'),
  _NotifSetting(key: 'notif_order_cancelled', title: 'Order Cancellations', subtitle: 'When your order is cancelled or rejected', category: 'Orders'),
  _NotifSetting(key: 'notif_achievement', title: 'Achievements', subtitle: 'When you unlock a new badge or achievement', category: 'Rewards'),
  _NotifSetting(key: 'notif_streak', title: 'Streak Reminders', subtitle: 'Daily reminder to keep your rescue streak alive', category: 'Rewards'),
  _NotifSetting(key: 'notif_points', title: 'Points Earned', subtitle: 'When you earn or are about to lose points', category: 'Rewards'),
  _NotifSetting(key: 'notif_challenge', title: 'Challenge Updates', subtitle: 'Progress updates on weekly and monthly challenges', category: 'Rewards'),
  _NotifSetting(key: 'notif_review_req', title: 'Review Requests', subtitle: 'Reminder to review your completed orders', category: 'Community'),
  _NotifSetting(key: 'notif_community', title: 'Community Posts', subtitle: 'Activity from the food rescue community', category: 'Community'),
  _NotifSetting(key: 'notif_announcements', title: 'Platform Announcements', subtitle: 'Important updates from Food Rescue Nepal', category: 'Community'),
];

final _notifPrefsProvider = StateNotifierProvider<_NotifPrefsNotifier, Map<String, bool>>((ref) => _NotifPrefsNotifier());

class _NotifPrefsNotifier extends StateNotifier<Map<String, bool>> {
  _NotifPrefsNotifier() : super({}) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final s in _settings) {
      map[s.key] = prefs.getBool(s.key) ?? true;
    }
    state = map;
  }

  Future<void> toggle(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !(state[key] ?? true);
    await prefs.setBool(key, newVal);
    state = {...state, key: newVal};
  }

  Future<void> setAll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final s in _settings) {
      await prefs.setBool(s.key, value);
      map[s.key] = value;
    }
    state = map;
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(_notifPrefsProvider);
    final categories = _settings.map((s) => s.category).toSet().toList();
    final allOn = prefs.values.every((v) => v);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: () => ref.read(_notifPrefsProvider.notifier).setAll(!allOn),
            child: Text(allOn ? 'Disable All' : 'Enable All', style: const TextStyle(color: AppColors.primaryMedium)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MasterToggle(allOn: allOn, onToggle: () => ref.read(_notifPrefsProvider.notifier).setAll(!allOn)),
          const SizedBox(height: 16),
          ...categories.map((cat) {
            final catSettings = _settings.where((s) => s.category == cat).toList();
            return _CategorySection(
              title: cat,
              settings: catSettings,
              prefs: prefs,
              onToggle: (key) => ref.read(_notifPrefsProvider.notifier).toggle(key),
            );
          }),
          _QuietHoursCard(),
        ],
      ),
    );
  }
}

class _MasterToggle extends StatelessWidget {
  final bool allOn;
  final VoidCallback onToggle;
  const _MasterToggle({required this.allOn, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: allOn ? AppColors.primaryMedium : AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Icon(allOn ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: allOn ? Colors.white : AppColors.textSecondary, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Push Notifications', style: AppTextStyles.label.copyWith(color: allOn ? Colors.white : AppColors.textPrimary)),
        Text(allOn ? 'All notifications enabled' : 'All notifications disabled', style: AppTextStyles.caption.copyWith(color: allOn ? Colors.white70 : AppColors.textSecondary)),
      ])),
      Switch(value: allOn, onChanged: (_) => onToggle()),
    ]),
  );
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<_NotifSetting> settings;
  final Map<String, bool> prefs;
  final void Function(String) onToggle;
  const _CategorySection({required this.title, required this.settings, required this.prefs, required this.onToggle});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppTextStyles.h5),
    const SizedBox(height: 8),
    Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: () {
        final items = <Widget>[];
        for (int i = 0; i < settings.length; i++) {
          items.add(SwitchListTile(
            title: Text(settings[i].title, style: AppTextStyles.label),
            subtitle: Text(settings[i].subtitle, style: AppTextStyles.caption),
            value: prefs[settings[i].key] ?? true,
            onChanged: (_) => onToggle(settings[i].key),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ));
          if (i < settings.length - 1) items.add(const Divider(height: 1, indent: 16));
        }
        return items;
      }()),
    ),
    const SizedBox(height: 16),
  ]);
}

class _QuietHoursCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.bedtime_rounded, color: AppColors.primaryMedium),
        const SizedBox(width: 8),
        Text('Quiet Hours', style: AppTextStyles.h5),
      ]),
      const SizedBox(height: 8),
      Text('Pause non-urgent notifications during specific hours', style: AppTextStyles.bodySmall),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('10:00 PM'))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('7:00 AM'))),
      ]),
      const SizedBox(height: 8),
      SwitchListTile(
        title: const Text('Enable Quiet Hours'),
        value: false,
        onChanged: (_) {},
        contentPadding: EdgeInsets.zero,
      ),
    ]),
  );
}
