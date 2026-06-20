import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _AuditEntry {
  final String id, actor, action, target, ip;
  final DateTime timestamp;
  final String severity;
  const _AuditEntry({required this.id, required this.actor, required this.action, required this.target, required this.ip, required this.timestamp, required this.severity});
}

final _logs = [
  _AuditEntry(id: 'A001', actor: 'admin@frn.app', action: 'SUSPENDED_VENDOR', target: 'Vendor #V-234', ip: '192.168.1.1', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), severity: 'warning'),
  _AuditEntry(id: 'A002', actor: 'System', action: 'AUTO_CANCELLED_ORDER', target: 'Order #ORD-889', ip: 'system', timestamp: DateTime.now().subtract(const Duration(minutes: 12)), severity: 'info'),
  _AuditEntry(id: 'A003', actor: 'admin@frn.app', action: 'DELETED_LISTING', target: 'Listing #L-561', ip: '192.168.1.1', timestamp: DateTime.now().subtract(const Duration(hours: 1)), severity: 'danger'),
  _AuditEntry(id: 'A004', actor: 'System', action: 'FLAGGED_REVIEW', target: 'Review #R-102', ip: 'system', timestamp: DateTime.now().subtract(const Duration(hours: 2)), severity: 'warning'),
  _AuditEntry(id: 'A005', actor: 'moderator@frn.app', action: 'DISMISSED_REPORT', target: 'Report #RPT-44', ip: '10.0.0.5', timestamp: DateTime.now().subtract(const Duration(hours: 3)), severity: 'info'),
  _AuditEntry(id: 'A006', actor: 'admin@frn.app', action: 'APPROVED_VENDOR', target: 'Vendor #V-289', ip: '192.168.1.1', timestamp: DateTime.now().subtract(const Duration(hours: 5)), severity: 'success'),
  _AuditEntry(id: 'A007', actor: 'System', action: 'SENT_ANNOUNCEMENT', target: 'All Users', ip: 'system', timestamp: DateTime.now().subtract(const Duration(hours: 8)), severity: 'info'),
  _AuditEntry(id: 'A008', actor: 'admin@frn.app', action: 'BANNED_USER', target: 'User #U-791', ip: '192.168.1.1', timestamp: DateTime.now().subtract(const Duration(days: 1)), severity: 'danger'),
];

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  String _filter = 'All';
  String _search = '';
  final _filters = ['All', 'danger', 'warning', 'info', 'success'];

  List<_AuditEntry> get _filtered => _logs.where((l) {
    final matchFilter = _filter == 'All' || l.severity == _filter;
    final matchSearch = _search.isEmpty || l.action.toLowerCase().contains(_search.toLowerCase()) || l.actor.toLowerCase().contains(_search.toLowerCase()) || l.target.toLowerCase().contains(_search.toLowerCase());
    return matchFilter && matchSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting audit log...')))),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search actions, actors, targets...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true, fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f == 'All' ? 'All' : f.toUpperCase()),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: _severityColor(f).withValues(alpha: 0.15),
                  checkmarkColor: _severityColor(f),
                  labelStyle: TextStyle(color: _filter == f ? _severityColor(f) : AppColors.textSecondary, fontSize: 11),
                ),
              )).toList()),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('${filtered.length} entries', style: AppTextStyles.caption),
            const Spacer(),
            Text('Live • Updates every 30s', style: AppTextStyles.caption.copyWith(color: Colors.green)),
            const SizedBox(width: 4),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _AuditCard(entry: filtered[i]),
          ),
        ),
      ]),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'danger': return Colors.red;
      case 'warning': return Colors.orange;
      case 'success': return Colors.green;
      default: return Colors.blue;
    }
  }
}

class _AuditCard extends StatelessWidget {
  final _AuditEntry entry;
  const _AuditCard({required this.entry});

  Color get _color {
    switch (entry.severity) {
      case 'danger': return Colors.red;
      case 'warning': return Colors.orange;
      case 'success': return Colors.green;
      default: return Colors.blue;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(entry.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: _color, width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(entry.action, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Text(_timeAgo(), style: AppTextStyles.caption),
      ]),
      const SizedBox(height: 6),
      Text(entry.target, style: AppTextStyles.label),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(entry.actor, style: AppTextStyles.caption),
        const SizedBox(width: 10),
        const Icon(Icons.router_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(entry.ip, style: AppTextStyles.caption),
      ]),
    ]),
  );
}
