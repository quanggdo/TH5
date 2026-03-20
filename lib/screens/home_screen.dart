import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/calendar_provider.dart';
import 'habit_management_screen.dart';
import '../widgets/habit_card.dart';
import '../widgets/view_mode_selector.dart';
import '../widgets/habit_filter.dart';
import '../widgets/calendar_day_view.dart';
import '../widgets/calendar_week_view.dart';
import '../widgets/calendar_month_view.dart';
import 'habit_form_screen.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewMode _selectedViewMode = ViewMode.day;
  Set<String> _selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          tooltip: 'Tài khoản',
          icon: const Icon(Icons.person_outline),
          onSelected: (value) async {
            if (value == 'change_password') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
              );
            } else if (value == 'logout') {
              await context.read<AuthService>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'change_password', child: Text('Đổi mật khẩu')),
            PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
          ],
        ),
        title: const Text('Theo dõi thói quen'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Thêm thói quen',
            icon: const Icon(Icons.add),
            onPressed: () => _openCreate(context),
          ),
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, calendarProvider, _) => Consumer<HabitProvider>(
          builder: (context, habitProvider, _) {
            final selectedDate = calendarProvider.selectedDate;
            final List<Habit> calendarHabits = calendarProvider.habitsForToday;
            List<Habit> habitList = calendarHabits
                .where((h) => habitProvider.getHabitById(h.id) != null)
                .toList();

            if (_selectedCategories.isNotEmpty) {
              habitList = habitList
                  .where((h) => _selectedCategories.contains(h.category))
                  .toList();
            }

            final categories = habitProvider.categories;
            final periodLogs = calendarProvider.periodLogs;
            final completionCount = calendarProvider.completionCount;

            return Column(
              children: [
                ViewModeSelector(
                  selectedMode: _selectedViewMode,
                  onModeChanged: (mode) async {
                    setState(() {
                      _selectedViewMode = mode;
                    });

                    final calendarView = _mapViewMode(mode);
                    await calendarProvider.changeView(calendarView);
                  },
                ),
                const Divider(),
                // ── Calendar View ────────────────────────────────────
                _buildCalendarView(
                  calendarProvider,
                  periodLogs,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => HabitFilter(
                                categories: categories,
                                selectedCategories: _selectedCategories,
                                onFilterChanged: (selected) {
                                  setState(() {
                                    _selectedCategories = selected;
                                  });
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Lọc thói quen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HabitManagementScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list),
                          label: const Text('Danh sách'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // ── Habit List / Logs Summary ────────────────────────
                Expanded(
                  child: (habitProvider.isLoading || calendarProvider.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedViewMode == ViewMode.day
                          ? _buildDayHabitList(
                              context, habitList, completionCount, selectedDate,
                              calendarProvider, habitProvider)
                          : _buildPeriodLogsSummary(
                              context, periodLogs, habitProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build the appropriate calendar view widget based on selected mode
  Widget _buildCalendarView(
    CalendarProvider calendarProvider,
    List periodLogs,
  ) {
    switch (_selectedViewMode) {
      case ViewMode.day:
        return CalendarDayView(
          selectedDate: calendarProvider.selectedDate,
          onDateChanged: (date) => calendarProvider.selectDate(date),
        );
      case ViewMode.week:
        return CalendarWeekView(
          selectedDate: calendarProvider.selectedDate,
          onDateChanged: (date) async {
            await calendarProvider.selectDate(date);
            await calendarProvider.changeView(CalendarView.week);
          },
          periodLogs: calendarProvider.periodLogs,
        );
      case ViewMode.month:
        return CalendarMonthView(
          selectedDate: calendarProvider.selectedDate,
          onDateChanged: (date) async {
            await calendarProvider.selectDate(date);
            await calendarProvider.changeView(CalendarView.month);
          },
          periodLogs: calendarProvider.periodLogs,
        );
    }
  }

  /// Build habit list for day view - shows each habit with completion count
  Widget _buildDayHabitList(
    BuildContext context,
    List<Habit> habitList,
    Map<String, int> completionCount,
    DateTime selectedDate,
    CalendarProvider calendarProvider,
    HabitProvider habitProvider,
  ) {
    if (habitList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 56),
              const SizedBox(height: 12),
              Text(
                _selectedCategories.isEmpty
                    ? 'Chưa có thói quen nào hôm nay'
                    : 'Không có thói quen nào theo bộ lọc',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Tạo thói quen mới'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: habitList.length,
      itemBuilder: (context, index) {
        final habit = habitList[index];
        final currentCount = completionCount[habit.id] ?? 0;
        final isCompleted = currentCount >= habit.timesPerDay;

        return HabitCard(
          habit: habit,
          isCompleted: isCompleted,
          completionCount: currentCount,
          onCompleteTap: () async {
            final newCount = await calendarProvider.toggleCompletion(
              habit.id,
              selectedDate,
              habit.timesPerDay,
            );
            if (newCount >= habit.timesPerDay) {
              await context.read<HabitProvider>().markCompleted(habit.id);
            }
          },
          onEditTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HabitFormScreen(existingHabit: habit),
              ),
            );
          },
          onDeleteTap: () => _showDeleteConfirmation(context, habit),
        );
      },
    );
  }

  /// Build period logs summary for week/month views
  /// Shows each habit with total completion count for the period
  Widget _buildPeriodLogsSummary(
    BuildContext context,
    List periodLogs,
    HabitProvider habitProvider,
  ) {
    if (periodLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu hoàn thành trong khoảng thời gian này',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group logs by habitId and sum up counts
    final Map<String, _HabitLogSummary> summaryMap = {};
    for (final log in periodLogs) {
      final habitId = log.habitId as String;
      final count = log.count as int;
      final isCompleted = log.isCompleted as bool;

      if (!summaryMap.containsKey(habitId)) {
        final habit = habitProvider.getHabitById(habitId);
        summaryMap[habitId] = _HabitLogSummary(
          habitId: habitId,
          habitTitle: habit?.title ?? 'Không rõ',
          habitCategory: habit?.category ?? '',
          timesPerDay: habit?.timesPerDay ?? 1,
        );
      }

      summaryMap[habitId]!.totalCount += count;
      if (isCompleted) {
        summaryMap[habitId]!.completedDays += 1;
      }
      summaryMap[habitId]!.loggedDays += 1;
    }

    final summaries = summaryMap.values.toList()
      ..sort((a, b) => b.completedDays.compareTo(a.completedDays));

    final colorScheme = Theme.of(context).colorScheme;
    final periodLabel =
        _selectedViewMode == ViewMode.week ? 'tuần này' : 'tháng này';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Thống kê hoàn thành $periodLabel',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final ratio = summary.loggedDays > 0
                  ? summary.completedDays / summary.loggedDays
                  : 0.0;

              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              summary.habitTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (summary.habitCategory.isNotEmpty)
                            Chip(
                              label: Text(summary.habitCategory),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio >= 1.0
                                ? Colors.green
                                : ratio >= 0.5
                                    ? Colors.orange
                                    : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hoàn thành: ${summary.completedDays}/${summary.loggedDays} ngày',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Tổng: ${summary.totalCount} lần',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  CalendarView _mapViewMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.day:
        return CalendarView.day;
      case ViewMode.week:
        return CalendarView.week;
      case ViewMode.month:
        return CalendarView.month;
    }
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HabitFormScreen(),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thói quen "${habit.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<HabitProvider>().deleteHabit(habit.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${habit.title}"'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () {
                context.read<HabitProvider>().restoreHabit(habit.id);
              },
            ),
          ),
        );
      }
    }
  }
}

/// Helper class to aggregate habit log data for period summaries
class _HabitLogSummary {
  final String habitId;
  final String habitTitle;
  final String habitCategory;
  final int timesPerDay;
  int totalCount;
  int completedDays;
  int loggedDays;

  _HabitLogSummary({
    required this.habitId,
    required this.habitTitle,
    required this.habitCategory,
    required this.timesPerDay,
    this.totalCount = 0,
    this.completedDays = 0,
    this.loggedDays = 0,
  });
}
