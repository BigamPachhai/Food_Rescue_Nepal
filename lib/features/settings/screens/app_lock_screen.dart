import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPinKey = 'app_lock_pin';

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) => AppLockNotifier());

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kPinKey) != null;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinKey, pin);
    state = true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPinKey);
    state = false;
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPinKey) == pin;
  }
}

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showSetPin = false;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (_pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be at least 4 digits')));
      return;
    }
    if (_pinCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }
    await ref.read(appLockProvider.notifier).setPin(_pinCtrl.text);
    _pinCtrl.clear();
    _confirmCtrl.clear();
    setState(() => _showSetPin = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final isPinSet = ref.watch(appLockProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('App Lock')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(child: Text('Protect your account with a 4–6 digit PIN.', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('PIN Lock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (isPinSet && !_showSetPin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(child: Text('PIN is set. Your account is protected.', style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _showSetPin = true), child: const Text('Change PIN'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(appLockProvider.notifier).removePin();
                    messenger.showSnackBar(const SnackBar(content: Text('PIN removed')));
                  },
                  child: const Text('Remove PIN'),
                )),
              ]),
            ] else if (_showSetPin || !isPinSet) ...[
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: _obscurePin,
                decoration: InputDecoration(
                  labelText: isPinSet ? 'New PIN (4–6 digits)' : 'Set PIN (4–6 digits)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePin = !_obscurePin)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                if (_showSetPin) ...[
                  Expanded(child: OutlinedButton(onPressed: () { setState(() => _showSetPin = false); _pinCtrl.clear(); _confirmCtrl.clear(); }, child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                ],
                Expanded(child: FilledButton(onPressed: _savePin, child: const Text('Set PIN'))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
