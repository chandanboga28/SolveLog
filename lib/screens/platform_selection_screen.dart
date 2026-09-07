import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import 'category_problems_screen.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class PlatformSelectionScreen extends StatefulWidget {
  const PlatformSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PlatformSelectionScreen> createState() =>
      _PlatformSelectionScreenState();
}

class _PlatformSelectionScreenState extends State<PlatformSelectionScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, String>> _defaultCategories = [];
  List<Map<String, String>> _customCategories = [];
  Map<String, int> _problemCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load default categories
      final defaultCategoriesJson = prefs.getString('default_categories');
      if (defaultCategoriesJson != null) {
        final List<dynamic> defaults = json.decode(defaultCategoriesJson);
        _defaultCategories = defaults
            .map((cat) => {
                  'icon': cat['icon'].toString(),
                  'name': cat['name'].toString(),
                })
            .toList();
        
        // Migration: Add Miscellaneous if it doesn't exist
        final hasMiscellaneous = _defaultCategories.any(
          (cat) => cat['name'] == 'Miscellaneous'
        );
        if (!hasMiscellaneous) {
          _defaultCategories.add({
            'icon': '📝',
            'name': 'Miscellaneous',
          });
          await prefs.setString('default_categories', json.encode(_defaultCategories));
        }
      } else {
        // Initialize with hardcoded defaults
        _defaultCategories = [
          {'icon': '💻', 'name': 'Codeforces'},
          {'icon': '⚡', 'name': 'LeetCode'},
          {'icon': '📝', 'name': 'Miscellaneous'},
        ];
        await prefs.setString('default_categories', json.encode(_defaultCategories));
      }
      
      // Load custom categories
      final categoriesJson = prefs.getString('custom_categories') ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);

      _customCategories = categories
          .map((cat) => {
                'icon': cat['icon'].toString(),
                'name': cat['name'].toString(),
              })
          .toList();
      
      // Load problem counts for all categories
      await _loadProblemCounts();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProblemCounts() async {
    final allCategories = [..._defaultCategories, ..._customCategories];
    
    for (final category in allCategories) {
      final count = await DatabaseHelper.instance
          .getProblemCountByCategory(category['name']!);
      _problemCounts[category['name']!] = count;
    }
  }

  void _openCategory(String icon, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryProblemsScreen(
          categoryIcon: icon,
          categoryName: name,
        ),
      ),
    ).then((_) => _loadCategories()); // Reload when coming back
  }

  void _openAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  void _showCategoryOptions(String icon, String name, int index, bool isDefault) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(name),
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                title: const Text(
                  'Edit Category',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editCategory(icon, name, index, isDefault);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                title: const Text(
                  'Delete Category',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCategory(icon, name, index, isDefault);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCategory(String icon, String name, int index, bool isDefault) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          originalIcon: icon,
          originalName: name,
          categoryIndex: index,
          isDefault: isDefault,
        ),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  void _confirmDeleteCategory(String icon, String name, int index, bool isDefault) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Category?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will delete the category. All problems under this category will remain in the database.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(index, name, isDefault);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int index, String name, bool isDefault) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (isDefault) {
        final categoriesJson = prefs.getString('default_categories') ?? '[]';
        final List<dynamic> categories = json.decode(categoriesJson);
        categories.removeAt(index);
        await prefs.setString('default_categories', json.encode(categories));
      } else {
        final categoriesJson = prefs.getString('custom_categories') ?? '[]';
        final List<dynamic> categories = json.decode(categoriesJson);
        categories.removeAt(index);
        await prefs.setString('custom_categories', json.encode(categories));
      }
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name deleted successfully'),
          backgroundColor: AppTheme.success,
        ),
      );

      _loadCategories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'codeforces':
        return Icons.code;
      case 'leetcode':
        return Icons.bolt;
      case 'atcoder':
        return Icons.radio_button_checked;
      case 'miscellaneous':
        return Icons.description_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _authService.signOut();
        // Navigation handled by AuthGate in main.dart
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.subtleGlow,
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/solvelog_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // SolveLog Title with colored text
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(
                          text: 'Solve',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        TextSpan(
                          text: 'Log',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Subtitle
                  const Text(
                    'Your Coding Knowledge Base',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 72),
                  
                  // "Choose a platform" heading
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose a platform',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Helper text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select where you solved the problem.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Category cards - single row layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate if we should use horizontal or grid layout
                      final useHorizontalLayout = constraints.maxWidth > 900;
                      
                      final allCategories = [
                        ..._defaultCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final problemCount = _problemCounts[category['name']!] ?? 0;
                          return _CategoryCard(
                            icon: _getCategoryIcon(category['name']!),
                            name: category['name']!,
                            problemCount: problemCount,
                            onTap: () => _openCategory(
                              category['icon']!,
                              category['name']!,
                            ),
                            onLongPress: () => _showCategoryOptions(
                              category['icon']!,
                              category['name']!,
                              index,
                              true,
                            ),
                            isHighlighted: category['name'] == 'Codeforces',
                          );
                        }),
                        ..._customCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final problemCount = _problemCounts[category['name']!] ?? 0;
                          return _CategoryCard(
                            icon: _getCategoryIcon(category['name']!),
                            name: category['name']!,
                            problemCount: problemCount,
                            onTap: () => _openCategory(
                              category['icon']!,
                              category['name']!,
                            ),
                            onLongPress: () => _showCategoryOptions(
                              category['icon']!,
                              category['name']!,
                              index,
                              false,
                            ),
                          );
                        }),
                      ];
                      
                      if (useHorizontalLayout) {
                        // Horizontal single row layout
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ...allCategories.map((card) => Expanded(child: card)),
                            Expanded(child: _AddCategoryCard(onTap: _openAddCategory)),
                          ],
                        );
                      } else {
                        // Grid layout for narrow windows
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            ...allCategories,
                            _AddCategoryCard(onTap: _openAddCategory),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 80),
                  
                  // Footer text
                  const Text(
                    'BUILD  /  SOLVE  /  GROW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textTertiary,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ), // Close Column
            ), // Close inner Container
          ), // Close SingleChildScrollView
        ), // Close Center
      ), // Close outer Container
      // Logout button in top-right corner
      Positioned(
        top: 24,
        right: 24,
        child: _LogoutButton(onLogout: _handleLogout),
      ),
    ], // Close Stack children
    ), // Close Scaffold body: Stack
  ); // Close Scaffold
  }
}

