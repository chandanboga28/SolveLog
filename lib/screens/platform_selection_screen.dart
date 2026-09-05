import 'package:flutter/material.dart';
import '../widgets/platform_card.dart';
import 'category_problems_screen.dart';

class PlatformSelectionScreen extends StatefulWidget {
  const PlatformSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PlatformSelectionScreen> createState() =>
      _PlatformSelectionScreenState();
}

class _PlatformSelectionScreenState extends State<PlatformSelectionScreen> {
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

                // Platform cards grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
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
                    PlatformCard(
                      icon: '➕',
                      name: 'Add Category',
                      onTap: () =>
                          _showNotification('Add Category — coming soon'),
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