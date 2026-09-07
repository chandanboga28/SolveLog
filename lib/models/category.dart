/// Model representing a competitive programming platform/category.
///
/// Supports both predefined platforms (Codeforces, LeetCode, etc.)
/// and custom user-created categories.
///
/// Future API integration types are tracked but not yet implemented.
class Category {
  final String id;
  final String name;
  final String icon;
  final CategoryType type;
  final String? website;
  final IntegrationType integrationType;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.website,
    required this.integrationType,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type.toString().split('.').last,
      'website': website,
      'integrationType': integrationType.toString().split('.').last,
    };
  }

  // Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? generateId(json['name'] as String),
      name: json['name'] as String,
      icon: json['icon'] as String,
      type: _parseType(json['type'] as String?),
      website: json['website'] as String?,
      integrationType: _parseIntegrationType(json['integrationType'] as String?),
    );
  }

  // Legacy format support (old categories without full model)
  factory Category.fromLegacy(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return Category(
      id: generateId(name),
      name: name,
      icon: json['icon'] as String,
      type: CategoryType.custom,
      integrationType: IntegrationType.none,
    );
  }

  static String generateId(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }

  static CategoryType _parseType(String? typeStr) {
    if (typeStr == null) return CategoryType.custom;
    try {
      return CategoryType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => CategoryType.custom,
      );
    } catch (_) {
      return CategoryType.custom;
    }
  }

  static IntegrationType _parseIntegrationType(String? typeStr) {
    if (typeStr == null) return IntegrationType.none;
    try {
      return IntegrationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => IntegrationType.none,
      );
    } catch (_) {
      return IntegrationType.none;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum CategoryType {
  predefined,
  custom,
}

enum IntegrationType {
  none,
  codeforces_api,
  leetcode_api,
  atcoder_api,
  codechef_api,
}

/// Predefined popular competitive programming platforms
class PredefinedPlatforms {
  static final List<Category> platforms = [
    Category(
      id: 'codeforces',
      name: 'Codeforces',
      icon: 'code',
      type: CategoryType.predefined,
      website: 'https://codeforces.com',
      integrationType: IntegrationType.codeforces_api,
    ),
    Category(
      id: 'leetcode',
      name: 'LeetCode',
      icon: 'bolt',
      type: CategoryType.predefined,
      website: 'https://leetcode.com',
      integrationType: IntegrationType.leetcode_api,
    ),
    Category(
      id: 'atcoder',
      name: 'AtCoder',
      icon: 'radio_button_checked',
      type: CategoryType.predefined,
      website: 'https://atcoder.jp',
      integrationType: IntegrationType.atcoder_api,
    ),
    Category(
      id: 'codechef',
      name: 'CodeChef',
      icon: 'restaurant',
      type: CategoryType.predefined,
      website: 'https://www.codechef.com',
      integrationType: IntegrationType.codechef_api,
    ),
    Category(
      id: 'hackerrank',
      name: 'HackerRank',
      icon: 'military_tech',
      type: CategoryType.predefined,
      website: 'https://www.hackerrank.com',
      integrationType: IntegrationType.none,
    ),
    Category(
      id: 'cses',
      name: 'CSES',
      icon: 'hub',
      type: CategoryType.predefined,
      website: 'https://cses.fi',
      integrationType: IntegrationType.none,
    ),
    Category(
      id: 'hackerearth',
      name: 'HackerEarth',
      icon: 'public',
      type: CategoryType.predefined,
      website: 'https://www.hackerearth.com',
      integrationType: IntegrationType.none,
    ),
    Category(
      id: 'geeksforgeeks',
      name: 'GeeksforGeeks',
      icon: 'school',
      type: CategoryType.predefined,
      website: 'https://www.geeksforgeeks.org',
      integrationType: IntegrationType.none,
    ),
  ];

  static Category? findByName(String name) {
    try {
      return platforms.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Category? findById(String id) {
    try {
      return platforms.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
