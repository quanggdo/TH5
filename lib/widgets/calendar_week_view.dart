import 'package:flutter/material.dart';
import '../models/habit_log_model.dart';

/// Widget hiển thị chế độ xem TUẦN.
/// Hiển thị 7 ngày (Thứ 2 → CN) với indicator hoàn thành.
class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final List<HabitLog> periodLogs;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.periodLogs = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final weekday = selectedDate.weekday; // 1 = Monday
    final startOfWeek = selectedDate.subtract(Duration(days: weekday - 1));

    // Tạo Map date → có log hoàn thành hay không
    final completedDates = <String, bool>{};
    for (final log in periodLogs) {
      if (log.isCompleted) {
        completedDates[log.date] = true;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với điều hướng tuần
            Row(
              children: [
                IconButton(
                  tooltip: 'Tuần trước',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    onDateChanged(
                      selectedDate.subtract(const Duration(days: 7)),
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    _weekRangeLabel(startOfWeek),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tuần sau',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    onDateChanged(
                      selectedDate.add(const Duration(days: 7)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Grid 7 ngày
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final date = startOfWeek.add(Duration(days: index));
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, today);
                final dateStr = _dateStr(date);
                final hasCompleted = completedDates[dateStr] == true;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDateChanged(
                      DateTime(date.year, date.month, date.day),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _shortWeekday(index),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
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
                            '${date.day}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
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
                        const SizedBox(height: 4),
                        // Indicator chấm hoàn thành
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasCompleted
                                ? Colors.green
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _shortWeekday(int index) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[index];
  }

  String _weekRangeLabel(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startStr =
        '${startOfWeek.day.toString().padLeft(2, '0')}/${startOfWeek.month.toString().padLeft(2, '0')}';
    final endStr =
        '${endOfWeek.day.toString().padLeft(2, '0')}/${endOfWeek.month.toString().padLeft(2, '0')}';
    return '$startStr — $endStr';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
