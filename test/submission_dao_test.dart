import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:leetstreak/data/local/database_helper.dart';
import 'package:leetstreak/data/local/submission_dao.dart';
import 'package:leetstreak/data/models/submission_attempt.dart';

void main() {
  late SubmissionDao dao;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE submission_attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            problem_id INTEGER NOT NULL,
            problem_title TEXT NOT NULL,
            problem_slug TEXT NOT NULL,
            language TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            verdict TEXT NOT NULL,
            leetcode_submission_id TEXT,
            details TEXT
          )
        ''');
      },
    );
    DatabaseHelper.setDatabaseForTesting(db);
    dao = SubmissionDao();
  });

  tearDownAll(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('SubmissionDao Tests', () {
    test('Insert and retrieve submission attempts with status verdicts', () async {
      final attempt = SubmissionAttempt(
        problemId: 1,
        problemTitle: 'Two Sum',
        problemSlug: 'two-sum',
        language: 'Python 3',
        timestamp: DateTime.now(),
        verdict: SubmissionVerdict.accepted,
        leetCodeSubmissionId: '10928374',
        details: 'Runtime: 45ms, Beats 89%',
      );

      final id = await dao.insertSubmission(attempt);
      expect(id, greaterThan(0));

      final all = await dao.getAllSubmissions();
      expect(all.any((s) => s.id == id && s.verdict == SubmissionVerdict.accepted), isTrue);

      final todayAccepted = await dao.getLatestAcceptedToday();
      expect(todayAccepted, isNotNull);
      expect(todayAccepted!.verdict, equals(SubmissionVerdict.accepted));
    });

    test('Non-accepted submission is distinctly preserved', () async {
      final failedAttempt = SubmissionAttempt(
        problemId: 2,
        problemTitle: 'Add Two Numbers',
        problemSlug: 'add-two-numbers',
        language: 'Java',
        timestamp: DateTime.now(),
        verdict: SubmissionVerdict.wrongAnswer,
        details: 'Test case 12 failed',
      );

      final id = await dao.insertSubmission(failedAttempt);
      expect(id, greaterThan(0));

      final all = await dao.getAllSubmissions();
      final retrieved = all.firstWhere((s) => s.id == id);
      expect(retrieved.verdict, equals(SubmissionVerdict.wrongAnswer));
    });
  });
}
