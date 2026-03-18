import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/calendar_provider.dart';
import '../services/auth_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/view_mode_selector.dart';
import '../widgets/habit_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewMode _selectedViewMode = ViewMode.day;
  Set<String> _selectedCategories = {};
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit tracker - Nhóm 2'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, calendarProvider, _) => Consumer<HabitProvider>(
          builder: (context, habitProvider, _) {
            // Lấy danh sách thói quen cho ngày đã chọn từ CalendarProvider,
            // và đảm bảo chỉ dùng những habit còn tồn tại trong HabitProvider
            final List<Habit> calendarHabits = calendarProvider.habitsForToday;
            List<Habit> habitList = calendarHabits
                .where((h) => habitProvider.getHabitById(h.id) != null)
                .toList();

            // Áp dụng filter theo category
            if (_selectedCategories.isNotEmpty) {
              habitList = habitList
                  .where((h) => _selectedCategories.contains(h.category))
                  .toList();
            }

            final categories = habitProvider.categories;

            return Column(
              children: [
                // View Mode Selector
                ViewModeSelector(
                  selectedMode: _selectedViewMode,
                  onModeChanged: (mode) {
                    setState(() {
                      _selectedViewMode = mode;
                    });
                  },
                ),
                const Divider(),
                // Filter Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Mở màn hình danh sách thói quen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mở danh sách thói quen'),
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
                // Habits List
                Expanded(
                  child: (habitProvider.isLoading || calendarProvider.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : habitList.isEmpty
                      ? Center(
                          child: Text(
                            _selectedCategories.isEmpty
                                ? 'Không có thói quen nào'
                                : 'Không có thói quen nào trong filter đã chọn',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                              onCompleteTap: () {
                                if (userId != null) {
                                  calendarProvider.toggleCompletion(
                                    habit.id,
                                    userId,
                                    _selectedDate,
                                    habit.timesPerDay,
                                  );
                                }
                              },
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
}
