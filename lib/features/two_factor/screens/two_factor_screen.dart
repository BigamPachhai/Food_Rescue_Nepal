import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

final twoFactorStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.twoFaStatus);
  final raw = res.data as Map<String, dynamic>;
  return raw['data'] as Map<String, dynamic>? ?? {};
});

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _tokenCtrl = TextEditingController();
  String? _setupSecret;
  bool _loading = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.post(ApiEndpoints.twoFaSetup);
      final raw = res.data as Map<String, dynamic>;
      final data = raw['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _setupSecret = data['secret'] as String?;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _enable() async {
    final token = _tokenCtrl.text.trim();
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code from your authenticator app')));
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.twoFaEnable, data: {'token': token});
      ref.invalidate(twoFactorStatusProvider);
      _tokenCtrl.clear();
      setState(() { _setupSecret = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA enabled successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid code: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _disable() async {
    final token = _tokenCtrl.text.trim();
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code to confirm disable')));
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.twoFaDisable, data: {'token': token});
      ref.invalidate(twoFactorStatusProvider);
      _tokenCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA disabled')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid code: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(twoFactorStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (status) {
          final isEnabled = status['isEnabled'] as bool? ?? false;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isEnabled ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isEnabled ? Colors.green : Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(isEnabled ? Icons.shield : Icons.shield_outlined, color: isEnabled ? Colors.green : Colors.orange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isEnabled ? '2FA is Active' : '2FA is Inactive', style: TextStyle(fontWeight: FontWeight.bold, color: isEnabled ? Colors.green[800] : Colors.orange[800])),
                            Text(isEnabled ? 'Your account is protected with TOTP' : 'Enable 2FA for stronger account security', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isEnabled) ...[
                  const Text('How it works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const _Step(n: '1', text: 'Install an authenticator app (Google Authenticator, Authy, etc.)'),
                  const _Step(n: '2', text: 'Tap "Set up 2FA" below to get your secret key'),
                  const _Step(n: '3', text: 'Enter the key in your authenticator app'),
                  const _Step(n: '4', text: 'Enter the 6-digit code to verify and enable'),
                  const SizedBox(height: 24),

                  if (_setupSecret != null) ...[
                    const Text('Your Secret Key', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(child: Text(_setupSecret!, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 2))),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _setupSecret!));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret copied')));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tokenCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: 'Verification Code', hintText: '6-digit code', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _enable,
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enable 2FA'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Set Up 2FA'),
                        onPressed: _loading ? null : _setup,
                      ),
                    ),
                ] else ...[
                  const Text('Disable 2FA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Enter your current authenticator code to disable 2FA.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Verification Code', hintText: '6-digit code', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _loading ? null : _disable,
                      child: const Text('Disable 2FA'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, child: Text(n, style: const TextStyle(fontSize: 11))),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
