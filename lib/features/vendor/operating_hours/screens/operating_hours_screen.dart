import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

const _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

class _HoursState {
  final int dayOfWeek;
  String openTime;
  String closeTime;
  bool isClosed;

  _HoursState({required this.dayOfWeek, required this.openTime, required this.closeTime, required this.isClosed});

  factory _HoursState.fromJson(Map<String, dynamic> json) => _HoursState(
        dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
        openTime: json['openTime'] as String? ?? '09:00',
        closeTime: json['closeTime'] as String? ?? '18:00',
        isClosed: json['isClosed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'openTime': openTime,
        'closeTime': closeTime,
        'isClosed': isClosed,
      };
}

class OperatingHoursScreen extends ConsumerStatefulWidget {
  const OperatingHoursScreen({super.key});

  @override
  ConsumerState<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends ConsumerState<OperatingHoursScreen> {
  List<_HoursState> _hours = List.generate(7, (i) => _HoursState(dayOfWeek: i, openTime: '09:00', closeTime: '18:00', isClosed: false));
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.myOperatingHours);
      final raw = response.data as Map<String, dynamic>;
      final data = raw['data'];
      if (data is List) {
        setState(() {
          _hours = data
              .map((e) => _HoursState.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put(ApiEndpoints.myOperatingHours, data: {'hours': _hours.map((h) => h.toJson()).toList()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operating hours saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _saving = false);
  }

  Future<void> _pickTime(int index, bool isOpen) async {
    final current = isOpen ? _hours[index].openTime : _hours[index].closeTime;
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpen) {
        _hours[index].openTime = formatted;
      } else {
        _hours[index].closeTime = formatted;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Hours'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final h = _hours[i];
                return ListTile(
                  title: Text(_days[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: h.isClosed
                      ? const Text('Closed', style: TextStyle(color: Colors.red))
                      : Text('${h.openTime} – ${h.closeTime}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!h.isClosed) ...[
                        TextButton(onPressed: () => _pickTime(i, true), child: Text(h.openTime)),
                        const Text('–'),
                        TextButton(onPressed: () => _pickTime(i, false), child: Text(h.closeTime)),
                      ],
                      Switch(
                        value: !h.isClosed,
                        onChanged: (v) => setState(() => _hours[i].isClosed = !v),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
