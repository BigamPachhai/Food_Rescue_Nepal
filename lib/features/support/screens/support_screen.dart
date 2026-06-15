import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.h6.copyWith(color: Colors.white, fontSize: 12),
          unselectedLabelStyle:
              AppTextStyles.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _FaqTab(),
          _ContactTab(),
          _ReportTab(),
        ],
      ),
    );
  }
}

// ─── FAQ Tab ───────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const _faqs = [
    (
      'How do I reserve food?',
      'Browse listings on the home screen, tap a listing to view details, then choose your quantity and tap "Reserve Now". Payment is cash on pickup — no upfront payment required.',
    ),
    (
      'Can I cancel my reservation?',
      'Yes. You can cancel a reservation within 10 minutes of placing it. Go to My Orders, open the order, and tap "Cancel Order". After 10 minutes, cancellations are not allowed.',
    ),
    (
      'How do I pick up my order?',
      'When your order is confirmed, go to My Orders and tap "Show QR Code". The vendor will scan this QR code when you arrive for pickup. Make sure to arrive within the pickup window.',
    ),
    (
      'What if a vendor doesn\'t show up or the food isn\'t as described?',
      'Please use the Report feature to flag the listing or vendor. Our team reviews all reports within 24 hours. You can also contact us directly via the Contact tab.',
    ),
    (
      'How are prices determined?',
      'Prices are set by vendors and represent discounted rates from the original price. Food Rescue Nepal does not take a commission — 100% of the payment goes to the vendor.',
    ),
    (
      'Is the food safe to eat?',
      'All vendors must agree to our food safety guidelines. Food is typically surplus from the same day and stored properly. If a listing has quality concerns, the vendor adds condition notes.',
    ),
    (
      'How do I become a vendor?',
      'Download the app and sign up as a vendor. You\'ll need to provide your business name, type, address, and contact details. Our team reviews your application within 1–2 business days.',
    ),
    (
      'How do I add food to favorites?',
      'Tap the heart icon (♡) on any listing to add it to your favorites. Find all saved listings under the Favorites tab.',
    ),
    (
      'Why can\'t I write a review?',
      'Reviews are only available for orders with PICKED_UP status. Once you pick up your order and the vendor marks it as picked up, the review option will appear on your order details.',
    ),
    (
      'How do I save a vendor to favorites?',
      'From the Favorites screen, go to the "Vendors" tab. You can also find the save option by visiting a vendor\'s reviews or profile page.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _faqs.length,
      itemBuilder: (_, i) => _FaqTile(
        question: _faqs[i].$1,
        answer: _faqs[i].$2,
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Q',
                  style: TextStyle(
                      color: AppColors.primaryMedium, fontWeight: FontWeight.bold)),
            ),
          ),
          title: Text(
            widget.question,
            style: AppTextStyles.h6.copyWith(
              fontWeight: _expanded ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          iconColor: AppColors.primaryMedium,
          collapsedIconColor: AppColors.textSecondary,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Text(widget.answer, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── Contact Tab ───────────────────────────────────────────────────────────

class _ContactTab extends ConsumerStatefulWidget {
  const _ContactTab();

  @override
  ConsumerState<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends ConsumerState<_ContactTab> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      context.showErrorSnackBar('Please fill in all fields');
      return;
    }
    setState(() => _isSending = true);
    try {
      // Submit as a report with type=SUPPORT
      await ref.read(dioClientProvider).post(ApiEndpoints.reports, data: {
        'type': 'SUPPORT',
        'reason': subject,
        'description': message,
      });
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 44, color: AppColors.primaryMedium),
              ),
              const SizedBox(height: 20),
              Text('Message Sent!', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Our support team will get back to you within 24 hours.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ContactInfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'support@foodrescuenepal.com',
          ),
          const SizedBox(height: 8),
          const _ContactInfoCard(
            icon: Icons.access_time,
            label: 'Response time',
            value: 'Within 24 hours',
          ),
          const SizedBox(height: 24),
          Text('Send us a message', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          const _FieldLabel('Subject'),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectCtrl,
            decoration: _inputDecoration('e.g. Order issue, App bug, Feedback…'),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Message'),
          const SizedBox(height: 6),
          TextField(
            controller: _messageCtrl,
            maxLines: 6,
            maxLength: 1000,
            decoration: _inputDecoration('Describe your issue or question…'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined),
              label: Text(_isSending ? 'Sending…' : 'Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMedium,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryMedium),
        ),
        contentPadding: const EdgeInsets.all(14),
      );
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryMedium, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.h6);
  }
}

