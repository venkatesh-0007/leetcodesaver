import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'default_problems.dart';

class DatabaseHelper {
  static const String _databaseName = 'leetstreak.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  static void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 1. Saved Problems table
    await db.execute('''
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

    // 2. Submission Attempts table
    await db.execute('''
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

    // 3. Heatmap Cache table
    await db.execute('''
      CREATE TABLE heatmap_cache (
        date_key TEXT PRIMARY KEY,
        count INTEGER NOT NULL,
        level INTEGER NOT NULL
      )
    ''');

    // Pre-populate with default accepted solutions
    final defaults = DefaultProblems.getInitialProblems();
    for (final problem in defaults) {
      await db.insert('saved_problems', problem.toMap());
    }
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

