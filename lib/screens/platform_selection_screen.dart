import 'package:flutter/material.dart';
import '../widgets/platform_card.dart';
import 'category_problems_screen.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlatformSelectionScreen extends StatefulWidget {
  const PlatformSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PlatformSelectionScreen> createState() =>
      _PlatformSelectionScreenState();
}

class _PlatformSelectionScreenState extends State<PlatformSelectionScreen> {
  List<Map<String, String>> _defaultCategories = [];
  List<Map<String, String>> _customCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load default categories (or use hardcoded if not found)
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
          // Save updated list
          await prefs.setString('default_categories', json.encode(_defaultCategories));
        }
      } else {
        // Initialize with hardcoded defaults
        _defaultCategories = [
          {'icon': '💻', 'name': 'Codeforces'},
          {'icon': '⚡', 'name': 'LeetCode'},
          {'icon': '🔷', 'name': 'AtCoder'},
          {'icon': '📝', 'name': 'Miscellaneous'},
        ];
        // Save them to SharedPreferences
        await prefs.setString('default_categories', json.encode(_defaultCategories));
      }
      
      // Load custom categories
      final categoriesJson = prefs.getString('custom_categories') ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);

      if (mounted) {
        setState(() {
          _customCategories = categories
              .map((cat) => {
                    'icon': cat['icon'].toString(),
                    'name': cat['name'].toString(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _openCategory(String icon, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryProblemsScreen(
          categoryIcon: icon,
          categoryName: name,
        ),
      ),
    );
  }

  void _openAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    );

    // Reload categories if a new one was added
    if (result == true) {
      _loadCategories();
    }
  }

  void _showCategoryOptions(String icon, String name, int index, bool isDefault) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              // Edit option
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text(
                  'Edit Category',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editCategory(icon, name, index, isDefault);
                },
              ),
              // Delete option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Delete Category',
                  style: TextStyle(color: Colors.redAccent),
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

    // Reload categories if updated
    if (result == true) {
      _loadCategories();
    }
  }

  void _confirmDeleteCategory(String icon, String name, int index, bool isDefault) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Category?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This will delete the category. All problems under this category will remain in the database.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(index, name, isDefault);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
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
        // Delete from default categories
        final categoriesJson = prefs.getString('default_categories') ?? '[]';
        final List<dynamic> categories = json.decode(categoriesJson);
        
        categories.removeAt(index);
        await prefs.setString('default_categories', json.encode(categories));
      } else {
        // Delete from custom categories
        final categoriesJson = prefs.getString('custom_categories') ?? '[]';
        final List<dynamic> categories = json.decode(categoriesJson);
        
        categories.removeAt(index);
        await prefs.setString('custom_categories', json.encode(categories));
      }
      
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name deleted successfully'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Reload categories
      _loadCategories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'SolveLog',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Coding Knowledge Base',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 56),

                // Choose a platform label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a platform',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 24),

                // Platform cards grid - 3 per row
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Default categories (now editable via long press)
                    ..._defaultCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      return PlatformCard(
                        icon: category['icon']!,
                        name: category['name']!,
                        onTap: () => _openCategory(
                          category['icon']!,
                          category['name']!,
                        ),
                        onLongPress: () => _showCategoryOptions(
                          category['icon']!,
                          category['name']!,
                          index,
                          true, // isDefault = true
                        ),
                      );
                    }),
                    // Custom categories
                    ..._customCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      return PlatformCard(
                        icon: category['icon']!,
                        name: category['name']!,
                        onTap: () => _openCategory(
                          category['icon']!,
                          category['name']!,
                        ),
                        onLongPress: () => _showCategoryOptions(
                          category['icon']!,
                          category['name']!,
                          index,
                          false, // isDefault = false
                        ),
                      );
                    }),
                    // Add category button
                    PlatformCard(
                      icon: '➕',
                      name: 'Add Category',
                      onTap: _openAddCategory,
                      isAddButton: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
