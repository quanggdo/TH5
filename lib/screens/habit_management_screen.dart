import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/habit_provider.dart';
import 'habit_form_screen.dart';

enum _SortOption { latest, name, schedule }

class HabitManagementScreen extends StatefulWidget {
  const HabitManagementScreen({super.key});

  @override
  State<HabitManagementScreen> createState() => _HabitManagementScreenState();
}

class _HabitManagementScreenState extends State<HabitManagementScreen> {
  bool _didInitialLoad = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '';
  _SortOption _sortOption = _SortOption.latest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;

    _didInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HabitProvider>().refreshHabits();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thói quen'),
        actions: [
          IconButton(
            tooltip: 'Thêm thói quen',
            onPressed: _openCreate,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Consumer2<HabitProvider, CalendarProvider>(
        builder: (context, habitProvider, calendarProvider, _) {
          final allHabits = habitProvider.activeHabits;
          final categories = habitProvider.categories..sort();
          final filteredHabits = _buildFilteredHabits(allHabits);
          final today = _dateOnly(DateTime.now());
          final dueToday = allHabits.where((habit) => habit.isDueOn(today)).toList();
          final completedToday = dueToday
              .where((habit) => (calendarProvider.completionCount[habit.id] ?? 0) >= habit.timesPerDay)
              .length;

          if (habitProvider.isLoading && allHabits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => habitProvider.refreshHabits(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _buildSummaryCard(
                  context: context,
                  total: allHabits.length,
                  dueToday: dueToday.length,
                  completedToday: completedToday,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(colorScheme),
                const SizedBox(height: 12),
                _buildCategoryFilter(categories),
                const SizedBox(height: 12),
                _buildSortSelector(theme),
                const SizedBox(height: 16),
                if (filteredHabits.isEmpty)
                  _buildEmptyState(context, allHabits.isEmpty)
                else
                  ...filteredHabits.map(
                    (habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitManagementCard(
                        habit: habit,
                        completionCount: calendarProvider.completionCount[habit.id] ?? 0,
                        onEditTap: () => _openEdit(habit),
                        onDeleteTap: () => _showDeleteConfirmation(habit),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Thói quen mới'),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required int total,
    required int dueToday,
    required int completedToday,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Tổng thói quen',
                    value: total.toString(),
                    icon: Icons.list_alt_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatItem(
                    label: 'Hôm nay',
                    value: dueToday.toString(),
                    icon: Icons.today_rounded,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatItem(
                    label: 'Đã hoàn thành',
                    value: completedToday.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Tìm theo tên, mô tả hoặc nhóm',
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _selectedCategory.isEmpty,
            onSelected: (_) {
              setState(() {
                _selectedCategory = '';
              });
            },
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = _selectedCategory == category ? '' : category;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSelector(ThemeData theme) {
    return SegmentedButton<_SortOption>(
      segments: const [
        ButtonSegment<_SortOption>(
          value: _SortOption.latest,
          label: Text('Mới nhất'),
          icon: Icon(Icons.schedule),
        ),
        ButtonSegment<_SortOption>(
          value: _SortOption.name,
          label: Text('A-Z'),
          icon: Icon(Icons.sort_by_alpha),
        ),
        ButtonSegment<_SortOption>(
          value: _SortOption.schedule,
          label: Text('Theo lịch'),
          icon: Icon(Icons.repeat),
        ),
      ],
      selected: {_sortOption},
      onSelectionChanged: (values) {
        if (values.isEmpty) return;
        setState(() {
          _sortOption = values.first;
        });
      },
      style: ButtonStyle(
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool noHabitYet) {
    final theme = Theme.of(context);
    final text = noHabitYet
        ? 'Bạn chưa có thói quen nào. Tạo thói quen đầu tiên để bắt đầu.'
        : 'Không có thói quen phù hợp bộ lọc hiện tại.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (noHabitYet)
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Tạo thói quen'),
            ),
        ],
      ),
    );
  }

  List<Habit> _buildFilteredHabits(List<Habit> source) {
    var result = source.where((habit) {
      final query = _searchQuery;
      final inSearch = query.isEmpty ||
          habit.title.toLowerCase().contains(query) ||
          habit.detail.toLowerCase().contains(query) ||
          habit.category.toLowerCase().contains(query);
      final inCategory = _selectedCategory.isEmpty || habit.category == _selectedCategory;
      return inSearch && inCategory;
    }).toList();

    switch (_sortOption) {
      case _SortOption.latest:
        result.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case _SortOption.name:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortOption.schedule:
        result.sort((a, b) => _scheduleLabel(a).compareTo(_scheduleLabel(b)));
        break;
    }

    return result;
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HabitFormScreen(),
      ),
    );
    if (!mounted) return;
    await context.read<HabitProvider>().refreshHabits();
  }

  Future<void> _openEdit(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitFormScreen(existingHabit: habit),
      ),
    );
    if (!mounted) return;
    await context.read<HabitProvider>().refreshHabits();
  }

  Future<void> _showDeleteConfirmation(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thói quen "${habit.title}" không?'),
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

    if (confirmed != true || !mounted) return;

    final success = await context.read<HabitProvider>().deleteHabit(habit.id);
    if (!success || !mounted) return;

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

  String _scheduleLabel(Habit habit) {
    if (habit.type == HabitType.interval) {
      return 'Mỗi ${habit.intervalDays ?? 1} ngày';
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
    return days.map((day) => labels[day] ?? '').where((s) => s.isNotEmpty).join(', ');
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

class _HabitManagementCard extends StatelessWidget {
  final Habit habit;
  final int completionCount;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _HabitManagementCard({
    required this.habit,
    required this.completionCount,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompletedToday = completionCount >= habit.timesPerDay;
    final schedule = _scheduleText(habit);
    final progress = (completionCount / habit.timesPerDay).clamp(0.0, 1.0);
    final isDueToday = habit.isDueOn(DateTime.now());

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
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditTap();
                    } else if (value == 'delete') {
                      onDeleteTap();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ],
            ),
            if (habit.detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                habit.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.repeat, label: schedule),
                _InfoChip(icon: Icons.exposure_plus_1, label: '${habit.timesPerDay} lần/ngày'),
                if (habit.category.isNotEmpty) _InfoChip(icon: Icons.sell_outlined, label: habit.category),
                _InfoChip(
                  icon: isDueToday ? Icons.today : Icons.event_busy,
                  label: isDueToday ? 'Đến hạn hôm nay' : 'Không đến hạn hôm nay',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompletedToday ? Colors.green : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$completionCount/${habit.timesPerDay}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCompletedToday ? Colors.green : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleText(Habit habit) {
    if (habit.type == HabitType.interval) {
      return 'Mỗi ${habit.intervalDays ?? 1} ngày';
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
    return days.map((day) => labels[day] ?? '').where((s) => s.isNotEmpty).join(', ');
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
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
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
