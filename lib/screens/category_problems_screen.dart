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

  List<Problem> _problems = [];
  List<Problem> _filteredProblems = [];
  bool _isLoading = true;
  int _problemCount = 0;

  // Sort options
  String _sortBy = 'Date: Latest First'; // Default sort
  final List<String> _sortOptions = [
    'Date: Latest First',
    'Date: Oldest First',
    'Rating: Low to High',
    'Rating: High to Low',
  ];

  // Filter options
  DateTimeRange? _dateRange;
  String? _ratingMin;
  String? _ratingMax;

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
        _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    List<Problem> filtered = List.from(_problems);

    // Apply date filter
    if (_dateRange != null) {
      filtered = filtered.where((problem) {
        if (problem.createdAt == null) return false;
        try {
          final problemDate = DateTime.parse(problem.createdAt!);
          final startDate = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
          final endDate = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
          return problemDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
                 problemDate.isBefore(endDate.add(const Duration(seconds: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply rating filter
    if (_ratingMin != null || _ratingMax != null) {
      filtered = filtered.where((problem) {
        if (problem.rating.isEmpty) return false;
        try {
          final rating = int.tryParse(problem.rating);
          if (rating == null) return false;
          
          if (_ratingMin != null && _ratingMax != null) {
            final min = int.tryParse(_ratingMin!);
            final max = int.tryParse(_ratingMax!);
            if (min != null && max != null) {
              return rating >= min && rating <= max;
            }
          } else if (_ratingMin != null) {
            final min = int.tryParse(_ratingMin!);
            if (min != null) return rating >= min;
          } else if (_ratingMax != null) {
            final max = int.tryParse(_ratingMax!);
            if (max != null) return rating <= max;
          }
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply sorting
    if (_sortBy == 'Date: Latest First') {
      filtered.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!));
      });
    } else if (_sortBy == 'Date: Oldest First') {
      filtered.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return DateTime.parse(a.createdAt!).compareTo(DateTime.parse(b.createdAt!));
      });
    } else if (_sortBy == 'Rating: Low to High') {
      filtered.sort((a, b) {
        final aRating = int.tryParse(a.rating) ?? 0;
        final bRating = int.tryParse(b.rating) ?? 0;
        return aRating.compareTo(bRating);
      });
    } else if (_sortBy == 'Rating: High to Low') {
      filtered.sort((a, b) {
        final aRating = int.tryParse(a.rating) ?? 0;
        final bRating = int.tryParse(b.rating) ?? 0;
        return bRating.compareTo(aRating);
      });
    }

    setState(() {
      _filteredProblems = filtered;
    });
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
                  _buildSortAndFilterBar(),
                  const SizedBox(height: 40),
                  _isLoading
                      ? _buildLoadingState()
                      : _filteredProblems.isEmpty
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

  // 4. Sort and Filter bar
  Widget _buildSortAndFilterBar() {
    return Row(
      children: [
        // Sort button
        Expanded(
          child: _buildSortButton(),
        ),
        const SizedBox(width: 12),
        // Filter button
        Expanded(
          child: _buildFilterButton(),
        ),
      ],
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.sort, color: Colors.white.withOpacity(0.7), size: 18),
                const SizedBox(width: 8),
                Text(
                  _sortBy,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final bool hasFilters = _dateRange != null || _ratingMin != null || _ratingMax != null;
    
    return GestureDetector(
      onTap: _showFilterOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFilters ? Colors.white.withOpacity(0.12) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFilters ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: hasFilters ? Colors.white : Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasFilters ? 'Filtered' : 'Filter',
                  style: TextStyle(
                    color: hasFilters ? Colors.white : Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: hasFilters ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (hasFilters)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _dateRange = null;
                    _ratingMin = null;
                    _ratingMax = null;
                  });
                  _applyFiltersAndSort();
                },
                child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 18),
              )
            else
              Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              ..._sortOptions.map((option) => ListTile(
                leading: Radio<String>(
                  value: option,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    _applyFiltersAndSort();
                    Navigator.pop(context);
                  },
                  activeColor: Colors.white,
                ),
                title: Text(
                  option,
                  style: TextStyle(
                    color: _sortBy == option ? Colors.white : Colors.white70,
                    fontWeight: _sortBy == option ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  setState(() => _sortBy = option);
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    final dateMinController = TextEditingController();
    final dateMaxController = TextEditingController();
    final ratingMinController = TextEditingController(text: _ratingMin ?? '');
    final ratingMaxController = TextEditingController(text: _ratingMax ?? '');

    DateTimeRange? tempDateRange = _dateRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Problems',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _dateRange = tempDateRange;
                            _ratingMin = ratingMinController.text.isEmpty ? null : ratingMinController.text;
                            _ratingMax = ratingMaxController.text.isEmpty ? null : ratingMaxController.text;
                          });
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  
                  // Date Range Filter
                  Text(
                    'Date Range',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: tempDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark(),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempDateRange = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempDateRange == null
                                ? 'Select date range'
                                : '${_formatDateShort(tempDateRange!.start)} - ${_formatDateShort(tempDateRange!.end)}',
                            style: TextStyle(
                              color: tempDateRange == null 
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tempDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            tempDateRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                        label: const Text(
                          'Clear date range',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Rating Range Filter
                  Text(
                    'Rating Range',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ratingMinController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'to',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: ratingMaxController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      children: _filteredProblems.map((problem) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem.problemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (problem.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Colors.green.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Solved ${_formatDateVerbose(problem.createdAt!)}',
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

  String _formatDateVerbose(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final problemDate = DateTime(date.year, date.month, date.day);
      final difference = today.difference(problemDate).inDays;

      // Format time
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeStr = '$hour12:$minute $period';

      if (difference == 0) {
        return 'today at $timeStr';
      } else if (difference == 1) {
        return 'yesterday at $timeStr';
      } else if (difference < 7) {
        return '${difference} days ago';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference < 365) {
        final months = (difference / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        return 'on ${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}