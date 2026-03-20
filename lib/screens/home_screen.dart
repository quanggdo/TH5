import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/habit_provider.dart';
import '../services/auth_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_filter.dart';
import '../widgets/view_mode_selector.dart';
import 'change_password_screen.dart';
import 'habit_form_screen.dart';
import 'habit_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewMode _selectedViewMode = ViewMode.day;
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncCalendarToToday(context.read<CalendarProvider>());
    });
  }

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
              if (!mounted) return;
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
            final today = _dateOnly(DateTime.now());
            if (_selectedViewMode == ViewMode.day &&
                !_isSameDay(calendarProvider.selectedDate, today)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _syncCalendarToToday(calendarProvider);
              });
            }

            final allHabitsForToday = habitProvider.getHabitsForDate(today);
            final habitList = _filterHabitsByCategory(allHabitsForToday);

            final categories = habitProvider.categories;
            final completionCount = calendarProvider.completionCount;
            final periodLogs = calendarProvider.periodLogs;

            return Column(
              children: [
                ViewModeSelector(
                  selectedMode: _selectedViewMode,
                  onModeChanged: (mode) async {
                    setState(() {
                      _selectedViewMode = mode;
                    });
                    await _syncCalendarToToday(calendarProvider);
                    await calendarProvider.changeView(_mapViewMode(mode));
                  },
                ),
                const Divider(),
                _buildModeInfo(context),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                    _selectedCategories = selected
                                        .map(_normalizeCategory)
                                        .where((value) => value.isNotEmpty)
                                        .toSet();
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
                Expanded(
                  child: (habitProvider.isLoading || calendarProvider.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedViewMode == ViewMode.day
                          ? _buildDayHabitList(
                              context,
                              habitList,
                              completionCount,
                              today,
                              calendarProvider,
                              habitProvider,
                            )
                          : _buildPeriodLogsSummary(
                              context,
                              periodLogs,
                              habitProvider,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeInfo(BuildContext context) {
    final now = DateTime.now();
    final text = switch (_selectedViewMode) {
      ViewMode.day => 'Hôm nay: ${_formatDate(now)}',
      ViewMode.week => 'Thống kê tuần hiện tại',
      ViewMode.month => 'Thống kê tháng ${now.month}/${now.year}',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

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

  Widget _buildPeriodLogsSummary(
    BuildContext context,
    List<dynamic> periodLogs,
    HabitProvider habitProvider,
  ) {
    final completedLogs = periodLogs.where((log) => log.isCompleted == true).toList();

    if (completedLogs.isEmpty) {
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

    final Map<String, _HabitLogSummary> summaryMap = {};
    for (final log in completedLogs) {
      final habitId = log.habitId as String;
      final count = log.count as int;

      if (!summaryMap.containsKey(habitId)) {
        final habit = habitProvider.getHabitById(habitId);
        summaryMap[habitId] = _HabitLogSummary(
          habitId: habitId,
          habitTitle: habit?.title ?? 'Không rõ',
          habitDetail: habit?.detail ?? '',
          habitCategory: habit?.category ?? '',
          timesPerDay: habit?.timesPerDay ?? 1,
          scheduleText: _buildScheduleText(habit),
        );
      }

      summaryMap[habitId]!.totalCount += count;
      summaryMap[habitId]!.completedDays += 1;
    }

    final summaries = summaryMap.values
        .where((summary) => _matchesCategoryFilter(summary.habitCategory))
        .toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
    final periodLabel = _selectedViewMode == ViewMode.week ? 'tuần này' : 'tháng này';

    if (summaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Không có thói quen nào theo bộ lọc',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Thống kê đã hoàn thành $periodLabel',
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      if (summary.habitDetail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          summary.habitDetail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SummaryInfoChip(
                            icon: Icons.repeat,
                            text: summary.scheduleText,
                          ),
                          _SummaryInfoChip(
                            icon: Icons.exposure_plus_1,
                            text: '${summary.timesPerDay} lần/ngày',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ngày hoàn thành: ${summary.completedDays}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Tổng: ${summary.totalCount} lần',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  String _buildScheduleText(Habit? habit) {
    if (habit == null) return 'Không rõ lịch';
    if (habit.type == HabitType.interval) {
      return 'Cách ${habit.intervalDays ?? 1} ngày';
    }

    final days = List<int>.from(habit.weeklyDays ?? const <int>[])..sort();
    if (days.isEmpty) return 'Theo tuần';

    const labels = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return days.map((day) => labels[day] ?? '').where((v) => v.isNotEmpty).join(', ');
  }

  Future<void> _syncCalendarToToday(CalendarProvider calendarProvider) async {
    final today = _dateOnly(DateTime.now());
    if (!_isSameDay(calendarProvider.selectedDate, today)) {
      await calendarProvider.selectDate(today);
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

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<Habit> _filterHabitsByCategory(List<Habit> habits) {
    final original = List<Habit>.from(habits);
    if (_selectedCategories.isEmpty) return original;

    return original
        .where((habit) => _matchesCategoryFilter(habit.category))
        .toList();
  }

  bool _matchesCategoryFilter(String? category) {
    if (_selectedCategories.isEmpty) return true;
    return _selectedCategories.contains(_normalizeCategory(category));
  }

  String _normalizeCategory(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _HabitLogSummary {
  final String habitId;
  final String habitTitle;
  final String habitDetail;
  final String habitCategory;
  final int timesPerDay;
  final String scheduleText;
  int totalCount;
  int completedDays;

  _HabitLogSummary({
    required this.habitId,
    required this.habitTitle,
    required this.habitDetail,
    required this.habitCategory,
    required this.timesPerDay,
    required this.scheduleText,
    this.totalCount = 0,
    this.completedDays = 0,
  });
}

class _SummaryInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
