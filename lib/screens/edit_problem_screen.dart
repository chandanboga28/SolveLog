import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/problem.dart';
import '../database/database_helper.dart';

/// Screen for editing an existing problem.
///
/// Allows users to update all problem fields and add/remove approaches.
/// Pre-fills the form with existing data.
class EditProblemScreen extends StatefulWidget {
  final Problem problem;
  final List<Approach> approaches;
  final String categoryIcon;
  final String categoryName;

  const EditProblemScreen({
    Key? key,
    required this.problem,
    required this.approaches,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<EditProblemScreen> createState() => _EditProblemScreenState();
}

class _EditProblemScreenState extends State<EditProblemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _ratingController;
  late final TextEditingController _linkController;
  late final TextEditingController _codeController;
  late final TextEditingController _understandingController;
  late final TextEditingController _problemsFacedController;
  late final TextEditingController _learntController;

  // Each approach has two controllers: one for text, one for code
  final List<Map<String, TextEditingController>> _approachControllers = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.problem.problemName);
    _idController = TextEditingController(text: widget.problem.problemId);
    _ratingController = TextEditingController(text: widget.problem.rating);
    _linkController = TextEditingController(text: widget.problem.problemLink);
    _codeController = TextEditingController(text: widget.problem.code);
    _understandingController = TextEditingController(
      text: widget.problem.questionUnderstanding,
    );
    _problemsFacedController = TextEditingController(
      text: widget.problem.problemsFaced,
    );
    _learntController = TextEditingController(
      text: widget.problem.anyNewThingLearnt,
    );

