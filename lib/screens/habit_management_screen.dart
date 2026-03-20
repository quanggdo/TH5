import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/habit_provider.dart';
import 'habit_form_screen.dart';

class HabitManagementScreen extends StatefulWidget {
  const HabitManagementScreen({super.key});

  @override
  State<HabitManagementScreen> createState() => _HabitManagementScreenState();
}

enum _DueBadgeType { overdue, today, tomorrow, upcoming, none }

class _HabitListItemData {
  final Habit habit;
  final int progressToday;
  final _DueBadgeType badgeType;
  final DateTime? nextDueDate;

  const _HabitListItemData({
    required this.habit,
    required this.progressToday,
    required this.badgeType,
    required this.nextDueDate,
  });
}

class _HabitManagementScreenState extends State<HabitManagementScreen> {
  bool _didInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;
    _didInitialLoad = true;

    // Đảm bảo CalendarProvider trỏ đúng ngày hôm nay và load completion status
    final today = _dateOnly(DateTime.now());
    final calendarProvider = context.read<CalendarProvider>();

    if (!_isSameDay(calendarProvider.selectedDate, today)) {
      // Dùng addPostFrameCallback thay vì microtask để tránh rebuild trong build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          calendarProvider.selectDate(today);
        }
      });
    }

    // Trigger refresh habit list từ API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HabitProvider>().refreshHabits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Thói quen đang thực hiện'),
        actions: [
          IconButton(
            tooltip: 'Thêm thói quen',
            icon: const Icon(Icons.add),
            onPressed: () => _openCreate(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm thói quen'),
      ),
      body: Consumer2<HabitProvider, CalendarProvider>(
        builder: (context, habitProvider, calendarProvider, _) {
          if (habitProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = habitProvider.activeHabits.map((habit) {
            final progressToday =
                calendarProvider.completionCount[habit.id] ?? 0;
            final badgeType = _resolveBadgeType(habit, progressToday, today);
            return _HabitListItemData(
              habit: habit,
              progressToday: progressToday,
              badgeType: badgeType,
              nextDueDate: _findNextDueDate(habit, today),
            );
          }).toList();

          _sortByTodayPriority(items);

          final dueTodayCount = items
              .where((e) => e.habit.isDueOn(today))
              .length;
          final completedTodayCount = items
              .where(
                (e) =>
                    e.habit.isDueOn(today) &&
                    e.progressToday >= e.habit.timesPerDay,
              )
              .length;

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có thói quen nào đang thực hiện',
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

          return CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SummaryHeaderDelegate(
                  totalActive: items.length,
                  dueToday: dueTodayCount,
                  completedToday: completedTodayCount,
                ),
              ),
              SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final habit = item.habit;
                  final badgeText = _badgeLabel(item.badgeType);
                  final badgeColor = _badgeColor(item.badgeType);

                  return Dismissible(
                    key: ValueKey(habit.id),
                    direction: DismissDirection.endToStart,
                    dismissThresholds: const {
                      DismissDirection.endToStart: 0.25,
                    },
                    confirmDismiss: (_) => _confirmDelete(context, habit),
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) => _handleDelete(context, habit),
                    child: ListTile(
                      onTap: () => _openEdit(context, habit),
                      title: Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subtitleForHabit(habit),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Hiển thị tiến độ hoàn thành
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (item.progressToday / habit.timesPerDay)
                                        .clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      item.progressToday >= habit.timesPerDay
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.progressToday}/${habit.timesPerDay}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          if (item.badgeType == _DueBadgeType.tomorrow &&
                              item.nextDueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Lần tiếp theo: ${_formatDate(item.nextDueDate!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badgeText != null)
                            Chip(
                              label: Text(badgeText),
                              backgroundColor: badgeColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _openEdit(context, habit);
                              } else if (value == 'delete') {
                                final approved = await _confirmDelete(context, habit);
                                if (approved && context.mounted) {
                                  await _handleDelete(context, habit);
                                }
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Sửa'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 84)),
            ],
          );
        },
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HabitFormScreen(),
      ),
    );
  }

  void _openEdit(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitFormScreen(existingHabit: habit),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Habit habit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thói quen'),
        content: Text('Bạn có chắc muốn xóa "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    return shouldDelete == true;
  }

  Future<void> _handleDelete(BuildContext context, Habit habit) async {
    final success = await context.read<HabitProvider>().deleteHabit(habit.id);
    if (!success || !context.mounted) return;

    HapticFeedback.mediumImpact();
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

  void _sortByTodayPriority(List<_HabitListItemData> items) {
    items.sort((a, b) {
      final rankDiff = _priorityRank(
        a.badgeType,
      ).compareTo(_priorityRank(b.badgeType));
      if (rankDiff != 0) return rankDiff;

      if (a.badgeType == _DueBadgeType.today &&
          b.badgeType == _DueBadgeType.today) {
        final aLeft = (a.habit.timesPerDay - a.progressToday).clamp(
          0,
          a.habit.timesPerDay,
        );
        final bLeft = (b.habit.timesPerDay - b.progressToday).clamp(
          0,
          b.habit.timesPerDay,
        );
        final leftDiff = bLeft.compareTo(aLeft);
        if (leftDiff != 0) return leftDiff;
      }

      return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());
    });
  }

  int _priorityRank(_DueBadgeType badgeType) {
    switch (badgeType) {
      case _DueBadgeType.today:
        return 0;
      case _DueBadgeType.overdue:
        return 1;
      case _DueBadgeType.tomorrow:
        return 2;
      case _DueBadgeType.upcoming:
        return 3;
      case _DueBadgeType.none:
        return 4;
    }
  }

  _DueBadgeType _resolveBadgeType(
    Habit habit,
    int progressToday,
    DateTime today,
  ) {
    final tomorrow = today.add(const Duration(days: 1));
    final dueToday = habit.isDueOn(today);
    final latestDue = _findLatestDueDate(habit, today);

    if (latestDue != null &&
        latestDue.isBefore(today) &&
        !_isCompletedOnOrAfter(habit.lastCompleted, latestDue)) {
      return _DueBadgeType.overdue;
    }

    if (dueToday) {
      if (progressToday >= habit.timesPerDay) {
        return _DueBadgeType.none;
      }
      return _DueBadgeType.today;
    }

    final nextDue = _findNextDueDate(habit, today);
    if (nextDue != null && _isSameDay(nextDue, tomorrow)) {
      return _DueBadgeType.tomorrow;
    }

    if (nextDue != null && nextDue.isAfter(tomorrow)) {
      return _DueBadgeType.upcoming;
    }

    return _DueBadgeType.none;
  }

  bool _isCompletedOnOrAfter(DateTime? completedDateTime, DateTime date) {
    if (completedDateTime == null) return false;
    final completedDate = _dateOnly(completedDateTime);
    return !completedDate.isBefore(date);
  }

  DateTime? _findNextDueDate(Habit habit, DateTime startFrom) {
    final maxDays = _searchWindow(habit);
    for (int i = 0; i <= maxDays; i++) {
      final candidate = startFrom.add(Duration(days: i));
      if (habit.isDueOn(candidate)) {
        return _dateOnly(candidate);
      }
    }
    return null;
  }

  DateTime? _findLatestDueDate(Habit habit, DateTime endAt) {
    final maxDays = _searchWindow(habit);
    for (int i = 0; i <= maxDays; i++) {
      final candidate = endAt.subtract(Duration(days: i));
      if (habit.isDueOn(candidate)) {
        return _dateOnly(candidate);
      }
    }
    return null;
  }

  int _searchWindow(Habit habit) {
    if (habit.type == HabitType.interval) {
      final interval = habit.intervalDays ?? 1;
      return interval * 3;
    }
    return 14;
  }

  String? _badgeLabel(_DueBadgeType badgeType) {
    switch (badgeType) {
      case _DueBadgeType.overdue:
        return 'Quá hạn';
      case _DueBadgeType.today:
        return 'Hôm nay';
      case _DueBadgeType.tomorrow:
        return 'Ngày mai';
      case _DueBadgeType.upcoming:
        return 'Sắp tới';
      case _DueBadgeType.none:
        return null;
    }
  }

  Color _badgeColor(_DueBadgeType badgeType) {
    switch (badgeType) {
      case _DueBadgeType.overdue:
        return Colors.red.shade100;
      case _DueBadgeType.today:
        return Colors.orange.shade100;
      case _DueBadgeType.tomorrow:
        return Colors.blue.shade100;
      case _DueBadgeType.upcoming:
        return Colors.green.shade100;
      case _DueBadgeType.none:
        return Colors.transparent;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _subtitleForHabit(Habit habit) {
    final typeText = habit.type == HabitType.weekly
        ? 'Hằng tuần'
        : 'Cách ${habit.intervalDays ?? 1} ngày';

    final category = habit.category.trim().isEmpty
        ? 'Không có nhóm'
        : habit.category.trim();

    return '$typeText • $category • ${habit.timesPerDay} lần/ngày';
  }
}

class _SummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int totalActive;
  final int dueToday;
  final int completedToday;

  const _SummaryHeaderDelegate({
    required this.totalActive,
    required this.dueToday,
    required this.completedToday,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryMetric(label: 'Còn thực hiện', value: '$totalActive'),
              _SummaryMetric(label: 'Đến hạn hôm nay', value: '$dueToday'),
              _SummaryMetric(
                label: 'Đã xong hôm nay',
                value: '$completedToday',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 84;

  @override
  double get minExtent => 84;

  @override
  bool shouldRebuild(covariant _SummaryHeaderDelegate oldDelegate) {
    return oldDelegate.totalActive != totalActive ||
        oldDelegate.dueToday != dueToday ||
        oldDelegate.completedToday != completedToday;
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}
