import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/problem.dart';
import '../database/database_helper.dart';
import 'edit_problem_screen.dart';

/// Screen that displays the full details of a saved problem.
///
/// Shows all problem information including code, approaches, understanding,
/// problems faced, and learnings. Allows users to view their complete notes
/// for a specific problem.
class ProblemDetailScreen extends StatefulWidget {
  final int problemId;
  final String categoryIcon;
  final String categoryName;

  const ProblemDetailScreen({
    Key? key,
    required this.problemId,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  Problem? _problem;
  List<Approach> _approaches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProblemDetails();
  }

  Future<void> _loadProblemDetails() async {
    setState(() => _isLoading = true);

    try {
      final result =
          await DatabaseHelper.instance.getProblemWithApproaches(widget.problemId);

      if (result != null && mounted) {
        setState(() {
          _problem = result['problem'] as Problem;
          _approaches = result['approaches'] as List<Approach>;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load problem: ${e.toString()}'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  void _openEditScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProblemScreen(
          problem: _problem!,
          approaches: _approaches,
          categoryIcon: widget.categoryIcon,
          categoryName: widget.categoryName,
        ),
      ),
    );

    // Reload if problem was updated
    if (result == true) {
      _loadProblemDetails();
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _problem == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Problem not found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 32),
              _buildProblemInfo(),
              const SizedBox(height: 32),
              _buildCodeSection(),
              if (_problem!.questionUnderstanding.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSection(
                  'Question Understanding',
                  _problem!.questionUnderstanding,
                ),
              ],
              if (_approaches.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildApproachesSection(),
              ],
              if (_problem!.problemsFaced.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSection(
                  'Problems Faced',
                  _problem!.problemsFaced,
                ),
              ],
              if (_problem!.anyNewThingLearnt.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSection(
                  'What I Learned',
                  _problem!.anyNewThingLearnt,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _problem!.problemName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(widget.categoryIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _openEditScreen,
          tooltip: 'Edit Problem',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildProblemInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Problem ID', _problem!.problemId),
          if (_problem!.rating.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Rating', _problem!.rating),
          ],
          if (_problem!.problemLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Link', _problem!.problemLink, isLink: true),
          ],
          if (_problem!.createdAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Added', _formatDate(_problem!.createdAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: isLink
              ? GestureDetector(
                  onTap: () => _copyToClipboard(value, 'Link'),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.blue.withOpacity(0.8),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CODE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.08),
                thickness: 1,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy,
                size: 18,
                color: Colors.white.withOpacity(0.6),
              ),
              onPressed: () => _copyToClipboard(_problem!.code, 'Code'),
              tooltip: 'Copy code',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SelectableText(
            _problem!.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'JetBrainsMono',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.08),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApproachesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'APPROACHES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.08),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _approaches.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Approach ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_approaches[i].approachCode.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        onPressed: () => _copyToClipboard(
                          _approaches[i].approachCode,
                          'Approach ${i + 1} code',
                        ),
                        tooltip: 'Copy code',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (_approaches[i].approachText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    _approaches[i].approachText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
                if (_approaches[i].approachCode.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: SelectableText(
                      _approaches[i].approachCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'JetBrainsMono',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (i < _approaches.length - 1) const SizedBox(height: 12),
        ],
      ],
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
      return isoDate;
    }
  }
}
