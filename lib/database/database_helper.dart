import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/problem.dart';

/// Handles all local SQLite database access for SolveLog.
///
/// This is a simple singleton: call `DatabaseHelper.instance` anywhere
/// you need the database, and it takes care of creating/opening it the
/// first time it's used.
///
/// Two tables are created:
/// - `problems`   — one row per saved problem (holds its category, so
///                  Codeforces/LeetCode/AtCoder/etc. problems stay separate)
/// - `approaches` — one row per approach, linked to a problem by `problemId`
///                  (a problem can have many approaches)
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// The open database. Opens/creates it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // sqflite doesn't talk to native SQLite on desktop by itself.
    // sqflite_common_ffi provides that desktop (macOS/Windows/Linux)
    // implementation, so we point sqflite at it before opening anything.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'solvelog.db');

    return openDatabase(
      path,
      version: 3, // Incremented version for do_later table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE problems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        problemName TEXT NOT NULL,
        problemId TEXT NOT NULL,
        rating TEXT,
        problemLink TEXT,
        code TEXT,
        questionUnderstanding TEXT,
        problemsFaced TEXT,
        anyNewThingLearnt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE approaches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        problemId INTEGER NOT NULL,
        approachText TEXT,
        approachCode TEXT,
        FOREIGN KEY (problemId) REFERENCES problems (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE do_later (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        problemId TEXT,
        problemLink TEXT,
        reason TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add approachCode column to existing approaches table
      await db.execute('''
        ALTER TABLE approaches ADD COLUMN approachCode TEXT DEFAULT ''
      ''');
    }
    if (oldVersion < 3) {
      // Add do_later table for problems to do later
      await db.execute('''
        CREATE TABLE do_later (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          problemId TEXT,
          problemLink TEXT,
          reason TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  /// Saves a new problem with its approaches in a transaction.
  ///
  /// `createdAt` is set automatically to the current date/time — you
  /// never need to pass it in yourself.
  /// 
  /// Returns the generated problem ID on success.
  /// If anything fails, the entire transaction is rolled back.
  Future<int> insertProblemWithApproaches(
    Problem problem,
    List<Map<String, String>> approaches, // Changed to accept text and code
  ) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Insert problem
      final problemMap = problem.toMap();
      problemMap.remove('id'); // let SQLite auto-generate this
      problemMap['createdAt'] = DateTime.now().toIso8601String();

      final problemId = await txn.insert('problems', problemMap);

      // Insert approaches
      for (final approach in approaches) {
        final text = approach['text'] ?? '';
        final code = approach['code'] ?? '';
        if (text.trim().isNotEmpty || code.trim().isNotEmpty) {
          await txn.insert('approaches', {
            'problemId': problemId,
            'approachText': text,
            'approachCode': code,
          });
        }
      }

      return problemId;
    });
  }

  /// Saves a new problem and returns its generated id.
  ///
  /// `createdAt` is set automatically to the current date/time — you
  /// never need to pass it in yourself.
  Future<int> insertProblem(Problem problem) async {
    final db = await database;

    final problemMap = problem.toMap();
    problemMap.remove('id'); // let SQLite auto-generate this
    problemMap['createdAt'] = DateTime.now().toIso8601String();

    return db.insert('problems', problemMap);
  }

  /// Saves a list of approach texts, all linked to the given problem.
  Future<void> insertApproaches(
    int problemId,
    List<String> approachTexts,
  ) async {
    final db = await database;

    for (final text in approachTexts) {
      if (text.trim().isNotEmpty) {
        await db.insert('approaches', {
          'problemId': problemId,
          'approachText': text,
        });
      }
    }
  }

  /// Returns every problem saved under [category] (e.g. "Codeforces"),
  /// newest first. Categories are kept completely separate — a problem
  /// only ever shows up for the category it was saved under.
  Future<List<Problem>> getProblemsByCategory(String category) async {
    final db = await database;

    final rows = await db.query(
      'problems',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );

    return rows.map((row) => Problem.fromMap(row)).toList();
  }

  /// Returns a single problem with all its approaches.
  Future<Map<String, dynamic>?> getProblemWithApproaches(int problemId) async {
    final db = await database;

    final problemRows = await db.query(
      'problems',
      where: 'id = ?',
      whereArgs: [problemId],
    );

    if (problemRows.isEmpty) return null;

    final problem = Problem.fromMap(problemRows.first);

    final approachRows = await db.query(
      'approaches',
      where: 'problemId = ?',
      whereArgs: [problemId],
    );

    final approaches =
        approachRows.map((row) => Approach.fromMap(row)).toList();

    return {
      'problem': problem,
      'approaches': approaches,
    };
  }

  /// Deletes a problem and all its approaches.
  Future<void> deleteProblem(int problemId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'approaches',
        where: 'problemId = ?',
        whereArgs: [problemId],
      );
      await txn.delete(
        'problems',
        where: 'id = ?',
        whereArgs: [problemId],
      );
    });
  }

  /// Returns the count of problems in a category.
  Future<int> getProblemCountByCategory(String category) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM problems WHERE category = ?',
      [category],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Do Later operations
  
  /// Adds a problem to the "Do Later" list.
  Future<int> insertDoLater({
    required String category,
    String? problemId,
    String? problemLink,
    required String reason,
  }) async {
    final db = await database;

    return db.insert('do_later', {
      'category': category,
      'problemId': problemId,
      'problemLink': problemLink,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Returns all "Do Later" problems for a category.
  Future<List<Map<String, dynamic>>> getDoLaterByCategory(String category) async {
    final db = await database;

    final rows = await db.query(
      'do_later',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );

    return rows;
  }

  /// Deletes a "Do Later" problem.
  Future<void> deleteDoLater(int id) async {
    final db = await database;

    await db.delete(
      'do_later',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the count of "Do Later" problems in a category.
  Future<int> getDoLaterCountByCategory(String category) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM do_later WHERE category = ?',
      [category],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}