class _CategoryCard extends StatefulWidget {
  final IconData icon;
  final String name;
  final int problemCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isHighlighted;

  const _CategoryCard({
    required this.icon,
    required this.name,
    required this.problemCount,
    required this.onTap,
    this.onLongPress,
    this.isHighlighted = false,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: _isHovered || widget.isHighlighted
                  ? AppTheme.primary.withOpacity(0.6)
                  : AppTheme.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Count and arrow row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${widget.problemCount} ${widget.problemCount == 1 ? 'problem' : 'problems'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
                    child: Icon(
                      Icons.arrow_forward,
                      color: _isHovered ? AppTheme.primary : AppTheme.textTertiary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatefulWidget {
  final VoidCallback onTap;

  const _AddCategoryCard({required this.onTap});

  @override
  State<_AddCategoryCard> createState() => _AddCategoryCardState();
}

class _AddCategoryCardState extends State<_AddCategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: _isHovered ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
              width: 1,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plus icon in circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isHovered ? AppTheme.primary : AppTheme.textTertiary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add,
                  color: _isHovered ? AppTheme.primary : AppTheme.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Text
              Text(
                'Add Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? AppTheme.primary : AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new category',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logout button widget for platform selection screen
class _LogoutButton extends StatefulWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userEmail = authService.userEmail;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.surface
              : AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppTheme.border
                : AppTheme.border.withOpacity(0.5),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLogout,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (userEmail != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail.length > 25
                              ? '${userEmail.substring(0, 25)}...'
                              : userEmail,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.logout,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
