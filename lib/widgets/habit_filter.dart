import 'package:flutter/material.dart';

class HabitFilter extends StatefulWidget {
  final List<String> categories;
  final Set<String> selectedCategories;
  final Function(Set<String>) onFilterChanged;

  const HabitFilter({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onFilterChanged,
  });

  @override
  State<HabitFilter> createState() => _HabitFilterState();
}

class _HabitFilterState extends State<HabitFilter> {
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lọc thói quen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Tất cả" checkbox
            CheckboxListTile(
              title: const Text('Tất cả'),
              value: _selectedCategories.length == widget.categories.length,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedCategories = Set.from(widget.categories);
                  } else {
                    _selectedCategories.clear();
                  }
                });
              },
            ),
            const Divider(),
            // Category checkboxes
            ...widget.categories.map(
              (category) => CheckboxListTile(
                title: Text(category.isEmpty ? 'Không có loại' : category),
                value: _selectedCategories.contains(category),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFilterChanged(_selectedCategories);
            Navigator.pop(context);
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }
}
