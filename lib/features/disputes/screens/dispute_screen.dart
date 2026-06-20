import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

const _reasons = [
  'Food quality issue',
  'Order not ready at pickup time',
  'Wrong items received',
  'Vendor was rude / unprofessional',
  'Pickup location was incorrect',
  'Other',
];

class DisputeScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DisputeScreen({super.key, required this.orderId});

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  String? _selectedReason;
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a reason')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.disputes, data: {
        'orderId': widget.orderId,
        'reason': _selectedReason,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute submitted. Our team will review it within 24 hours.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report an Issue')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What went wrong?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _selectedReason,
                onChanged: (v) => setState(() => _selectedReason = v),
                child: Column(
                  children: _reasons
                      .map((r) => RadioListTile<String>(
                            value: r,
                            title: Text(r),
                            dense: true,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Additional details (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in more detail…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Dispute'),
                ),
              ),
            ],
          ),
        ),
      );
}
