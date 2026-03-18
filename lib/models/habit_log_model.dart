import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  String? id;
  String habitId;
  String userId;
  String date; // Định dạng YYYY-MM-DD
  bool isCompleted;
  int count; // Số lần đã hoàn thành trong ngày (VD: 2/3)

  HabitLog({
    this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.isCompleted,
    this.count = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'habitId': habitId,
        'userId': userId,
        'date': date,
        'isCompleted': isCompleted,
        'count': count,
      };

  factory HabitLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitLog(
      id: doc.id,
      habitId: data['habitId'] as String,
      userId: data['userId'] as String,
      date: data['date'] as String,
      isCompleted: data['isCompleted'] as bool? ?? false,
      count: data['count'] as int? ?? 0,
    );
  }

  /// Dùng để lưu pending logs vào SharedPreferences khi offline
  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'userId': userId,
        'date': date,
        'isCompleted': isCompleted,
        'count': count,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        habitId: json['habitId'] as String,
        userId: json['userId'] as String,
        date: json['date'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        count: json['count'] as int? ?? 0,
      );
}
