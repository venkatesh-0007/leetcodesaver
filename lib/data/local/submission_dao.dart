import 'package:sqflite/sqflite.dart';
import '../models/submission_attempt.dart';
import 'database_helper.dart';

class SubmissionDao {
  Future<int> insertSubmission(SubmissionAttempt attempt) async {
    final db = await DatabaseHelper.database;
    return await db.insert('submission_attempts', attempt.toMap());
  }

  Future<List<SubmissionAttempt>> getAllSubmissions({int limit = 100}) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'submission_attempts',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => SubmissionAttempt.fromMap(m)).toList();
  }

  Future<List<SubmissionAttempt>> getSubmissionsForProblem(int problemId) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'submission_attempts',
      where: 'problem_id = ?',
      whereArgs: [problemId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => SubmissionAttempt.fromMap(m)).toList();
  }

  Future<SubmissionAttempt?> getLatestAcceptedToday() async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'submission_attempts',
      where: 'verdict = ? AND timestamp >= ?',
      whereArgs: [SubmissionVerdict.accepted.name, todayStart],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SubmissionAttempt.fromMap(maps.first);
  }

  Future<void> clearHistory() async {
    final db = await DatabaseHelper.database;
    await db.delete('submission_attempts');
  }

  Future<List<Map<String, dynamic>>> exportAll() async {
    final db = await DatabaseHelper.database;
    return await db.query('submission_attempts');
  }

  Future<int> importSubmissions(List<Map<String, dynamic>> submissions) async {
    final db = await DatabaseHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final s in submissions) {
        final mutable = Map<String, dynamic>.from(s)..remove('id');
        await txn.insert('submission_attempts', mutable, conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    });
    return count;
  }
}

