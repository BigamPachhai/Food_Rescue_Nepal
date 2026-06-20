import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class ReferralData {
  final String code;
  final int totalReferrals;
  final int totalBonusPoints;
  const ReferralData({required this.code, required this.totalReferrals, required this.totalBonusPoints});
  factory ReferralData.fromJson(Map<String, dynamic> j) => ReferralData(
        code: j['code'] as String? ?? '',
        totalReferrals: (j['totalReferrals'] as num?)?.toInt() ?? 0,
        totalBonusPoints: (j['totalBonusPoints'] as num?)?.toInt() ?? 0,
      );
}

final referralProvider = FutureProvider<ReferralData>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.referralMyCode);
  final raw = res.data as Map<String, dynamic>;
  return ReferralData.fromJson(raw['data'] as Map<String, dynamic>? ?? {});
});

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeCtrl = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.referralApply, data: {'code': code});
      ref.invalidate(referralProvider);
      _codeCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code applied! +50 bonus points added.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid code: $e')));
    }
    setState(() => _applying = false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(referralProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text('Invite Friends, Earn Points!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Get 100 pts for every friend who joins.\nThey get 50 pts too!', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(data.code, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: colorScheme.primary)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: data.code));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Invite Link'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colorScheme.primary),
                      onPressed: () => Share.share('Join Food Rescue Nepal and save food! Use my code ${data.code} to get 50 bonus points. Download now: https://foodrescuenepal.com'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Row(children: [
                Expanded(child: _StatBox(value: '${data.totalReferrals}', label: 'Friends Referred')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(value: '${data.totalBonusPoints}', label: 'Points Earned')),
              ]),
              const SizedBox(height: 24),

              // Apply code
              const Text('Have a referral code?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'Enter referral code', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _applying ? null : _applyCode,
                  child: _applying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Apply'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
}
