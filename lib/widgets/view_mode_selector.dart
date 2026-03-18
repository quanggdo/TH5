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
      child: Row(
        children: [
          Expanded(child: _buildModeButton(context, ViewMode.day, 'Ngày')),
          const SizedBox(width: 8),
          Expanded(child: _buildModeButton(context, ViewMode.week, 'Tuần')),
          const SizedBox(width: 8),
          Expanded(child: _buildModeButton(context, ViewMode.month, 'Tháng')),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, ViewMode mode, String label) {
    final isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () => onModeChanged(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}
