import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Screen for editing an existing category (default or custom).
///
/// Allows users to change the icon and name of a category.
/// Updates are saved to SharedPreferences.
class EditCategoryScreen extends StatefulWidget {
  final String originalIcon;
  final String originalName;
  final int categoryIndex;
  final bool isDefault;

  const EditCategoryScreen({
    Key? key,
    required this.originalIcon,
    required this.originalName,
    required this.categoryIndex,
    this.isDefault = false,
  }) : super(key: key);

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  
  late String _selectedIcon;
  bool _isSubmitting = false;

  // Common emoji icons for categories
  final List<String> _iconOptions = [
    '📝', '💡', '🎯', '🚀', '⭐', '🔥',
    '💻', '🧩', '🎨', '📚', '🏆', '⚡',
    '🌟', '✨', '🎓', '🔷', '🔶', '🟢',
    '🔵', '🟣', '🟡', '🔴', '🟠', '🟤',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.originalName);
    _selectedIcon = widget.originalIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Determine which category list to work with
      final storageKey = widget.isDefault ? 'default_categories' : 'custom_categories';
      
      // Get existing categories
      final categoriesJson = prefs.getString(storageKey) ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);
      
      // Check for duplicate name (excluding current category)
      final categoryName = _nameController.text.trim();
      
      // Check against categories in the same list (excluding current)
      final isDuplicate = categories.asMap().entries.any(
        (entry) => entry.key != widget.categoryIndex &&
                   entry.value['name'].toString().toLowerCase() == categoryName.toLowerCase()
      );
      
      if (isDuplicate) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category with this name already exists'),
            backgroundColor: Colors.orange.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      
      // Check against the other category list
      final otherStorageKey = widget.isDefault ? 'custom_categories' : 'default_categories';
      final otherCategoriesJson = prefs.getString(otherStorageKey) ?? '[]';
      final List<dynamic> otherCategories = json.decode(otherCategoriesJson);
      
      final isDuplicateOther = otherCategories.any(
        (cat) => cat['name'].toString().toLowerCase() == categoryName.toLowerCase()
      );
      
      if (isDuplicateOther) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category with this name already exists'),
            backgroundColor: Colors.orange.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      
      // Update category
      categories[widget.categoryIndex] = {
        'icon': _selectedIcon,
        'name': categoryName,
      };
      
      // Save back to SharedPreferences
      await prefs.setString(storageKey, json.encode(categories));
      
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category updated successfully!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          content: Text('Failed to update category: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 48),
                    _buildIconSelector(),
                    const SizedBox(height: 32),
                    _buildNameField(),
                    const SizedBox(height: 48),
                    _buildPreview(),
                    const SizedBox(height: 48),
                    _buildActionButtons(),
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
          'Edit Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an Icon',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _iconOptions.map((icon) {
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Name',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g. HackerRank, CodeChef, Personal',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
            ),
            errorStyle: TextStyle(
              color: Colors.redAccent.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          validator: _requiredValidator,
          onChanged: (value) => setState(() {}), // Update preview
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final previewName = _nameController.text.trim().isEmpty
        ? widget.originalName
        : _nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 180,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    previewName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                    'Update Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
