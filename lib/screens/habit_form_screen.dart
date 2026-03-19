import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? existingHabit;

  const HabitFormScreen({super.key, this.existingHabit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _categoryController = TextEditingController();
  final _timesPerDayController = TextEditingController();
  final _intervalDaysController = TextEditingController();

  HabitType _type = HabitType.weekly;
  DateTime _startDate = DateTime.now();
  final Set<int> _weeklyDays = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.existingHabit;
    if (habit != null) {
      _titleController.text = habit.title;
      _detailController.text = habit.detail;
      _categoryController.text = habit.category;
      _timesPerDayController.text = habit.timesPerDay.toString();
      _intervalDaysController.text = (habit.intervalDays ?? 1).toString();
      _type = habit.type;
      _startDate = habit.startDate;
      _weeklyDays.addAll(habit.weeklyDays ?? const []);
    } else {
      _timesPerDayController.text = '1';
      _intervalDaysController.text = '2';
      _startDate = _dateOnly(DateTime.now());
      _weeklyDays.add(_startDate.weekday);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _categoryController.dispose();
    _timesPerDayController.dispose();
    _intervalDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingHabit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa thói quen' : 'Tạo thói quen'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Ví dụ: Uống nước',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              maxLength: 60,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailController,
              decoration: const InputDecoration(
                labelText: 'Chi tiết',
                hintText: 'Ví dụ: 8 ly mỗi ngày',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Nhóm / Thẻ',
                hintText: 'Ví dụ: Sức khỏe',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timesPerDayController,
                    decoration: const InputDecoration(
                      labelText: 'Số lần / ngày',
                      hintText: 'Ví dụ: 1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Nhập số lần hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    date: _startDate,
                    onPick: (date) => setState(() => _startDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Loại thói quen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            if (_type == HabitType.weekly) _buildWeeklyPicker(),
            if (_type == HabitType.interval) _buildIntervalPicker(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Lưu thay đổi' : 'Tạo thói quen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        RadioListTile<HabitType>(
          value: HabitType.weekly,
          groupValue: _type,
          onChanged: (value) => _setType(value ?? HabitType.weekly),
          title: const Text('Theo tuần'),
          subtitle: const Text('Chọn các thứ trong tuần để thực hiện'),
        ),
        RadioListTile<HabitType>(
          value: HabitType.interval,
          groupValue: _type,
          onChanged: (value) => _setType(value ?? HabitType.interval),
          title: const Text('Cách ngày'),
          subtitle: const Text('Thực hiện sau mỗi N ngày'),
        ),
      ],
    );
  }

  Widget _buildWeeklyPicker() {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngày trong tuần',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = _weeklyDays.contains(day);
            return FilterChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _weeklyDays.add(day);
                  } else {
                    _weeklyDays.remove(day);
                  }
                });
              },
            );
          }),
        ),
        if (_weeklyDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Hãy chọn ít nhất 1 ngày',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildIntervalPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _intervalDaysController,
          decoration: const InputDecoration(
            labelText: 'Mỗi bao nhiêu ngày',
            hintText: 'Ví dụ: 2',
            border: OutlineInputBorder(),
            helperText: 'VD: 2 = mỗi 2 ngày thực hiện 1 lần',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (_type != HabitType.interval) return null;
            if (parsed == null || parsed <= 0) {
              return 'Nhập số ngày hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _setType(HabitType type) {
    setState(() {
      _type = type;
    });
  }

  Future<void> _handleSave() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if (_type == HabitType.weekly && _weeklyDays.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần')),
        );
      }
      setState(() {});
      return;
    }

    setState(() => _isSaving = true);

    final habitProvider = context.read<HabitProvider>();
    final existing = widget.existingHabit;
    final habit = Habit(
      id: existing?.id ?? _generateId(),
      userId: existing?.userId,
      title: _titleController.text.trim(),
      detail: _detailController.text.trim(),
      type: _type,
      weeklyDays: _type == HabitType.weekly
          ? (_weeklyDays.toList()..sort())
          : null,
      intervalDays: _type == HabitType.interval
          ? int.tryParse(_intervalDaysController.text.trim()) ?? 1
          : null,
      startDate: _dateOnly(_startDate),
      timesPerDay: int.tryParse(_timesPerDayController.text.trim()) ?? 1,
      lastCompleted: existing?.lastCompleted,
      category: _categoryController.text.trim(),
      isDeleted: existing?.isDeleted ?? false,
    );

    try {
      final success = existing == null
          ? await habitProvider.addHabit(habit)
          : await habitProvider.updateHabit(habit);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa đăng nhập. Vui lòng đăng nhập để lưu thói quen.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _generateId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    // Use a safe max for web/JS integer range with Random.nextInt.
    final rand = Random().nextInt(1 << 31);
    return '${millis}_$rand';
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: date,
        );
        if (picked != null) {
          onPick(DateTime(picked.year, picked.month, picked.day));
        }
      },
      icon: const Icon(Icons.event),
      label: Text(_formatDate(date)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
