import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/category_sync_service.dart';

/// Screen for adding a new category by selecting from predefined platforms
/// or creating a custom one.
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({Key? key}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  bool _isLoading = false;
  late final CategorySyncService _categorySyncService;

  @override
  void initState() {
    super.initState();
    final repository = CategoryRepository(Supabase.instance.client);
    _categorySyncService = CategorySyncService(repository, AuthService());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 48),
                  _buildSectionHeader('Popular Platforms'),
                  const SizedBox(height: 24),
                  _buildPlatformGrid(),
                  const SizedBox(height: 40),
                  _buildCustomOption(),
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
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Text(
          'Add Category',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildPlatformGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: PredefinedPlatforms.platforms.map((platform) {
        return _PlatformCard(
          platform: platform,
          onTap: () => _handlePlatformSelection(platform),
        );
      }).toList(),
    );
  }

  Widget _buildCustomOption() {
    return _CustomPlatformCard(
      onTap: () => _showCustomPlatformDialog(),
    );
  }

  Future<void> _handlePlatformSelection(Category platform) async {
    setState(() => _isLoading = true);

    try {
      // Check if platform already exists
      if (await _categorySyncService.categoryExists(platform.name)) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('${platform.name} is already added');
        return;
      }

      // Add using sync service (cloud first, then local)
      final addedCategory = await _categorySyncService.addCategory(platform);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (addedCategory != null) {
        _showSuccess('${platform.name} added successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        _showError('Failed to add ${platform.name}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _showCustomPlatformDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Custom Platform',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the platform name',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Project Euler',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderFocus, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _handleCustomPlatform(nameController.text.trim());
    }
  }

  Future<void> _handleCustomPlatform(String name) async {
    setState(() => _isLoading = true);

    try {
      // Check if platform already exists
      if (await _categorySyncService.categoryExists(name)) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('$name is already added');
        return;
      }

      // Create custom category
      final customCategory = Category(
        id: Category.generateId(name),
        name: name,
        icon: 'folder_outlined',
        type: CategoryType.custom,
        integrationType: IntegrationType.none,
      );

      // Add using sync service (cloud first, then local)
      final addedCategory = await _categorySyncService.addCategory(customCategory);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (addedCategory != null) {
        _showSuccess('$name added successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        _showError('Failed to add $name');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to add category: ${e.toString()}');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PlatformCard extends StatefulWidget {
  final Category platform;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.platform,
    required this.onTap,
  });

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> {
  bool _isHovered = false;

  IconData get _iconData {
    switch (widget.platform.icon) {
      case 'code':
        return Icons.code;
      case 'bolt':
        return Icons.bolt;
      case 'radio_button_checked':
        return Icons.radio_button_checked;
      case 'restaurant':
        return Icons.restaurant;
      case 'military_tech':
        return Icons.military_tech;
      case 'hub':
        return Icons.hub;
      case 'public':
        return Icons.public;
      case 'school':
        return Icons.school;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: _isHovered ? AppTheme.primary.withOpacity(0.6) : AppTheme.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconData,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.platform.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomPlatformCard extends StatefulWidget {
  final VoidCallback onTap;

  const _CustomPlatformCard({required this.onTap});

  @override
  State<_CustomPlatformCard> createState() => _CustomPlatformCardState();
}

class _CustomPlatformCardState extends State<_CustomPlatformCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: _isHovered ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
              width: 1,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isHovered ? AppTheme.primary : AppTheme.textTertiary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add,
                  color: _isHovered ? AppTheme.primary : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Custom Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? AppTheme.primary : AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
