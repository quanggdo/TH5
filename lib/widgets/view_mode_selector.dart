import 'package:flutter/material.dart';

enum ViewMode { day, week, month }

class ViewModeSelector extends StatelessWidget {
  final ViewMode selectedMode;
  final Function(ViewMode) onModeChanged;

  const ViewModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SegmentedButton<ViewMode>(
        segments: const [
          ButtonSegment(value: ViewMode.day, label: Text('Ngày')),
          ButtonSegment(value: ViewMode.week, label: Text('Tuần')),
          ButtonSegment(value: ViewMode.month, label: Text('Tháng')),
        ],
        selected: {selectedMode},
        onSelectionChanged: (value) => onModeChanged(value.first),
        showSelectedIcon: false,
      ),
    );
  }
}
