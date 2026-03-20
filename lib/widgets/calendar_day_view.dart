import 'package:flutter/material.dart';

/// Widget hiển thị chế độ xem NGÀY.
/// Hiển thị ngày được chọn với điều hướng trái/phải.
class CalendarDayView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isToday = _isSameDay(selectedDate, today);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            // Nút lùi ngày
            IconButton(
              tooltip: 'Ngày trước',
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                onDateChanged(
                  selectedDate.subtract(const Duration(days: 1)),
                );
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekdayName(selectedDate.weekday),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${selectedDate.day}',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: isToday
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMonthYear(selectedDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Hôm nay',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Nút tiến ngày
            IconButton(
              tooltip: 'Ngày sau',
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                onDateChanged(
                  selectedDate.add(const Duration(days: 1)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayName(int weekday) {
    const names = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return names[weekday - 1];
  }

  String _formatMonthYear(DateTime d) {
    return 'Tháng ${d.month}, ${d.year}';
  }
}
