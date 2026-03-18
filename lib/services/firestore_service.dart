import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _logsCollection => _db.collection('habit_logs');

  // ─── Single Log ───────────────────────────────────────────

  /// Đẩy hoặc cập nhật 1 log lên Firestore
  Future<void> syncLog(HabitLog log) async {
    // Dùng composite key để tránh trùng lặp
    final docId = '${log.userId}_${log.habitId}_${log.date}';
    await _logsCollection.doc(docId).set(
          log.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ─── Batch Sync (Offline → Online) ────────────────────────

  /// Đẩy một loạt pending logs lên Firestore bằng batch write
  Future<void> syncPendingLogs(List<HabitLog> pendingLogs) async {
    final batch = _db.batch();
    for (final log in pendingLogs) {
      final docId = '${log.userId}_${log.habitId}_${log.date}';
      batch.set(
        _logsCollection.doc(docId),
        log.toFirestore(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // ─── Query theo Ngày ──────────────────────────────────────

  /// Lấy logs cho 1 ngày cụ thể
  Future<List<HabitLog>> getLogsForDate(String userId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snapshot = await _logsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dateStr)
        .get();
    return snapshot.docs.map((doc) => HabitLog.fromFirestore(doc)).toList();
  }

  // ─── Query theo khoảng ngày (core) ─────────────────────────

  /// Query logs theo khoảng ngày bất kỳ — dùng chung cho Tuần/Tháng
  Future<List<HabitLog>> getLogsByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    final snapshot = await _logsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .get();
    return snapshot.docs.map((doc) => HabitLog.fromFirestore(doc)).toList();
  }

  // ─── Query theo Tuần ──────────────────────────────────────

  /// Lấy logs cho 1 tuần (từ startOfWeek đến startOfWeek + 6 ngày)
  Future<List<HabitLog>> getLogsForWeek(
      String userId, DateTime startOfWeek) async {
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 6));
    return getLogsByDateRange(userId, start, end);
  }

  // ─── Query theo Tháng ─────────────────────────────────────

  /// Lấy logs cho 1 tháng
  Future<List<HabitLog>> getLogsForMonth(
      String userId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0); // ngày cuối tháng
    return getLogsByDateRange(userId, start, end);
  }
}
