import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/firestore_service.dart';

enum CalendarView { day, week, month }

class CalendarProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  String? _userId;
  List<Habit> _allHabits = [];

  CalendarProvider(this._firestoreService);

  // ─── State ────────────────────────────────────────────────

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  CalendarView _currentView = CalendarView.day;
  CalendarView get currentView => _currentView;

  List<Habit> _habitsForToday = [];
  List<Habit> get habitsForToday => List.unmodifiable(_habitsForToday);

  Map<String, int> _completionCount = {};
  Map<String, int> get completionCount => Map.unmodifiable(_completionCount);

  List<HabitLog> _periodLogs = [];
  List<HabitLog> get periodLogs => List.unmodifiable(_periodLogs);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── ProxyProvider Update ─────────────────────────────────

  /// Nhận dữ liệu cập nhật từ ProxyProvider (userId từ Auth, allHabits từ HabitProvider)
  void update(String? userId, List<Habit> allHabits) {
    _allHabits = allHabits;
    bool userChanged = _userId != userId;
    _userId = userId;

    _filterHabitsForDate();

    if (userChanged) {
      Future.microtask(() {
        if (_userId != null) {
          if (_currentView == CalendarView.day) {
            _loadCompletionStatus();
          } else {
            _loadLogsForView();
          }
        } else {
          _completionCount.clear();
          _periodLogs.clear();
          notifyListeners();
        }
      });
    }
  }

  // ─── Actions ──────────────────────────────────────────────

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    _filterHabitsForDate();
    if (_userId != null) {
      await _loadCompletionStatus();
    }
    notifyListeners();
  }

  Future<void> changeView(CalendarView view) async {
    _currentView = view;
    if (_userId != null) {
      await _loadLogsForView();
    }
    notifyListeners();
  }

  void _filterHabitsForDate() {
    _habitsForToday = _allHabits.where((h) => h.isDueOn(_selectedDate)).toList();
  }

  // ─── Load completion status (Ngày) ────────────────────────

  Future<void> _loadCompletionStatus() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final logs = await _firestoreService.getLogsForDate(_userId!, _selectedDate);
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

  Future<void> _loadLogsForView() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      switch (_currentView) {
        case CalendarView.day:
          break;
        case CalendarView.week:
          final weekday = _selectedDate.weekday;
          final startOfWeek = _selectedDate.subtract(Duration(days: weekday - 1));
          _periodLogs = await _firestoreService.getLogsForWeek(_userId!, startOfWeek);
          break;
        case CalendarView.month:
          _periodLogs = await _firestoreService.getLogsForMonth(_userId!, _selectedDate);
          break;
      }
    } catch (e) {
      debugPrint('Error loading logs for view: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLogsForView(DateTime baseDate) async {
    _selectedDate = baseDate;
    await _loadLogsForView();
  }

  // ─── Toggle hoàn thành ────────────────────────────────────

  Future<void> toggleCompletion(String habitId, DateTime date, int timesPerDay) async {
    if (_userId == null) return;

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final currentCount = _completionCount[habitId] ?? 0;
    final newCount = currentCount >= timesPerDay ? 0 : currentCount + 1;
    final isCompleted = newCount >= timesPerDay;

    // Cập nhật State tức thì (Optimistic UI)
    _completionCount[habitId] = newCount;
    notifyListeners();

    final log = HabitLog(
      habitId: habitId,
      userId: _userId!,
      date: dateStr,
      isCompleted: isCompleted,
      count: newCount,
    );

    try {
      await _firestoreService.syncLog(log);
    } catch (e) {
      debugPrint('Log saved locally. Firestore will sync when online. Error: $e');
    }
  }
}
