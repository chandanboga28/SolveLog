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
  List<Map<String, String>> _customCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      _loadCustomCategories();
    }
  }

  void _showCategoryOptions(String icon, String name, int index) {
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
                  _editCategory(icon, name, index);
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
                  _confirmDeleteCategory(icon, name, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCategory(String icon, String name, int index) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          originalIcon: icon,
          originalName: name,
          categoryIndex: index,
        ),
      ),
    );

    // Reload categories if updated
    if (result == true) {
      _loadCustomCategories();
    }
  }

  void _confirmDeleteCategory(String icon, String name, int index) {
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
              _deleteCategory(index, name);
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

  Future<void> _deleteCategory(int index, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing custom categories
      final categoriesJson = prefs.getString('custom_categories') ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);
      
      // Remove category at index
      categories.removeAt(index);
      
      // Save back to SharedPreferences
      await prefs.setString('custom_categories', json.encode(categories));
      
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
      _loadCustomCategories();
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
                    // Default categories
                    PlatformCard(
                      icon: '💻',
                      name: 'Codeforces',
                      onTap: () => _openCategory('💻', 'Codeforces'),
                    ),
                    PlatformCard(
                      icon: '⚡',
                      name: 'LeetCode',
                      onTap: () => _openCategory('⚡', 'LeetCode'),
                    ),
                    PlatformCard(
                      icon: '🔷',
                      name: 'AtCoder',
                      onTap: () => _openCategory('🔷', 'AtCoder'),
                    ),
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