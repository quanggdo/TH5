enum HabitType { weekly, interval }

class Habit {
  String id;
  String? userId; // Added userId
  String title;
  String detail;
  HabitType type;
  List<int>? weeklyDays;
  int? intervalDays;
  DateTime startDate;
  int timesPerDay;
  DateTime? lastCompleted;
  String category;
  bool isDeleted;

  Habit({
    required this.id,
    this.userId,
    required this.title,
    required this.detail,
    required this.type,
    this.weeklyDays,
    this.intervalDays,
    required this.startDate,
    this.timesPerDay = 1,
    this.lastCompleted,
    this.category = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'detail': detail,
        'type': type.name,
        'weeklyDays': weeklyDays,
        'intervalDays': intervalDays,
        'startDate': startDate.toIso8601String(),
        'timesPerDay': timesPerDay,
        'lastCompleted': lastCompleted?.toIso8601String(),
        'category': category,
        'isDeleted': isDeleted,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        title: json['title'] as String,
        detail: json['detail'] as String,
        type: HabitType.values.byName(json['type'] as String),
        weeklyDays: (json['weeklyDays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
        intervalDays: json['intervalDays'] as int?,
        startDate: DateTime.parse(json['startDate'] as String),
        timesPerDay: json['timesPerDay'] as int? ?? 1,
        lastCompleted: json['lastCompleted'] != null
            ? DateTime.parse(json['lastCompleted'] as String)
            : null,
        category: json['category'] as String? ?? '',
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  /// Kiểm tra thói quen này có cần thực hiện vào [date] không
  bool isDueOn(DateTime date) {
    if (isDeleted) return false;

    final d1 = DateTime(date.year, date.month, date.day);
    final d2 = DateTime(startDate.year, startDate.month, startDate.day);

    if (d1.isBefore(d2)) return false;

    switch (type) {
      case HabitType.weekly:
        return weeklyDays?.contains(d1.weekday) ?? false;
      case HabitType.interval:
        if (intervalDays == null || intervalDays! <= 0) return false;
        return d1.difference(d2).inDays % intervalDays! == 0;
    }
  }
}
