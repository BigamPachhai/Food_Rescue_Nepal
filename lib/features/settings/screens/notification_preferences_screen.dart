import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class _PrefItem {
  final String key, title, subtitle;
  const _PrefItem({required this.key, required this.title, required this.subtitle});
}

const _prefItems = [
  _PrefItem(key: 'orderUpdates', title: 'Order Updates', subtitle: 'Ready for pickup, status changes'),
  _PrefItem(key: 'newListings', title: 'New Listings', subtitle: 'New food listings from your saved vendors'),
  _PrefItem(key: 'flashSales', title: 'Flash Sales', subtitle: 'Limited-time deals and discounts'),
  _PrefItem(key: 'chatMessages', title: 'Chat Messages', subtitle: 'New messages from vendors or customers'),
  _PrefItem(key: 'waitlistNotify', title: 'Waitlist Notifications', subtitle: 'When a listing you\'re waiting for is available'),
  _PrefItem(key: 'announcements', title: 'Announcements', subtitle: 'Platform news and important updates'),
  _PrefItem(key: 'loyaltyPoints', title: 'Loyalty Points', subtitle: 'Points earned, redeemed, or expiring'),
  _PrefItem(key: 'disputeUpdates', title: 'Dispute Updates', subtitle: 'Status changes on your disputes'),
];

final notificationPrefsProvider = FutureProvider<Map<String, bool>>((ref) async {
  try {
    final dio = ref.read(dioClientProvider);
    final res = await dio.get(ApiEndpoints.notificationPrefs);
    final raw = res.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return Map<String, bool>.from(data.map((k, v) => MapEntry(k, v as bool? ?? true)));
  } catch (_) {
    return {for (final p in _prefItems) p.key: true};
  }
});

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool>? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(notificationPrefsProvider.future).then((p) => setState(() => _prefs = Map.from(p)));
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put(ApiEndpoints.notificationPrefs, data: _prefs);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notification Preferences'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
        body: _prefs == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _prefItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (ctx, i) {
                  final item = _prefItems[i];
                  return SwitchListTile(
                    value: _prefs![item.key] ?? true,
                    onChanged: (v) => setState(() => _prefs![item.key] = v),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
      );
}
