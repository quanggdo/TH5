import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class LocalStorageService {
  static const String _habitsKey = 'habits';
  static const String _pendingLogsKey = 'pending_logs';

  // ─── Habits ───────────────────────────────────────────────

  /// Lưu danh sách thói quen vào SharedPreferences
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_habitsKey, jsonList);
  }

  /// Đọc danh sách thói quen từ SharedPreferences
  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_habitsKey) ?? [];
    return jsonList
        .map((s) => Habit.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Cập nhật riêng trường lastCompleted cho 1 thói quen
  Future<void> updateLastCompleted(String id, DateTime date) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      habits[index].lastCompleted = date;
      await saveHabits(habits);
    }
  }

  // ─── Pending Logs (Offline Queue) ─────────────────────────

  /// Lưu danh sách logs chờ đồng bộ
  Future<void> savePendingLogs(List<HabitLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_pendingLogsKey, jsonList);
  }

  /// Đọc danh sách logs chờ đồng bộ
  Future<List<HabitLog>> getPendingLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_pendingLogsKey) ?? [];
    return jsonList
        .map((s) => HabitLog.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Xóa pending logs sau khi đồng bộ thành công
  Future<void> clearPendingLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingLogsKey);
  }
}
