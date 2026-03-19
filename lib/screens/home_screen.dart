import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/calendar_provider.dart';
import 'habit_management_screen.dart';
import '../widgets/habit_card.dart';
import '../widgets/view_mode_selector.dart';
import '../widgets/habit_filter.dart';
import 'habit_form_screen.dart';

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
                Expanded(
                  child: (habitProvider.isLoading || calendarProvider.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : habitList.isEmpty
                          ? Center(
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
                            )
                          : ListView.builder(
                              itemCount: habitList.length,
                              itemBuilder: (context, index) {
                                final habit = habitList[index];
                                final isCompleted =
                                    (calendarProvider.completionCount[habit.id] ??
                                            0) >=
                                        habit.timesPerDay;

                                return HabitCard(
                                  habit: habit,
                                  isCompleted: isCompleted,
                                  onCompleteTap: () async {
                                    final newCount =
                                        await calendarProvider.toggleCompletion(
                                      habit.id,
                                      selectedDate,
                                      habit.timesPerDay,
                                    );
                                    if (newCount >= habit.timesPerDay) {
                                      await context
                                          .read<HabitProvider>()
                                          .markCompleted(habit.id);
                                    }
                                  },
                                  onEditTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            HabitFormScreen(existingHabit: habit),
                                      ),
                                    );
                                  },
                                  onDeleteTap: () => _showDeleteConfirmation(context, habit),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
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
