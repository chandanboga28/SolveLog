import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Add Problem screen — a form for logging a new problem under the
/// current category (Codeforces, LeetCode, AtCoder, etc.).
///
/// There is no database yet, so "Save Problem" only validates the form,
/// captures an in-memory timestamp, shows a temporary success message,
/// and returns to the Category Problems screen. Nothing is persisted.
class AddProblemScreen extends StatefulWidget {
  final String categoryIcon;
  final String categoryName;

  const AddProblemScreen({
    Key? key,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<AddProblemScreen> createState() => _AddProblemScreenState();
}

class _AddProblemScreenState extends State<AddProblemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _understandingController =
      TextEditingController();
  final TextEditingController _problemsFacedController =
      TextEditingController();
  final TextEditingController _learntController = TextEditingController();

  // One controller per approach. Starts with a single "Approach 1" section;
  // more can be added/removed locally. No separate model class yet — this
  // is intentionally simple until storage is introduced.
  final List<TextEditingController> _approachControllers = [
    TextEditingController(),
  ];

  bool _isSubmitting = false;

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
    for (final controller in _approachControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addApproach() {
    setState(() {
      _approachControllers.add(TextEditingController());
    });
  }

  void _removeApproach(int index) {
    setState(() {
      final removed = _approachControllers.removeAt(index);
      removed.dispose();
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Automatically capture the moment of creation in memory. This will be
    // written to the database once storage is implemented — for now it's
    // just captured so the wiring is ready.
    final DateTime createdAt = DateTime.now();
    debugPrint(
      'Problem "${_nameController.text}" prepared at $createdAt '
      '(category: ${widget.categoryName}) — not persisted yet.',
    );

    setState(() => _isSubmitting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Problem added successfully (storage coming next).'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Brief pause so the success message is visible before navigating back.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pop();
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

  // Top bar: back button, "Add Problem" title, category badge
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
          'Add Problem',
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
          TextField(
            controller: _approachControllers[index],
            style: _fieldTextStyle,
            decoration: _inputDecoration(hint: 'Describe this approach...'),
            minLines: 3,
            maxLines: 8,
          ),
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
            onPressed: _isSubmitting ? null : _handleSave,
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
                    'Save Problem',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}