import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class PickupCalendarScreen extends StatefulWidget {
  const PickupCalendarScreen({super.key});

  @override
  State<PickupCalendarScreen> createState() => _PickupCalendarScreenState();
}

class _PickupCalendarScreenState extends State<PickupCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock upcoming pickups keyed by day-of-month
  final Map<int, List<_PickupEvent>> _events = {
    DateTime.now().day: const [
      _PickupEvent('Himalayan Bakehouse', 'Surprise Bakery Box', '5:00–6:00 PM', 'NPR 250', false),
    ],
    DateTime.now().day + 2: const [
      _PickupEvent('Green Valley Kitchen', 'Veg Meal Box', '12:00–1:00 PM', 'NPR 180', false),
      _PickupEvent('Thamel Deli', 'Sandwich Set', '6:00–7:00 PM', 'NPR 150', false),
    ],
    DateTime.now().day - 3: const [
      _PickupEvent('Mountain Fresh', 'Fresh Fruits Box', '4:00–5:00 PM', 'NPR 200', true),
    ],
  };

  List<_PickupEvent> get _selectedEvents {
    if (_selectedDay == null) return _events[DateTime.now().day] ?? [];
    return _events[_selectedDay!.day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Pickup Calendar')),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            _CalendarHeader(focusedDay: _focusedDay, onPrev: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)), onNext: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
            const SizedBox(height: 8),
            _CalendarGrid(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              eventDays: _events.keys.toSet(),
              onDaySelected: (day) => setState(() => _selectedDay = day),
              today: now,
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text(
              _selectedDay == null ? 'Today\'s Pickups' : '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: AppTextStyles.h5,
            ),
            const Spacer(),
            Text('${_selectedEvents.length} scheduled', style: AppTextStyles.caption),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedEvents.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.event_available_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('No pickups on this day', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedEvents.length,
                  itemBuilder: (_, i) => _PickupCard(event: _selectedEvents[i]),
                ),
        ),
        _Legend(),
      ]),
    );
  }
}

class _PickupEvent {
  final String vendor, item, time, price;
  final bool completed;
  const _PickupEvent(this.vendor, this.item, this.time, this.price, this.completed);
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onPrev, onNext;
  const _CalendarHeader({required this.focusedDay, required this.onPrev, required this.onNext});

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
    Expanded(child: Text('${_months[focusedDay.month - 1]} ${focusedDay.year}', style: AppTextStyles.h5, textAlign: TextAlign.center)),
    IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
  ]);
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Set<int> eventDays;
  final void Function(DateTime) onDaySelected;
  final DateTime today;

  const _CalendarGrid({required this.focusedDay, required this.selectedDay, required this.eventDays, required this.onDaySelected, required this.today});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    return Column(children: [
      Row(children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600))))).toList()),
      const SizedBox(height: 4),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
        itemCount: startOffset + daysInMonth,
        itemBuilder: (_, i) {
          if (i < startOffset) return const SizedBox();
          final day = i - startOffset + 1;
          final date = DateTime(focusedDay.year, focusedDay.month, day);
          final isToday = day == today.day && focusedDay.month == today.month && focusedDay.year == today.year;
          final isSelected = selectedDay != null && selectedDay!.day == day && selectedDay!.month == focusedDay.month;
          final hasEvent = eventDays.contains(day);

          return GestureDetector(
            onTap: () => onDaySelected(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryMedium : isToday ? AppColors.primaryMedium.withValues(alpha: 0.15) : null,
                shape: BoxShape.circle,
              ),
              child: Stack(alignment: Alignment.center, children: [
                Text('$day', style: TextStyle(
                  color: isSelected ? Colors.white : isToday ? AppColors.primaryMedium : AppColors.textPrimary,
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                )),
                if (hasEvent && !isSelected)
                  Positioned(bottom: 4, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}

class _PickupCard extends StatelessWidget {
  final _PickupEvent event;
  const _PickupCard({required this.event});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border(left: BorderSide(color: event.completed ? Colors.green : AppColors.primaryMedium, width: 4)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.vendor, style: AppTextStyles.label),
        const SizedBox(height: 2),
        Text(event.item, style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(event.time, style: AppTextStyles.caption),
          const SizedBox(width: 12),
          const Icon(Icons.payment_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(event.price, style: AppTextStyles.caption),
        ]),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (event.completed ? Colors.green : AppColors.primaryMedium).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(event.completed ? 'Done' : 'Upcoming', style: TextStyle(color: event.completed ? Colors.green : AppColors.primaryMedium, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryMedium, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('Today', style: AppTextStyles.caption),
      const SizedBox(width: 16),
      const Icon(Icons.circle, size: 8, color: Colors.orange),
      const SizedBox(width: 4),
      Text('Has pickups', style: AppTextStyles.caption),
      const SizedBox(width: 16),
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('Completed', style: AppTextStyles.caption),
    ]),
  );
}
