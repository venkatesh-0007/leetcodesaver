import 'package:sqflite/sqflite.dart';
import '../models/difficulty.dart';
import '../models/saved_problem.dart';
import 'database_helper.dart';

class ProblemDao {
  Future<List<SavedProblem>> getAllProblems() async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_problems',
      orderBy: 'id DESC',
    );
    return maps.map((m) => SavedProblem.fromMap(m)).toList();
  }

  Future<SavedProblem?> getProblemById(int id) async {
    final db = await DatabaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_problems',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SavedProblem.fromMap(maps.first);
  }

  Future<int> insertProblem(SavedProblem problem) async {
    final db = await DatabaseHelper.database;
    return await db.insert('saved_problems', problem.toMap());
  }

  Future<int> updateProblem(SavedProblem problem) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      'saved_problems',
      problem.toMap(),
      where: 'id = ?',
      whereArgs: [problem.id],
    );
  }

  Future<int> deleteProblem(int id) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      'saved_problems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SavedProblem>> searchAndFilter({
    String? query,
    Difficulty? difficulty,
    String? language,
  }) async {
    final db = await DatabaseHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR slug LIKE ? OR notes LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (difficulty != null) {
      whereClauses.add('difficulty = ?');
      whereArgs.add(difficulty.name);
    }

    if (language != null && language != 'All') {
      whereClauses.add('language = ?');
      whereArgs.add(language);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'saved_problems',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    return maps.map((m) => SavedProblem.fromMap(m)).toList();
  }

  /// Retrieves eligible problems for random selection.
  /// Prioritizes:
  /// 1. Problems not submitted within the [cooldownDays] window.
  /// 2. If all problems have been submitted within cooldown, falls back to least recently used problem.
  /// 3. Filters by [preferredLanguage] if specified and available.
  Future<List<SavedProblem>> getEligibleProblems({
    int cooldownDays = 7,
    String? preferredLanguage,
  }) async {
    final all = await getAllProblems();
    if (all.isEmpty) return [];

    final now = DateTime.now();
    final cooldownThreshold = now.subtract(Duration(days: cooldownDays));

    // Filter by preferred language if requested and any exist
    List<SavedProblem> candidatePool = all;
    if (preferredLanguage != null && preferredLanguage.isNotEmpty && preferredLanguage != 'All') {
      final langFiltered = all.where((p) => p.language.toLowerCase() == preferredLanguage.toLowerCase()).toList();
      if (langFiltered.isNotEmpty) {
        candidatePool = langFiltered;
      }
    }

    // Filter by cooldown (not submitted within cooldown days)
    final cooledDown = candidatePool.where((p) {
      if (p.lastSubmittedDate == null) return true;
      return p.lastSubmittedDate!.isBefore(cooldownThreshold);
    }).toList();

    if (cooledDown.isNotEmpty) {
      return cooledDown;
    }

    // Fallback: sort by least recently submitted so we don't pick the most recent one
    candidatePool.sort((a, b) {
      if (a.lastSubmittedDate == null) return -1;
      if (b.lastSubmittedDate == null) return 1;
      return a.lastSubmittedDate!.compareTo(b.lastSubmittedDate!);
    });

    return candidatePool;
  }

  /// Record a submission attempt on a problem.
  /// Never overwrites the source code! Only increments attempt counter and updates lastSubmittedDate on Accepted.
  Future<void> recordSubmissionAttempt({
    required int problemId,
    required bool isAccepted,
  }) async {
    final db = await DatabaseHelper.database;
    final problem = await getProblemById(problemId);
    if (problem == null) return;

    final updatedAttempts = problem.submissionAttempts + 1;
    final updatedLastSubmitted = isAccepted ? DateTime.now() : problem.lastSubmittedDate;

    await db.update(
      'saved_problems',
      {
        'submission_attempts': updatedAttempts,
        if (isAccepted) 'last_submitted_date': updatedLastSubmitted?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [problemId],
    );
  }

  /// Bulk export all problems for backup
  Future<List<Map<String, dynamic>>> exportAll() async {
    final db = await DatabaseHelper.database;
    return await db.query('saved_problems');
  }

  /// Bulk import problems
  Future<int> importProblems(List<Map<String, dynamic>> problems) async {
    final db = await DatabaseHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final p in problems) {
        final mutable = Map<String, dynamic>.from(p)..remove('id');
        await txn.insert('saved_problems', mutable, conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    });
    return count;
  }
}

