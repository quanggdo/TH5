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
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategories.isEmpty
        ? null
        : _normalize(widget.selectedCategories.first);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lọc thói quen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Tất cả'),
              value: _selectedCategory == null,
              onChanged: (value) {
                if (value != true) return;
                setState(() => _selectedCategory = null);
              },
            ),
            const Divider(),
            ...widget.categories.map(
              (category) => CheckboxListTile(
                title: Text(category.isEmpty ? 'Không có nhóm' : category),
                value: _selectedCategory == _normalize(category),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategory = _normalize(category);
                    } else {
                      _selectedCategory = null;
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
        FilledButton(
          onPressed: () {
            if (_selectedCategory == null) {
              widget.onFilterChanged(<String>{});
            } else {
              widget.onFilterChanged({_selectedCategory!});
            }
            Navigator.pop(context);
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }

  String _normalize(String? value) => (value ?? '').trim().toLowerCase();
}
