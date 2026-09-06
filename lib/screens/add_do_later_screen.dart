import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddDoLaterScreen extends StatefulWidget {
  final String categoryIcon;
  final String categoryName;

  const AddDoLaterScreen({
    Key? key,
    required this.categoryIcon,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<AddDoLaterScreen> createState() => _AddDoLaterScreenState();
}

class _AddDoLaterScreenState extends State<AddDoLaterScreen> {
  final TextEditingController _problemIdController = TextEditingController();
  final TextEditingController _problemLinkController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _problemIdController.dispose();
    _problemLinkController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveDoLater() async {
    final problemId = _problemIdController.text.trim();
    final problemLink = _problemLinkController.text.trim();
    final reason = _reasonController.text.trim();

    // Validate: at least one of problemId or problemLink, and reason is required
    if ((problemId.isEmpty && problemLink.isEmpty) || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason.isEmpty
                ? 'Please enter a reason'
                : 'Please enter at least Problem ID or Problem Link',
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.insertDoLater(
        category: widget.categoryName,
        problemId: problemId.isEmpty ? null : problemId,
        problemLink: problemLink.isEmpty ? null : problemLink,
        reason: reason,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 32),
                  _buildForm(),
                ],
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
            'Add to Do Later',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _problemIdController,
            label: 'Problem ID',
            hint: 'e.g., 1234A',
            icon: Icons.tag,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _problemLinkController,
            label: 'Problem Link',
            hint: 'e.g., https://codeforces.com/problem/...',
            icon: Icons.link,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _reasonController,
            label: 'Reason to Do Later',
            hint: 'Why are you postponing this problem?',
            icon: Icons.description,
            maxLines: 4,
            required: true,
          ),
          const SizedBox(height: 28),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.redAccent.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.35), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveDoLater,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
      ),
      child: _isSaving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withOpacity(0.7),
              ),
            )
          : const Text(
              'Save to Do Later',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
