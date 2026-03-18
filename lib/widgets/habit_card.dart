import 'package:flutter/material.dart';
import '../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onCompleteTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onCompleteTap,
  });

  /// Lấy giờ thực hiện (nếu có thêm thông tin từ model)
  String get _executionTime {
    // Nếu model không có execution time, có thể tính từ lastCompleted
    if (habit.lastCompleted != null) {
      return '${habit.lastCompleted!.hour.toString().padLeft(2, '0')}:${habit.lastCompleted!.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  /// Chuyển enum HabitType sang chuỗi hiển thị
  String get _habitTypeText {
    if (habit.type == HabitType.weekly) {
      return 'Hàng tuần';
    } else if (habit.type == HabitType.interval) {
      return 'Cách ${habit.intervalDays} ngày';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox (Status)
            Checkbox(
              value: isCompleted,
              onChanged: (_) => onCompleteTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 12),
            // Content (Title, Details, Type)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thời gian thực hiện
                  Text(
                    _executionTime,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  // Tiêu đề (bold, 1 dòng, truncate với ...)
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Chi tiết (nhạt hơn, 3 dòng, truncate với ...)
                  Text(
                    habit.detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  // Loại thói quen
                  Text(
                    _habitTypeText,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