    // Initialize approach controllers with existing approaches
    if (widget.approaches.isEmpty) {
      _approachControllers.add({
        'text': TextEditingController(),
        'code': TextEditingController(),
      });
    } else {
      for (final approach in widget.approaches) {
        _approachControllers.add({
          'text': TextEditingController(text: approach.approachText),
          'code': TextEditingController(text: approach.approachCode),
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _ratingController.dispose();
    _linkController.dispose();
    _codeController.dispose();
    _understandingController.dispose();
    _problemsFacedController.dispose();
    _learntController.dispose();
    for (final controllers in _approachControllers) {
      controllers['text']!.dispose();
      controllers['code']!.dispose();
    }
    super.dispose();
  }

  void _addApproach() {
    setState(() {
      _approachControllers.add({
        'text': TextEditingController(),
        'code': TextEditingController(),
      });
    });
  }

  void _removeApproach(int index) {
    setState(() {
      final removed = _approachControllers.removeAt(index);
      removed['text']!.dispose();
      removed['code']!.dispose();
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final db = DatabaseHelper.instance;

      // Gather approaches (text + code)
      final approaches = _approachControllers
          .map((controllers) => {
                'text': controllers['text']!.text.trim(),
                'code': controllers['code']!.text.trim(),
              })
          .where((approach) =>
              approach['text']!.isNotEmpty || approach['code']!.isNotEmpty)
          .toList();

      // Update in transaction
      await (await db.database).transaction((txn) async {
        // Update problem
        await txn.update(
          'problems',
          {
            'problemName': _nameController.text.trim(),
            'problemId': _idController.text.trim(),
            'rating': _ratingController.text.trim(),
            'problemLink': _linkController.text.trim(),
            'code': _codeController.text.trim(),
            'questionUnderstanding': _understandingController.text.trim(),
            'problemsFaced': _problemsFacedController.text.trim(),
            'anyNewThingLearnt': _learntController.text.trim(),
          },
          where: 'id = ?',
          whereArgs: [widget.problem.id],
        );

        // Delete old approaches
        await txn.delete(
          'approaches',
          where: 'problemId = ?',
          whereArgs: [widget.problem.id],
        );

        // Insert new approaches
        for (final approach in approaches) {
          await txn.insert('approaches', {
            'problemId': widget.problem.id,
            'approachText': approach['text'],
            'approachCode': approach['code'],
          });
        }
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Problem updated successfully!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pop(true); // Return true to trigger reload
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update problem: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  TextStyle get _fieldTextStyle =>
      const TextStyle(color: Colors.white, fontSize: 14);

  TextStyle get _codeTextStyle => const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'monospace',
        height: 1.5,
      );

  InputDecoration _inputDecoration({String? hint}) {
    final radius = BorderRadius.circular(10);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
      ),
      errorStyle: TextStyle(
        color: Colors.redAccent.withOpacity(0.9),
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 32),

                    _sectionHeading('Problem Information'),
                    const SizedBox(height: 16),
                    _buildLabeledField(
                      label: 'Problem Name',
                      child: TextFormField(
                        controller: _nameController,
                        style: _fieldTextStyle,
                        decoration:
                            _inputDecoration(hint: 'e.g. Watermelon'),
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildLabeledField(
                            label: 'Problem ID',
                            child: TextFormField(
                              controller: _idController,
                              style: _fieldTextStyle,
                              decoration:
                                  _inputDecoration(hint: 'e.g. 4A, 71A'),
                              validator: _requiredValidator,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLabeledField(
                            label: 'Rating',
                            child: TextFormField(
                              controller: _ratingController,
                              style: _fieldTextStyle,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: _inputDecoration(
                                  hint: 'e.g. 800, 1200'),
                              validator: _requiredValidator,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabeledField(
                      label: 'Problem Link',
                      child: TextFormField(
                        controller: _linkController,
                        style: _fieldTextStyle,
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          hint:
                              'https://codeforces.com/problemset/problem/...',
                        ),
                        validator: _requiredValidator,
                      ),
                    ),

                    const SizedBox(height: 36),
                    _sectionHeading('Solution'),
                    const SizedBox(height: 16),
                    _buildLabeledField(
                      label: 'Code',
                      child: TextFormField(
                        controller: _codeController,
                        style: _codeTextStyle,
                        decoration:
                            _inputDecoration(hint: 'Paste your solution...'),
                        minLines: 12,
                        maxLines: 24,
                        validator: _requiredValidator,
                      ),
                    ),

                    const SizedBox(height: 36),
                    _sectionHeading('Thinking & Learning'),
                    const SizedBox(height: 16),
                    _buildLabeledField(
                      label: 'Question Understanding',
                      child: TextField(
                        controller: _understandingController,
                        style: _fieldTextStyle,
                        decoration: _inputDecoration(
                          hint: 'Explain the problem in your own words...',
                        ),
                        minLines: 4,
                        maxLines: 10,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildApproachesSection(),
                    const SizedBox(height: 24),
                    _buildLabeledField(
                      label: 'Problems Faced',
                      child: TextField(
                        controller: _problemsFacedController,
                        style: _fieldTextStyle,
                        decoration: _inputDecoration(
                          hint: 'Errors, wrong ideas, failed attempts...',
                        ),
                        minLines: 4,
                        maxLines: 10,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabeledField(
                      label: 'Any New Thing Learnt',
                      child: TextField(
                        controller: _learntController,
                        style: _fieldTextStyle,
                        decoration: _inputDecoration(
                          hint:
                              'Concepts, tricks, patterns you picked up...',
                        ),
                        minLines: 4,
                        maxLines: 10,
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
          onPressed: _isSubmitting ? null : _handleCancel,
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        const Text(
          'Edit Problem',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.categoryIcon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                widget.categoryName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title) {
    return Row(
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
          child: Divider(color: Colors.white.withOpacity(0.08), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildApproachesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approaches',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _approachControllers.length; i++) ...[
          _buildApproachCard(i),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addApproach,
            icon: const Icon(Icons.add, size: 18, color: Colors.white70),
            label: const Text(
              'Add Another Approach',
              style: TextStyle(color: Colors.white70),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApproachCard(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Approach ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_approachControllers.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onPressed: () => _removeApproach(index),
                  tooltip: 'Remove approach',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Description',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _approachControllers[index]['text']!,
            style: _fieldTextStyle,
            decoration: _inputDecoration(hint: 'Describe this approach...'),
            minLines: 3,
            maxLines: 8,
          ),
          // Only show code field for approaches after the first one
          if (index > 0) ...[
            const SizedBox(height: 16),
            Text(
              'Code',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _approachControllers[index]['code']!,
              style: _codeTextStyle,
              decoration: _inputDecoration(hint: 'Code for this approach...'),
              minLines: 6,
              maxLines: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _handleCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Text(
                    'Update Problem',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
