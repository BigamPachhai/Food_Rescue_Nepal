import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _Report {
  final String id, type, description, reporterName, targetName;
  final DateTime createdAt;
  final String status;
  const _Report({required this.id, required this.type, required this.description, required this.reporterName, required this.targetName, required this.createdAt, required this.status});
}

final _reports = [
  _Report(id: '1', type: 'VENDOR', description: 'Vendor did not provide the items listed in the listing', reporterName: 'Sita S.', targetName: 'Fast Food Corner', createdAt: DateTime.now().subtract(const Duration(hours: 2)), status: 'PENDING'),
  _Report(id: '2', type: 'LISTING', description: 'Photos do not match actual food quality', reporterName: 'Ram T.', targetName: 'Surprise Bag #142', createdAt: DateTime.now().subtract(const Duration(hours: 5)), status: 'PENDING'),
  _Report(id: '3', type: 'OTHER', description: 'Inappropriate content in vendor description', reporterName: 'Gita R.', targetName: 'Street Bites', createdAt: DateTime.now().subtract(const Duration(days: 1)), status: 'RESOLVED'),
  _Report(id: '4', type: 'VENDOR', description: 'Order was not ready at pickup time', reporterName: 'Hari G.', targetName: 'Himalayan Bakes', createdAt: DateTime.now().subtract(const Duration(days: 2)), status: 'RESOLVED'),
];

final _moderationFilterProvider = StateProvider<String>((ref) => 'PENDING');

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_moderationFilterProvider);
    final filtered = _reports.where((r) => r.status == filter).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Content Moderation'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _SummaryBar(),
          _FilterRow(filter: filter, onFilter: (f) => ref.read(_moderationFilterProvider.notifier).state = f),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.primaryMedium),
                    const SizedBox(height: 12),
                    Text('No $filter reports', style: AppTextStyles.h5),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ReportCard(report: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pending = _reports.where((r) => r.status == 'PENDING').length;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(children: [
        _SBar(label: 'Pending', value: '$pending', color: Colors.orange),
        const SizedBox(width: 12),
        _SBar(label: 'Resolved', value: '${_reports.where((r) => r.status == 'RESOLVED').length}', color: Colors.green),
        const SizedBox(width: 12),
        _SBar(label: 'Total', value: '${_reports.length}', color: AppColors.primaryMedium),
      ]),
    );
  }
}

class _SBar extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SBar({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: AppTextStyles.h5.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ]),
    ),
  );
}

class _FilterRow extends StatelessWidget {
  final String filter;
  final void Function(String) onFilter;
  const _FilterRow({required this.filter, required this.onFilter});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: ['PENDING', 'RESOLVED', 'DISMISSED'].map((f) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(f.toLowerCase().replaceAll('_', ' ').toUpperCase()), selected: filter == f, onSelected: (_) => onFilter(f), selectedColor: AppColors.primaryMedium.withValues(alpha: 0.2)),
    )).toList()),
  );
}

class _ReportCard extends StatelessWidget {
  final _Report report;
  const _ReportCard({required this.report});

  Color get _typeColor => report.type == 'VENDOR' ? Colors.orange : report.type == 'LISTING' ? Colors.blue : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: report.status == 'PENDING' ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(report.type, style: TextStyle(fontSize: 11, color: _typeColor, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(report.targetName, style: AppTextStyles.label, overflow: TextOverflow.ellipsis)),
          if (report.status == 'PENDING')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Text('PENDING', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 8),
        Text(report.description, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('Reported by ${report.reporterName}', style: AppTextStyles.caption),
          const Spacer(),
          Text('${DateTime.now().difference(report.createdAt).inHours}h ago', style: AppTextStyles.caption),
        ]),
        if (report.status == 'PENDING') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text('Dismiss'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white), child: const Text('Take Action'))),
          ]),
        ],
      ]),
    );
  }
}
