import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:leetstreak/data/local/database_helper.dart';
import 'package:leetstreak/data/local/default_problems.dart';
import 'package:leetstreak/data/local/problem_dao.dart';
import 'package:leetstreak/data/models/difficulty.dart';
import 'package:leetstreak/data/models/saved_problem.dart';

void main() {
  late ProblemDao dao;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE saved_problems (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            leetcode_id INTEGER,
            title TEXT NOT NULL,
            slug TEXT NOT NULL,
            url TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            language TEXT NOT NULL,
            source_code TEXT NOT NULL,
            is_accepted INTEGER NOT NULL DEFAULT 1,
            date_added TEXT NOT NULL,
            last_submitted_date TEXT,
            submission_attempts INTEGER NOT NULL DEFAULT 0,
            notes TEXT
          )
        ''');
        for (final p in DefaultProblems.getInitialProblems()) {
          await d.insert('saved_problems', p.toMap());
        }
      },
    );
    DatabaseHelper.setDatabaseForTesting(db);
    dao = ProblemDao();
  });

  tearDownAll(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('ProblemDao SQLite & Intelligent Selection Tests', () {
    test('Default problems are initialized upon creation', () async {
      final problems = await dao.getAllProblems();
      expect(problems.length, greaterThanOrEqualTo(8));
      expect(problems.any((p) => p.title == 'Two Sum'), isTrue);
    });

    test('Add, retrieve, and delete a custom problem', () async {
      final newProblem = SavedProblem(
        leetCodeId: 999,
        title: 'Custom Test Problem',
        slug: 'custom-test-problem',
        url: 'https://leetcode.com/problems/custom-test-problem/',
        difficulty: Difficulty.hard,
        language: 'Rust',
        sourceCode: 'fn main() { println!("Accepted"); }',
        dateAdded: DateTime.now(),
      );

      final id = await dao.insertProblem(newProblem);
      expect(id, greaterThan(0));

      final retrieved = await dao.getProblemById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Custom Test Problem'));
      expect(retrieved.difficulty, equals(Difficulty.hard));
      expect(retrieved.language, equals('Rust'));

      await dao.deleteProblem(id);
      final afterDelete = await dao.getProblemById(id);
      expect(afterDelete, isNull);
    });

    test('Search and filter by keyword, difficulty, and language', () async {
      final easyPython = await dao.searchAndFilter(
        difficulty: Difficulty.easy,
        language: 'Python 3',
      );
      expect(easyPython.every((p) => p.difficulty == Difficulty.easy), isTrue);
      expect(easyPython.every((p) => p.language == 'Python 3'), isTrue);

      final searchResult = await dao.searchAndFilter(query: 'Parentheses');
      expect(searchResult.any((p) => p.title.contains('Parentheses')), isTrue);
    });

    test('Eligible problem selection respects cooldown window', () async {
      final eligible = await dao.getEligibleProblems(cooldownDays: 7);
      expect(eligible.isNotEmpty, isTrue);

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      for (final p in eligible) {
        if (p.lastSubmittedDate != null) {
          expect(p.lastSubmittedDate!.isBefore(sevenDaysAgo), isTrue);
        }
      }
    });

    test('Recording submission attempt NEVER overwrites source code', () async {
      final problems = await dao.getAllProblems();
      final problem = problems.first;
      final originalCode = problem.sourceCode;
      final originalAttempts = problem.submissionAttempts;

      await dao.recordSubmissionAttempt(
        problemId: problem.id!,
        isAccepted: true,
      );

      final updated = await dao.getProblemById(problem.id!);
      expect(updated, isNotNull);
      expect(updated!.sourceCode, equals(originalCode)); // Source code preserved untouched!
      expect(updated.submissionAttempts, equals(originalAttempts + 1));
      expect(updated.lastSubmittedDate, isNotNull);
    });
  });
}
