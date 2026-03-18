import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/habit_provider.dart';

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
  bool _syncedCalendarToToday = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedCalendarToToday) return;

    _syncedCalendarToToday = true;
    final today = _dateOnly(DateTime.now());
    final calendarProvider = context.read<CalendarProvider>();

    if (!_isSameDay(calendarProvider.selectedDate, today)) {
      Future.microtask(() => calendarProvider.selectDate(today));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sach thoi quen con thuc hien')),
      body: Consumer2<HabitProvider, CalendarProvider>(
        builder: (context, habitProvider, calendarProvider, _) {
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
            return const Center(
              child: Text('Chua co thoi quen nao dang thuc hien'),
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

                  return ListTile(
                    title: Text(habit.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_subtitleForHabit(habit)),
                        const SizedBox(height: 4),
                        Text(
                          'Tien do hom nay: ${item.progressToday}/${habit.timesPerDay}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.badgeType == _DueBadgeType.tomorrow &&
                            item.nextDueDate != null)
                          Text(
                            'Lan tiep theo: ${_formatDate(item.nextDueDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: badgeText == null
                        ? null
                        : Chip(
                            label: Text(badgeText),
                            backgroundColor: badgeColor,
                            visualDensity: VisualDensity.compact,
                          ),
                    isThreeLine: true,
                  );
                },
                separatorBuilder: (_, _) => const Divider(height: 1),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          );
        },
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
        return 'Qua han';
      case _DueBadgeType.today:
        return 'Hom nay';
      case _DueBadgeType.tomorrow:
        return 'Ngay mai';
      case _DueBadgeType.upcoming:
        return 'Sap toi';
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
        ? 'Hang tuan'
        : 'Cach ${habit.intervalDays ?? 1} ngay';

    final category = habit.category.trim().isEmpty
        ? 'Khong co nhom'
        : habit.category.trim();

    return '$typeText • $category • ${habit.timesPerDay} lan/ngay';
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
              _SummaryMetric(label: 'Con thuc hien', value: '$totalActive'),
              _SummaryMetric(label: 'Den han hom nay', value: '$dueToday'),
              _SummaryMetric(
                label: 'Da xong hom nay',
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
