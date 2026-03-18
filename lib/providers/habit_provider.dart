import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../services/local_storage_service.dart';

class HabitProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;

  HabitProvider(this._localStorageService);

  List<Habit> _activeHabits = [];
  /// Chỉ trả về habits chưa bị xóa
  List<Habit> get activeHabits =>
      List.unmodifiable(_activeHabits.where((h) => !h.isDeleted));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Load ─────────────────────────────────────────────────

  /// Tải danh sách thói quen từ local storage
  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    _activeHabits = await _localStorageService.getHabits();

    _isLoading = false;
    notifyListeners();
  }

  // ─── Add ──────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    _activeHabits.add(habit);
    await _localStorageService.saveHabits(_activeHabits);
    notifyListeners();
  }

  // ─── Update ───────────────────────────────────────────────

  Future<void> updateHabit(Habit updatedHabit) async {
    final index =
        _activeHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _activeHabits[index] = updatedHabit;
      await _localStorageService.saveHabits(_activeHabits);
      notifyListeners();
    }
  }

  // ─── Delete (Soft-delete) ─────────────────────────────────

  /// Đánh dấu xóa mềm — giữ lại dữ liệu quá khứ trên Firebase
  Future<void> deleteHabit(String habitId) async {
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].isDeleted = true;
      await _localStorageService.saveHabits(_activeHabits);
      notifyListeners();
    }
  }

  // ─── Mark Completed ───────────────────────────────────────

  /// Cập nhật lastCompleted cho thói quen khi người dùng bấm hoàn thành
  Future<void> markCompleted(String habitId) async {
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].lastCompleted = DateTime.now();
      await _localStorageService.saveHabits(_activeHabits);
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────

  /// Lấy danh sách thói quen cần thực hiện trong ngày [date]
  List<Habit> getHabitsForDate(DateTime date) {
    return _activeHabits.where((h) => !h.isDeleted && h.isDueOn(date)).toList();
  }

  /// Lọc thói quen theo nhãn phân loại (category)
  List<Habit> filterHabits(String category) {
    if (category.isEmpty) return activeHabits;
    return activeHabits.where((h) => h.category == category).toList();
  }

  /// Lấy 1 thói quen theo ID (dùng cho màn hình Sửa)
  Habit? getHabitById(String id) {
    final index = _activeHabits.indexWhere((h) => h.id == id);
    return index != -1 ? _activeHabits[index] : null;
  }

  /// Lấy danh sách category duy nhất (dùng cho UI filter)
  List<String> get categories {
    return _activeHabits
        .where((h) => !h.isDeleted && h.category.isNotEmpty)
        .map((h) => h.category)
        .toSet()
        .toList();
  }
}
