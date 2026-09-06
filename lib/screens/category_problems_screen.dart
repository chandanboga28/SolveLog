import 'package:flutter/material.dart';
import 'add_problem_screen.dart';
import 'problem_detail_screen.dart';
import '../models/problem.dart';
import '../database/database_helper.dart';

/// Screen shown after selecting a category (Codeforces, LeetCode, AtCoder,
/// or any custom category) from the platform selection screen.
///
/// Loads and displays problems from the local SQLite database for the
/// selected category. Categories are kept completely separate.
class CategoryProblemsScreen extends StatefulWidget {
  final String categoryIcon;
  final String categoryName;

  const CategoryProblemsScreen({
    Key? key,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryProblemsScreen> createState() =>
      _CategoryProblemsScreenState();
}

class _CategoryProblemsScreenState extends State<CategoryProblemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filters = ['All', 'Solved', 'Hint', 'Editorial'];
  String _selectedFilter = 'All';

  List<Problem> _problems = [];
  bool _isLoading = true;
  int _problemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProblems() async {
    setState(() => _isLoading = true);

    try {
      final problems = await DatabaseHelper.instance
          .getProblemsByCategory(widget.categoryName);
      final count = await DatabaseHelper.instance
          .getProblemCountByCategory(widget.categoryName);

      if (mounted) {
        setState(() {
          _problems = problems;
          _problemCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load problems: ${e.toString()}'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  void _openAddProblem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProblemScreen(
          categoryIcon: widget.categoryIcon,
          categoryName: widget.categoryName,
        ),
      ),
    );

    // If a problem was added, reload the list
    if (result == true) {
      _loadProblems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 32),
                  _buildStatistics(),
                  const SizedBox(height: 28),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildFilterTabs(),
                  const SizedBox(height: 40),
                  _isLoading
                      ? _buildLoadingState()
                      : _problems.isEmpty
                          ? _buildEmptyState()
                          : _buildProblemsList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top bar: back button, category name, + Add Problem
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Text(
          widget.categoryIcon,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.categoryName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _openAddProblem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Problem'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Statistics: Total Problems, Current Streak (static for now)
  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Problems',
            value: '$_problemCount ${_problemCount == 1 ? 'Problem' : 'Problems'}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Current Streak',
            value: '🔥 0 Day Streak',
          ),
        ),
      ],
    );
  }

  // 3. Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search problems...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          prefixIcon: Icon(Icons.search,
              color: Colors.white.withOpacity(0.35), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // 4. Filter tabs
  Widget _buildFilterTabs() {
    return Row(
      children: _filters.map((filter) {
        final bool isSelected = filter == _selectedFilter;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.12)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Empty state
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 44,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No problems yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging the problems you solve.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _openAddProblem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Your First Problem'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Loading state
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // 7. Problems list
  Widget _buildProblemsList() {
    return Column(
      children: _problems.map((problem) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProblemCard(
            problem: problem,
            categoryIcon: widget.categoryIcon,
            categoryName: widget.categoryName,
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final Problem problem;
  final String categoryIcon;
  final String categoryName;

  const _ProblemCard({
    Key? key,
    required this.problem,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProblemDetailScreen(
              problemId: problem.id!,
              categoryIcon: categoryIcon,
              categoryName: categoryName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    problem.problemName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (problem.rating.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      problem.rating,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'ID: ${problem.problemId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                if (problem.createdAt != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(problem.createdAt!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            if (problem.questionUnderstanding.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                problem.questionUnderstanding,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}