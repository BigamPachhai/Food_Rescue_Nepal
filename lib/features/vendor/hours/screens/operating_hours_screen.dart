import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class _DaySchedule {
  final String day;
  final bool isOpen;
  final TimeOfDay openTime, closeTime;
  final bool isHoliday;
  const _DaySchedule({required this.day, required this.isOpen, required this.openTime, required this.closeTime, this.isHoliday = false});
  _DaySchedule copyWith({bool? isOpen, TimeOfDay? openTime, TimeOfDay? closeTime, bool? isHoliday}) =>
      _DaySchedule(day: day, isOpen: isOpen ?? this.isOpen, openTime: openTime ?? this.openTime, closeTime: closeTime ?? this.closeTime, isHoliday: isHoliday ?? this.isHoliday);
}

final _scheduleProvider = StateNotifierProvider<_ScheduleNotifier, List<_DaySchedule>>((ref) => _ScheduleNotifier());

class _ScheduleNotifier extends StateNotifier<List<_DaySchedule>> {
  _ScheduleNotifier() : super([
    const _DaySchedule(day: 'Monday', isOpen: true, openTime: TimeOfDay(hour: 7, minute: 0), closeTime: TimeOfDay(hour: 20, minute: 0)),
    const _DaySchedule(day: 'Tuesday', isOpen: true, openTime: TimeOfDay(hour: 7, minute: 0), closeTime: TimeOfDay(hour: 20, minute: 0)),
    const _DaySchedule(day: 'Wednesday', isOpen: true, openTime: TimeOfDay(hour: 7, minute: 0), closeTime: TimeOfDay(hour: 20, minute: 0)),
    const _DaySchedule(day: 'Thursday', isOpen: true, openTime: TimeOfDay(hour: 7, minute: 0), closeTime: TimeOfDay(hour: 20, minute: 0)),
    const _DaySchedule(day: 'Friday', isOpen: true, openTime: TimeOfDay(hour: 7, minute: 0), closeTime: TimeOfDay(hour: 21, minute: 0)),
    const _DaySchedule(day: 'Saturday', isOpen: true, openTime: TimeOfDay(hour: 8, minute: 0), closeTime: TimeOfDay(hour: 21, minute: 0)),
    const _DaySchedule(day: 'Sunday', isOpen: false, openTime: TimeOfDay(hour: 8, minute: 0), closeTime: TimeOfDay(hour: 18, minute: 0)),
  ]);

  void toggle(int index) {
    final list = [...state];
    list[index] = list[index].copyWith(isOpen: !list[index].isOpen);
    state = list;
  }

  void updateTime(int index, TimeOfDay open, TimeOfDay close) {
    final list = [...state];
    list[index] = list[index].copyWith(openTime: open, closeTime: close);
    state = list;
  }
}

class OperatingHoursScreen extends ConsumerWidget {
  const OperatingHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(_scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Operating Hours'),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hours saved!'))),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(),
          const SizedBox(height: 16),
          Text('Weekly Schedule', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          ...schedule.asMap().entries.map((e) => _DayCard(
            schedule: e.value,
            index: e.key,
            onToggle: () => ref.read(_scheduleProvider.notifier).toggle(e.key),
            onEditTime: () async {
              final open = await showTimePicker(context: context, initialTime: e.value.openTime);
              if (open == null || !context.mounted) return;
              final close = await showTimePicker(context: context, initialTime: e.value.closeTime);
              if (close == null) return;
              ref.read(_scheduleProvider.notifier).updateTime(e.key, open, close);
            },
          )),
          const SizedBox(height: 16),
          _HolidaySection(),
          const SizedBox(height: 16),
          _SpecialHoursCard(),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.primaryMedium),
      const SizedBox(width: 10),
      Expanded(child: Text('Customers can only order during your operating hours. Set accurate times to avoid missed orders.', style: AppTextStyles.bodySmall)),
    ]),
  );
}

class _DayCard extends StatelessWidget {
  final _DaySchedule schedule;
  final int index;
  final VoidCallback onToggle, onEditTime;
  const _DayCard({required this.schedule, required this.index, required this.onToggle, required this.onEditTime});

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? "AM" : "PM"}';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      SizedBox(width: 90, child: Text(schedule.day, style: AppTextStyles.label.copyWith(color: schedule.isOpen ? AppColors.textPrimary : AppColors.textSecondary))),
      Switch(value: schedule.isOpen, onChanged: (_) => onToggle()),
      const SizedBox(width: 8),
      if (schedule.isOpen) ...[
        Expanded(
          child: GestureDetector(
            onTap: onEditTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${_fmt(schedule.openTime)} — ${_fmt(schedule.closeTime)}', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEditTime),
      ] else
        Expanded(child: Text('Closed', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
    ]),
  );
}

class _HolidaySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upcoming Holidays', style: AppTextStyles.h5),
      const SizedBox(height: 12),
      const _HolidayRow(name: 'Dashain', date: 'Oct 12–14', isClosed: true),
      const _HolidayRow(name: 'Tihar', date: 'Oct 29–Nov 2', isClosed: false),
      const _HolidayRow(name: 'New Year', date: 'Jan 1', isClosed: false),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('Add Holiday')),
    ]),
  );
}

class _HolidayRow extends StatelessWidget {
  final String name, date;
  final bool isClosed;
  const _HolidayRow({required this.name, required this.date, required this.isClosed});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      const Icon(Icons.event_rounded, size: 18, color: Colors.orange),
      const SizedBox(width: 8),
      Expanded(child: Text(name, style: AppTextStyles.bodySmall)),
      Text(date, style: AppTextStyles.caption),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: (isClosed ? Colors.red : Colors.green).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(isClosed ? 'Closed' : 'Open', style: TextStyle(fontSize: 11, color: isClosed ? Colors.red : Colors.green.shade700)),
      ),
    ]),
  );
}

class _SpecialHoursCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Special Hours', style: AppTextStyles.h5),
      const SizedBox(height: 8),
      Text('Set different hours for specific dates (e.g. festival sales, special events)', style: AppTextStyles.bodySmall),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Add Special Hours'),
      )),
    ]),
  );
}
