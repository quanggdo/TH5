import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class HabitProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final FirestoreService _firestoreService;
  String? _userId;

  HabitProvider(this._localStorageService, this._firestoreService);

  List<Habit> _activeHabits = [];
  List<Habit> get activeHabits =>
      List.unmodifiable(_activeHabits.where((h) => !h.isDeleted));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Cập nhật UserId và Load dữ liệu mới (được gọi từ ProxyProvider)
  void updateUser(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      Future.microtask(() {
        if (userId != null) {
          _syncAndLoadHabits();
        } else {
          // Đăng xuất -> Xóa danh sách tải trên máy
          _activeHabits.clear();
          notifyListeners();
        }
      });
    }
  }

  // ─── Load ─────────────────────────────────────────────────

  Future<void> _syncAndLoadHabits() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final onlineHabits = await _firestoreService.getHabits(_userId!);
      if (onlineHabits.isNotEmpty) {
        _activeHabits = onlineHabits;
        await _localStorageService.saveHabits(_activeHabits);
      } else {
        _activeHabits = await _localStorageService.getHabits();
      }
    } catch (e) {
      _activeHabits = await _localStorageService.getHabits();
      debugPrint("Offline mode: Loaded habits from local storage.");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHabits() async {
    _activeHabits = await _localStorageService.getHabits();
    notifyListeners();
  }

  // ─── Add ──────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    habit.userId = _userId; 
    _activeHabits.add(habit);
    await _localStorageService.saveHabits(_activeHabits);
    if (_userId != null) {
      await _firestoreService.syncHabit(habit);
    }
    notifyListeners();
  }

  // ─── Update ───────────────────────────────────────────────

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _activeHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _activeHabits[index] = updatedHabit;
      await _localStorageService.saveHabits(_activeHabits);
      if (_userId != null) {
        await _firestoreService.syncHabit(updatedHabit);
      }
      notifyListeners();
    }
  }

  // ─── Delete ───────────────────────────────────────────────

  Future<void> deleteHabit(String habitId) async {
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].isDeleted = true;
      await _localStorageService.saveHabits(_activeHabits);
      if (_userId != null) {
        await _firestoreService.syncHabit(_activeHabits[index]);
      }
      notifyListeners();
    }
  }

  // ─── Mark Completed (Helper) ──────────────────────────────

  Future<void> markCompleted(String habitId) async {
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].lastCompleted = DateTime.now();
      await _localStorageService.saveHabits(_activeHabits);
      if (_userId != null) {
        await _firestoreService.syncHabit(_activeHabits[index]);
      }
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────

  List<Habit> getHabitsForDate(DateTime date) {
    return _activeHabits.where((h) => !h.isDeleted && h.isDueOn(date)).toList();
  }

  List<Habit> filterHabits(String category) {
    if (category.isEmpty) return activeHabits;
    return activeHabits.where((h) => h.category == category).toList();
  }

  Habit? getHabitById(String id) {
    final index = _activeHabits.indexWhere((h) => h.id == id);
    return index != -1 ? _activeHabits[index] : null;
  }

  List<String> get categories {
    return _activeHabits
        .where((h) => !h.isDeleted && h.category.isNotEmpty)
        .map((h) => h.category)
        .toSet()
        .toList();
  }
}
