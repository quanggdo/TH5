import '../models/habit_model.dart';

/// Dữ liệu mẫu để kiểm tra UI
class SampleHabits {
  static List<Habit> getSampleHabits() {
    return [
      Habit(
        id: '1',
        title: 'Chạy bộ sáng',
        detail: 'Chạy bộ 30 phút vào buổi sáng để rèn luyện sức khỏe',
        type: HabitType.weekly,
        weeklyDays: [1, 3, 5], // Monday, Wednesday, Friday
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Sức khỏe',
        lastCompleted: DateTime.now(),
      ),
      Habit(
        id: '2',
        title: 'Đọc sách',
        detail: 'Đọc sách trong 30 phút trước khi đi ngủ',
        type: HabitType.weekly,
        weeklyDays: [1, 2, 3, 4, 5, 6, 7], // Hàng ngày
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Học tập',
        lastCompleted: DateTime.now(),
      ),
      Habit(
        id: '3',
        title: 'Yoga',
        detail: 'Tập yoga 20 phút để giãn cơ và thư giãn',
        type: HabitType.interval,
        intervalDays: 2,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Sức khỏe',
        lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Habit(
        id: '4',
        title: 'Meditating',
        detail: 'Thiền định 10 phút mỗi sáng',
        type: HabitType.weekly,
        weeklyDays: [1, 2, 3, 4, 5, 6, 7], // Hàng ngày
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Tâm lý',
        lastCompleted: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Habit(
        id: '5',
        title: 'Học tiếng Anh',
        detail: 'Học tiếng Anh 45 phút qua app Duolingo hoặc sách',
        type: HabitType.weekly,
        weeklyDays: [2, 4, 6], // Tuesday, Thursday, Saturday
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Học tập',
        lastCompleted: DateTime.now(),
      ),
      Habit(
        id: '6',
        title: 'Uống nước',
        detail: 'Uống 8 cốc nước mỗi ngày',
        type: HabitType.weekly,
        weeklyDays: [1, 2, 3, 4, 5, 6, 7], // Hàng ngày
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        timesPerDay: 1,
        category: 'Sức khỏe',
      ),
    ];
  }
}
