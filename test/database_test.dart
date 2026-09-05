import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:solvelog/database/database_helper.dart';
import 'package:solvelog/models/problem.dart';

void main() {
  // Initialize FFI for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Persistence Tests', () {
    test('Add Codeforces problem with approaches', () async {
      final db = DatabaseHelper.instance;

      // Create test problem
      final problem = Problem(
        category: 'Codeforces',
        problemName: 'Test Problem',
        problemId: 'TEST-1',
        rating: '800',
        problemLink: 'https://codeforces.com',
        code: 'print("test")',
        questionUnderstanding: 'Test understanding',
        problemsFaced: 'Test issue',
        anyNewThingLearnt: 'Test learning',
      );

      final approaches = [
        'Approach 1: First approach description',
        'Approach 2: Second approach description',
      ];

      // Insert problem with approaches
      final problemId = await db.insertProblemWithApproaches(problem, approaches);

      expect(problemId, greaterThan(0));
      print('✓ Problem inserted with ID: $problemId');
    });

    test('Retrieve Codeforces problems', () async {
      final db = DatabaseHelper.instance;

      final problems = await db.getProblemsByCategory('Codeforces');

      expect(problems, isNotEmpty);
      expect(problems[0].problemName, equals('Test Problem'));
      expect(problems[0].problemId, equals('TEST-1'));
      expect(problems[0].rating, equals('800'));
      print('✓ Retrieved ${problems.length} Codeforces problem(s)');
    });

    test('Verify problem count', () async {
      final db = DatabaseHelper.instance;

      final count = await db.getProblemCountByCategory('Codeforces');

      expect(count, greaterThan(0));
      print('✓ Codeforces has $count problem(s)');
    });

    test('Category isolation - LeetCode should be empty', () async {
      final db = DatabaseHelper.instance;

      final leetcodeProblems = await db.getProblemsByCategory('LeetCode');

      expect(leetcodeProblems, isEmpty);
      print('✓ LeetCode has 0 problems (category isolation works)');
    });

    test('Add LeetCode problem with same ID', () async {
      final db = DatabaseHelper.instance;

      final problem = Problem(
        category: 'LeetCode',
        problemName: 'Test Problem',
        problemId: 'TEST-1',
        rating: '800',
        problemLink: 'https://leetcode.com',
        code: 'print("test")',
        questionUnderstanding: 'Test understanding',
        problemsFaced: 'Test issue',
        anyNewThingLearnt: 'Test learning',
      );

      final problemId = await db.insertProblemWithApproaches(problem, ['Approach 1']);

      expect(problemId, greaterThan(0));
      print('✓ LeetCode problem inserted with same ID: TEST-1');
    });

    test('Verify both problems exist in their categories', () async {
      final db = DatabaseHelper.instance;

      final cfProblems = await db.getProblemsByCategory('Codeforces');
      final lcProblems = await db.getProblemsByCategory('LeetCode');

      expect(cfProblems.length, equals(1));
      expect(lcProblems.length, equals(1));
      expect(cfProblems[0].category, equals('Codeforces'));
      expect(lcProblems[0].category, equals('LeetCode'));
      print('✓ Both categories have their respective problems');
    });

    test('Retrieve problem with approaches', () async {
      final db = DatabaseHelper.instance;

      // Get first Codeforces problem
      final problems = await db.getProblemsByCategory('Codeforces');
      final problemId = problems[0].id!;

      final result = await db.getProblemWithApproaches(problemId);

      expect(result, isNotNull);
      expect(result!['problem'], isA<Problem>());
      expect(result['approaches'], isA<List<Approach>>());
      final approaches = result['approaches'] as List<Approach>;
      expect(approaches.length, equals(2));
      print('✓ Retrieved problem with ${approaches.length} approaches');
    });
  });
}
