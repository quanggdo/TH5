import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

enum CalendarView { day, week, month }

class CalendarProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  CalendarProvider(this._firestoreService, this._localStorageService);

  // ─── State ────────────────────────────────────────────────

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  CalendarView _currentView = CalendarView.day;
  CalendarView get currentView => _currentView;

  List<Habit> _habitsForToday = [];
  List<Habit> get habitsForToday => List.unmodifiable(_habitsForToday);

  /// habitId → số lần đã hoàn thành trong ngày
  Map<String, int> _completionCount = {};
  Map<String, int> get completionCount =>
      Map.unmodifiable(_completionCount);

  /// Logs cho chế độ xem tuần/tháng
  List<HabitLog> _periodLogs = [];
  List<HabitLog> get periodLogs => List.unmodifiable(_periodLogs);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Actions ──────────────────────────────────────────────

  /// Đổi ngày được chọn và cập nhật dữ liệu
  Future<void> selectDate(DateTime date, List<Habit> allHabits,
      String? userId) async {
    _selectedDate = date;
    _filterHabitsForDate(allHabits, date);
    if (userId != null) {
      await _loadCompletionStatus(userId, date);
    }
    notifyListeners();
  }

  /// Đổi chế độ xem
  Future<void> changeView(CalendarView view, List<Habit> allHabits,
      String? userId) async {
    _currentView = view;
    if (userId != null) {
      await _loadLogsForView(userId);
    }
    notifyListeners();
  }

  // ─── Logic lọc thói quen ─────────────────────────────────

  void _filterHabitsForDate(List<Habit> allHabits, DateTime date) {
    _habitsForToday = allHabits.where((h) => h.isDueOn(date)).toList();
  }

  // ─── Load completion status (Ngày) ────────────────────────

  Future<void> _loadCompletionStatus(String userId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final logs = await _firestoreService.getLogsForDate(userId, date);
      _completionCount = {
        for (final log in logs) log.habitId: log.count,
      };
    } catch (e) {
      debugPrint('Error loading completion status: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load logs cho chế độ xem Tuần/Tháng ──────────────────

  Future<void> _loadLogsForView(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      switch (_currentView) {
        case CalendarView.day:
          // Đã xử lý qua _loadCompletionStatus
          break;
        case CalendarView.week:
          final weekday = _selectedDate.weekday;
          final startOfWeek =
              _selectedDate.subtract(Duration(days: weekday - 1));
          _periodLogs =
              await _firestoreService.getLogsForWeek(userId, startOfWeek);
          break;
        case CalendarView.month:
          _periodLogs =
              await _firestoreService.getLogsForMonth(userId, _selectedDate);
          break;
      }
    } catch (e) {
      debugPrint('Error loading logs for view: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Public: tải logs khi người dùng chuyển sang tuần/tháng khác
  Future<void> fetchLogsForView(DateTime baseDate, String userId) async {
    _selectedDate = baseDate;
    await _loadLogsForView(userId);
  }

  // ─── Toggle hoàn thành ────────────────────────────────────

  /// Tăng số lần hoàn thành, đánh dấu isCompleted khi đạt timesPerDay
  Future<void> toggleCompletion(
      String habitId, String userId, DateTime date, int timesPerDay) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final currentCount = _completionCount[habitId] ?? 0;
    final newCount = currentCount >= timesPerDay ? 0 : currentCount + 1;
    final isCompleted = newCount >= timesPerDay;

    _completionCount[habitId] = newCount;
    notifyListeners();

    final log = HabitLog(
      habitId: habitId,
      userId: userId,
      date: dateStr,
      isCompleted: isCompleted,
      count: newCount,
    );

    try {
      await _firestoreService.syncLog(log);
    } catch (e) {
      // Offline → lưu vào pending queue
      debugPrint('Offline, saving to pending logs: $e');
      final pendingLogs = await _localStorageService.getPendingLogs();
      pendingLogs.add(log);
      await _localStorageService.savePendingLogs(pendingLogs);
    }
  }
}
