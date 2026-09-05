/// A single coding problem stored in SolveLog.
///
/// This mirrors one row in the `problems` table. `id` and `createdAt`
/// are filled in automatically by [DatabaseHelper] — you don't need to
/// set them yourself when creating a new [Problem] to save.
class Problem {
  final int? id;
  final String category;
  final String problemName;
  final String problemId;
  final String rating;
  final String problemLink;
  final String code;
  final String questionUnderstanding;
  final String problemsFaced;
  final String anyNewThingLearnt;
  final String? createdAt;

  Problem({
    this.id,
    required this.category,
    required this.problemName,
    required this.problemId,
    this.rating = '',
    this.problemLink = '',
    this.code = '',
    this.questionUnderstanding = '',
    this.problemsFaced = '',
    this.anyNewThingLearnt = '',
    this.createdAt,
  });

  /// Converts this problem into a Map so it can be saved to SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'problemName': problemName,
      'problemId': problemId,
      'rating': rating,
      'problemLink': problemLink,
      'code': code,
      'questionUnderstanding': questionUnderstanding,
      'problemsFaced': problemsFaced,
      'anyNewThingLearnt': anyNewThingLearnt,
      'createdAt': createdAt,
    };
  }

  /// Builds a [Problem] from a row read out of SQLite.
  factory Problem.fromMap(Map<String, dynamic> map) {
    return Problem(
      id: map['id'] as int?,
      category: map['category'] as String,
      problemName: map['problemName'] as String,
      problemId: map['problemId'] as String,
      rating: map['rating'] as String? ?? '',
      problemLink: map['problemLink'] as String? ?? '',
      code: map['code'] as String? ?? '',
      questionUnderstanding: map['questionUnderstanding'] as String? ?? '',
      problemsFaced: map['problemsFaced'] as String? ?? '',
      anyNewThingLearnt: map['anyNewThingLearnt'] as String? ?? '',
      createdAt: map['createdAt'] as String?,
    );
  }
}

/// One approach/explanation of how a [Problem] was solved.
///
/// A single problem can have multiple approaches, so approaches live in
/// their own table (`approaches`) and each one points back to its
/// problem via [problemId].
class Approach {
  final int? id;
  final int problemId;
  final String approachText;

  Approach({
    this.id,
    required this.problemId,
    required this.approachText,
  });

  /// Converts this approach into a Map so it can be saved to SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'problemId': problemId,
      'approachText': approachText,
    };
  }

  /// Builds an [Approach] from a row read out of SQLite.
  factory Approach.fromMap(Map<String, dynamic> map) {
    return Approach(
      id: map['id'] as int?,
      problemId: map['problemId'] as int,
      approachText: map['approachText'] as String? ?? '',
    );
  }
}