import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';

class LocalStorageService {
  static const String _habitsKeyPrefix = 'habits_';

  String _keyForUser(String? userId) {
    final safeId = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim()
        : 'guest';
    return '$_habitsKeyPrefix$safeId';
  }

  // ─── Habits ───────────────────────────────────────────────

  /// Lưu danh sách thói quen vào SharedPreferences
  Future<void> saveHabits(List<Habit> habits, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_keyForUser(userId), jsonList);
  }

  /// Đọc danh sách thói quen từ SharedPreferences
  Future<List<Habit>> getHabits({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyForUser(userId)) ?? [];
    return jsonList
        .map((s) => Habit.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Cập nhật riêng trường lastCompleted cho 1 thói quen (Local offline backup)
  Future<void> updateLastCompleted(
    String id,
    DateTime date, {
    String? userId,
  }) async {
    final habits = await getHabits(userId: userId);
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      habits[index].lastCompleted = date;
      await saveHabits(habits, userId: userId);
    }
  }

  /// Xóa danh sách thói quen đã lưu trong SharedPreferences
  Future<void> clearHabits({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(userId));
  }
}
