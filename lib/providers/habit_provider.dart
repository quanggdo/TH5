import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String? _effectiveUserId() {
    return _userId ?? FirebaseAuth.instance.currentUser?.uid;
  }

  // ─── Load ─────────────────────────────────────────────────

  Future<void> _syncAndLoadHabits() async {
    final uid = _effectiveUserId();
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final onlineHabits = await _firestoreService.getHabits(uid);
      if (onlineHabits.isNotEmpty) {
        _activeHabits = onlineHabits;
        await _localStorageService.saveHabits(
          _activeHabits,
          userId: uid,
        );
      } else {
        _activeHabits = await _localStorageService.getHabits(userId: uid);
        // Nếu chưa có dữ liệu user, thử migrate từ guest và đẩy lên Firestore
        if (_activeHabits.isEmpty) {
          final guestHabits = await _localStorageService.getHabits();
          if (guestHabits.isNotEmpty) {
            for (final habit in guestHabits) {
              habit.userId = uid;
              await _firestoreService.syncHabit(habit);
            }
            _activeHabits = guestHabits;
            await _localStorageService.saveHabits(_activeHabits, userId: uid);
            await _localStorageService.clearHabits();
          }
        }
      }
    } catch (e) {
      _activeHabits = await _localStorageService.getHabits(userId: uid);
      debugPrint("Offline mode: Loaded habits from local storage.");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHabits() async {
    final uid = _effectiveUserId();
    _activeHabits = await _localStorageService.getHabits(userId: uid);
    notifyListeners();
  }

  // ─── Add ──────────────────────────────────────────────────

  Future<bool> addHabit(Habit habit) async {
    final uid = _effectiveUserId();
    if (uid == null || uid.trim().isEmpty) {
      debugPrint('addHabit skipped: userId is null');
      return false;
    }
    habit.userId = uid;
    _activeHabits.add(habit);
    await _localStorageService.saveHabits(_activeHabits, userId: uid);
    try {
      await _firestoreService.syncHabit(habit);
    } catch (e) {
      debugPrint('Sync habit failed: $e');
    }
    notifyListeners();
    return true;
  }

  // ─── Update ───────────────────────────────────────────────

  Future<bool> updateHabit(Habit updatedHabit) async {
    final uid = _effectiveUserId();
    if (uid == null || uid.trim().isEmpty) {
      debugPrint('updateHabit skipped: userId is null');
      return false;
    }
    final index = _activeHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      updatedHabit.userId = uid;
      _activeHabits[index] = updatedHabit;
      await _localStorageService.saveHabits(_activeHabits, userId: uid);
      try {
        await _firestoreService.syncHabit(updatedHabit);
      } catch (e) {
        debugPrint('Sync habit failed: $e');
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Delete ───────────────────────────────────────────────

  Future<bool> deleteHabit(String habitId) async {
    final uid = _effectiveUserId();
    if (uid == null || uid.trim().isEmpty) {
      debugPrint('deleteHabit skipped: userId is null');
      return false;
    }
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].isDeleted = true;
      // Lưu lại local với flag isDeleted để có thể hoàn tác
      await _localStorageService.saveHabits(_activeHabits, userId: uid);
      try {
        // Thực hiện xóa vĩnh viễn trên Firestore như yêu cầu
        await _firestoreService.deleteHabit(uid, habitId);
      } catch (e) {
        debugPrint('Delete from Firestore failed: $e');
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> restoreHabit(String habitId) async {
    final uid = _effectiveUserId();
    if (uid == null || uid.trim().isEmpty) {
      debugPrint('restoreHabit skipped: userId is null');
      return false;
    }
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].isDeleted = false;
      await _localStorageService.saveHabits(_activeHabits, userId: uid);
      try {
        // Khi hoàn tác, đồng bộ lại habit lên Firestore (sẽ tạo lại document)
        await _firestoreService.syncHabit(_activeHabits[index]);
      } catch (e) {
        debugPrint('Restore to Firestore failed: $e');
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Mark Completed (Helper) ──────────────────────────────

  Future<bool> markCompleted(String habitId) async {
    final uid = _effectiveUserId();
    if (uid == null || uid.trim().isEmpty) {
      debugPrint('markCompleted skipped: userId is null');
      return false;
    }
    final index = _activeHabits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      _activeHabits[index].lastCompleted = DateTime.now();
      await _localStorageService.saveHabits(_activeHabits, userId: uid);
      try {
        await _firestoreService.syncHabit(_activeHabits[index]);
      } catch (e) {
        debugPrint('Sync habit failed: $e');
      }
      notifyListeners();
      return true;
    }
    return false;
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
