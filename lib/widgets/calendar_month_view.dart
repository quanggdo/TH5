import 'package:flutter/material.dart';
import '../models/habit_log_model.dart';

/// Widget hiển thị chế độ xem THÁNG.
/// Grid lịch tháng đầy đủ với indicator chấm cho ngày đã hoàn thành.
class CalendarMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final List<HabitLog> periodLogs;

  const CalendarMonthView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.periodLogs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    // Tạo Map date → có log hoàn thành
    final completedDates = <String, bool>{};
    final partialDates = <String, bool>{};
    for (final log in periodLogs) {
      if (log.isCompleted) {
        completedDates[log.date] = true;
      } else if (log.count > 0) {
        partialDates[log.date] = true;
      }
    }

    final firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Ngày bắt đầu hiển thị (Thứ 2 tuần đầu)
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final leadingEmptyDays = startWeekday - 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header tháng
            Row(
              children: [
                IconButton(
                  tooltip: 'Tháng trước',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final prevMonth = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                    onDateChanged(prevMonth);
                  },
                ),
                Expanded(
                  child: Text(
                    'Tháng ${selectedDate.month}, ${selectedDate.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tháng sau',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final nextMonth = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                    onDateChanged(nextMonth);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Header ngày trong tuần
            Row(
              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Grid ngày
            ..._buildWeekRows(
              context,
              colorScheme,
              today,
              daysInMonth,
              leadingEmptyDays,
              completedDates,
              partialDates,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekRows(
    BuildContext context,
    ColorScheme colorScheme,
    DateTime today,
    int daysInMonth,
    int leadingEmptyDays,
    Map<String, bool> completedDates,
    Map<String, bool> partialDates,
  ) {
    final rows = <Widget>[];
    int dayCounter = 1;

    // Tổng số ô cần render
    final totalSlots = leadingEmptyDays + daysInMonth;
    final totalRows = (totalSlots / 7).ceil();

    for (int row = 0; row < totalRows; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final slotIndex = row * 7 + col;
        if (slotIndex < leadingEmptyDays || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
          continue;
        }

        final day = dayCounter;
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, today);
        final dateStr = _dateStr(date);
        final hasCompleted = completedDates[dateStr] == true;
        final hasPartial = partialDates[dateStr] == true;

        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: () => onDateChanged(
                DateTime(date.year, date.month, date.day),
              ),
              child: SizedBox(
                height: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : isToday
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasCompleted
                            ? Colors.green
                            : hasPartial
                                ? Colors.orange
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        dayCounter++;
      }

      rows.add(Row(children: cells));
    }

    return rows;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