// ─── Report Tab ────────────────────────────────────────────────────────────

class _ReportTab extends ConsumerStatefulWidget {
  const _ReportTab();

  @override
  ConsumerState<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends ConsumerState<_ReportTab> {
  String _type = 'OTHER';
  String? _selectedReason;
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  static const _typeLabels = {
    'VENDOR': ('Store', Icons.store_outlined),
    'LISTING': ('Food Listing', Icons.fastfood_outlined),
    'OTHER': ('General Issue', Icons.flag_outlined),
  };

  static const _reasons = {
    'VENDOR': [
      'Food quality not as described',
      'Vendor was rude or unprofessional',
      'Vendor didn\'t show up',
      'Suspected fraud or scam',
      'Other',
    ],
    'LISTING': [
      'Photos are misleading',
      'Price discrepancy',
      'Food was expired or unsafe',
      'Listing is a duplicate',
      'Other',
    ],
    'OTHER': [
      'App bug or technical issue',
      'Inappropriate content',
      'Privacy concern',
      'Other',
    ],
  };

  @override
  void dispose() {
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      context.showErrorSnackBar('Please select a reason');
      return;
    }
    setState(() => _isSending = true);
    try {
      await ref.read(dioClientProvider).post(ApiEndpoints.reports, data: {
        'type': _type,
        'targetId': _targetCtrl.text.trim().isEmpty ? null : _targetCtrl.text.trim(),
        'reason': _selectedReason,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.errorSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined,
                    size: 44, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              Text('Report Submitted', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Thank you for helping keep Food Rescue Nepal safe. Our team will review your report within 24 hours.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final reasons = _reasons[_type] ?? _reasons['OTHER']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you reporting?', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          // Type selector
          Row(
            children: _typeLabels.entries.map((e) {
              final selected = _type == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _type = e.key;
                    _selectedReason = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryMedium : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryMedium
                            : AppColors.neutral300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(e.value.$2,
                            color: selected ? Colors.white : AppColors.textSecondary,
                            size: 22),
                        const SizedBox(height: 4),
                        Text(
                          e.value.$1,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Optional target ID
          if (_type != 'OTHER') ...[
            Text(
              _type == 'VENDOR' ? 'Vendor Name (optional)' : 'Listing Title (optional)',
              style: AppTextStyles.h6,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _targetCtrl,
              decoration: InputDecoration(
                hintText: _type == 'VENDOR'
                    ? 'e.g. Momo House Thamel'
                    : 'e.g. Veg Momo Set',
                hintStyle: AppTextStyles.bodySmall,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Reason
          Text('Reason', style: AppTextStyles.h6),
          const SizedBox(height: 8),
          ...reasons.map((r) => InkWell(
                onTap: () => setState(() => _selectedReason = r),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _selectedReason == r
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: _selectedReason == r
                            ? AppColors.primaryMedium
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r, style: AppTextStyles.bodySmall),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          // Description
          Text('Additional details (optional)', style: AppTextStyles.h6),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Provide any additional context…',
              hintStyle: AppTextStyles.bodySmall,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryMedium),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _submit,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.flag_outlined),
              label: Text(_isSending ? 'Submitting…' : 'Submit Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
