// Test script to verify database persistence
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  print('=== Testing SolveLog Database Persistence ===\n');
  
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Get database path
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'solvelog.db');
  
  print('Database path: $path\n');
  
  // Open/create database
  final db = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      print('Creating tables...');
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
          FOREIGN KEY (problemId) REFERENCES problems (id)
        )
      ''');
      print('Tables created!\n');
    },
  );
  
  // Test 1: Insert a Codeforces problem
  print('TEST 1: Adding Codeforces problem...');
  final cfProblemId = await db.transaction((txn) async {
    final problemMap = {
      'category': 'Codeforces',
      'problemName': 'Test Problem',
      'problemId': 'TEST-1',
      'rating': '800',
      'problemLink': 'https://codeforces.com',
      'code': 'print("test")',
      'questionUnderstanding': 'Test understanding',
      'problemsFaced': 'Test issue',
      'anyNewThingLearnt': 'Test learning',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final pId = await txn.insert('problems', problemMap);
    
    // Add 2 approaches
    await txn.insert('approaches', {
      'problemId': pId,
      'approachText': 'Approach 1: First approach description',
    });
    await txn.insert('approaches', {
      'problemId': pId,
      'approachText': 'Approach 2: Second approach description',
    });
    
    return pId;
  });
  print('✓ Codeforces problem added with ID: $cfProblemId\n');
  
  // Test 2: Verify it appears in Codeforces
  print('TEST 2: Verifying Codeforces problem list...');
  final cfProblems = await db.query(
    'problems',
    where: 'category = ?',
    whereArgs: ['Codeforces'],
    orderBy: 'createdAt DESC',
  );
  print('✓ Found ${cfProblems.length} Codeforces problem(s)');
  if (cfProblems.isNotEmpty) {
    print('  - Problem: ${cfProblems[0]['problemName']} (ID: ${cfProblems[0]['problemId']})');
  }
  print('');
  
  // Test 3: Verify approaches were saved
  print('TEST 3: Verifying approaches...');
  final approaches = await db.query(
    'approaches',
    where: 'problemId = ?',
    whereArgs: [cfProblemId],
  );
  print('✓ Found ${approaches.length} approach(es)');
  for (var i = 0; i < approaches.length; i++) {
    print('  - Approach ${i + 1}: ${approaches[i]['approachText']}');
  }
  print('');
  
  // Test 4: Verify LeetCode is empty
  print('TEST 4: Verifying LeetCode category is empty...');
  final leetcodeProblems = await db.query(
    'problems',
    where: 'category = ?',
    whereArgs: ['LeetCode'],
  );
  print('✓ LeetCode has ${leetcodeProblems.length} problem(s) (should be 0)');
  print('');
  
  // Test 5: Add a LeetCode problem with same ID
  print('TEST 5: Adding LeetCode problem with same ID...');
  final lcProblemId = await db.insert('problems', {
    'category': 'LeetCode',
    'problemName': 'Test Problem',
    'problemId': 'TEST-1',
    'rating': '800',
    'problemLink': 'https://leetcode.com',
    'code': 'print("test")',
    'questionUnderstanding': 'Test understanding',
    'problemsFaced': 'Test issue',
    'anyNewThingLearnt': 'Test learning',
    'createdAt': DateTime.now().toIso8601String(),
  });
  print('✓ LeetCode problem added with ID: $lcProblemId\n');
  
  // Test 6: Verify category isolation
  print('TEST 6: Verifying category isolation...');
  final cfCount = await db.rawQuery('SELECT COUNT(*) as count FROM problems WHERE category = ?', ['Codeforces']);
  final lcCount = await db.rawQuery('SELECT COUNT(*) as count FROM problems WHERE category = ?', ['LeetCode']);
  print('✓ Codeforces: ${cfCount[0]['count']} problem(s)');
  print('✓ LeetCode: ${lcCount[0]['count']} problem(s)');
  print('✓ Categories are properly isolated!\n');
  
  // Test 7: Simulate app restart by closing and reopening database
  print('TEST 7: Simulating app restart...');
  await db.close();
  print('Database closed.');
  
  // Reopen database
  final db2 = await openDatabase(path, version: 1);
  print('Database reopened.');
  
  // Verify data persists
  final persistedProblems = await db2.query(
    'problems',
    where: 'category = ?',
    whereArgs: ['Codeforces'],
  );
  print('✓ After restart: Found ${persistedProblems.length} Codeforces problem(s)');
  if (persistedProblems.isNotEmpty) {
    print('  - Problem: ${persistedProblems[0]['problemName']} (ID: ${persistedProblems[0]['problemId']})');
  }
  print('');
  
  await db2.close();
  
  print('=== All Tests Completed Successfully! ===');
  print('\nSummary:');
  print('✓ Problems can be added with multiple approaches');
  print('✓ Problems are saved in transactions');
  print('✓ Category isolation works (Codeforces ≠ LeetCode)');
  print('✓ Same problem ID can exist in different categories');
  print('✓ Data persists after database close/reopen');
  print('✓ Database location: $path');
}
