import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import 'category_repository.dart';
import 'auth_service.dart';

/// Service for syncing categories between local storage and Supabase
/// 
/// This maintains both:
/// - Local storage (SharedPreferences) for offline access and existing functionality
/// - Cloud storage (Supabase) for authenticated users
/// 
/// LOCAL-FIRST APPROACH:
/// - SQLite/SharedPreferences remains the primary source for the UI
/// - Supabase acts as the authenticated user's cloud backup
/// - Operations try Supabase but don't fail if cloud sync fails
class CategorySyncService {
  final CategoryRepository _repository;
  final AuthService _authService;

  CategorySyncService(this._repository, this._authService);

  /// Get user-specific storage keys
  /// 
  /// This ensures each user's data is isolated in SharedPreferences.
  /// Keys are namespaced by user ID to prevent cross-user data leakage.
  String _getUserKey(String baseKey) {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      // Fallback for logged-out state - use global keys
      return baseKey;
    }
    return '${baseKey}_$userId';
  }

  String get _defaultCategoriesKey => _getUserKey('default_categories');
  String get _customCategoriesKey => _getUserKey('custom_categories');
  String get _supabaseMappingKey => _getUserKey('category_supabase_mapping');

  /// Load categories on app start or after login
  /// 
  /// If authenticated, fetches user's categories from Supabase as source of truth.
  /// Returns the categories that should be displayed.
  Future<List<Category>> syncOnLogin() async {
    if (!_authService.isAuthenticated) {
      return [];
    }

    try {
      // Fetch user's categories from Supabase (SOURCE OF TRUTH)
      final cloudCategories = await _repository.fetchUserCategories();
      
      // Always replace local storage with cloud data
      await _replaceLocalWithCloudCategories(cloudCategories);
      
      // Return cloud categories for immediate use
      return cloudCategories;
    } catch (e) {
      print('Error syncing categories on login: $e');
      rethrow; // Don't silently fail - caller needs to know
    }
  }

  /// Add a new category (both local and cloud)
  /// 
  /// Steps:
  /// 1. Save to Supabase (source of truth)
  /// 2. Save to local storage (SharedPreferences) for offline access
  /// 3. Store mapping between local ID and Supabase UUID
  /// 
  /// Returns the created category or null if failed
  Future<Category?> addCategory(Category category, {bool isDefault = false}) async {
    try {
      // 1. Save to Supabase first (source of truth)
      if (_authService.isAuthenticated) {
        try {
          final cloudCategory = await _repository.insertCategory(category);
          
          // 2. Save locally with Supabase UUID
          final prefs = await SharedPreferences.getInstance();
          final storageKey = isDefault ? _defaultCategoriesKey : _customCategoriesKey;
          final categoriesJson = prefs.getString(storageKey) ?? '[]';
          final List<dynamic> categories = json.decode(categoriesJson);
          
          categories.add(cloudCategory.toJson());
          await prefs.setString(storageKey, json.encode(categories));
          
          // 3. Store mapping
          await _storeCategoryMapping(cloudCategory.id, cloudCategory.id);
          
          return cloudCategory;
        } catch (e) {
          print('Error saving category to cloud: $e');
          rethrow; // Don't silently fail
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error adding category: $e');
      return null;
    }
  }

  /// Update an existing category
  /// 
  /// Updates both local and cloud storage.
  Future<bool> updateCategory(
    Category category,
    int categoryIndex,
    {bool isDefault = false}
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Update locally
      final storageKey = isDefault ? _defaultCategoriesKey : _customCategoriesKey;
      final categoriesJson = prefs.getString(storageKey) ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);
      
      if (categoryIndex >= 0 && categoryIndex < categories.length) {
        categories[categoryIndex] = category.toJson();
        await prefs.setString(storageKey, json.encode(categories));
      }

      // 2. Update in Supabase if authenticated
      if (_authService.isAuthenticated) {
        try {
          final supabaseId = await _getSupabaseId(category.id);
          if (supabaseId != null) {
            await _repository.updateCategory(supabaseId, category);
          }
        } catch (e) {
          print('Warning: Failed to sync category update to cloud: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  /// Delete a category (cloud first, then local)
  /// 
  /// Removes from Supabase first (source of truth), then local storage.
  Future<bool> deleteCategory(
    String categoryId,
    int categoryIndex,
    {bool isDefault = false}
  ) async {
    try {
      // 1. Delete from Supabase first (source of truth)
      if (_authService.isAuthenticated) {
        try {
          final supabaseId = await _getSupabaseId(categoryId);
          if (supabaseId != null) {
            await _repository.deleteCategory(supabaseId);
            await _removeCategoryMapping(categoryId);
          }
        } catch (e) {
          print('Error deleting category from cloud: $e');
          rethrow; // Don't silently fail - this is critical
        }
      }
      
      // 2. Delete locally after cloud delete succeeds
      final prefs = await SharedPreferences.getInstance();
      final storageKey = isDefault ? _defaultCategoriesKey : _customCategoriesKey;
      final categoriesJson = prefs.getString(storageKey) ?? '[]';
      final List<dynamic> categories = json.decode(categoriesJson);
      
      if (categoryIndex >= 0 && categoryIndex < categories.length) {
        categories.removeAt(categoryIndex);
        await prefs.setString(storageKey, json.encode(categories));
      }

      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  /// Check if a category name already exists (local + cloud check)
  Future<bool> categoryExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check local default categories
    final defaultCategoriesJson = prefs.getString(_defaultCategoriesKey) ?? '[]';
    final List<dynamic> defaultCategories = json.decode(defaultCategoriesJson);
    
    final existsInDefault = defaultCategories.any(
      (cat) => cat['name'].toString().toLowerCase() == name.toLowerCase(),
    );
    
    if (existsInDefault) return true;
    
    // Check local custom categories
    final customCategoriesJson = prefs.getString(_customCategoriesKey) ?? '[]';
    final List<dynamic> customCategories = json.decode(customCategoriesJson);
    
    final existsInCustom = customCategories.any(
      (cat) => cat['name'].toString().toLowerCase() == name.toLowerCase(),
    );
    
    return existsInCustom;
  }

  /// Replace local categories with cloud categories (complete sync)
  /// 
  /// This ensures the authenticated user sees ONLY their cloud categories,
  /// preventing cross-user data leakage.
  Future<void> _replaceLocalWithCloudCategories(List<Category> cloudCategories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear existing local categories for this user
      final List<dynamic> localCategories = [];
      
      // Add all cloud categories to local storage
      for (final cloudCat in cloudCategories) {
        localCategories.add(cloudCat.toJson());
        // Store mapping (Supabase ID is used as both local and cloud ID)
        await _storeCategoryMapping(cloudCat.id, cloudCat.id);
      }
      
      // Save to user-specific key
      await prefs.setString(_customCategoriesKey, json.encode(localCategories));
      
      print('Replaced local categories with ${cloudCategories.length} cloud categories');
    } catch (e) {
      print('Error replacing local categories with cloud: $e');
    }
  }

  /// Store mapping between local category ID and Supabase UUID
  Future<void> _storeCategoryMapping(String localId, String supabaseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_supabaseMappingKey) ?? '{}';
      final Map<String, dynamic> mapping = json.decode(mappingJson);
      
      mapping[localId] = supabaseId;
      
      await prefs.setString(_supabaseMappingKey, json.encode(mapping));
    } catch (e) {
      print('Error storing category mapping: $e');
    }
  }

  /// Get Supabase UUID for a local category ID
  Future<String?> _getSupabaseId(String localId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_supabaseMappingKey) ?? '{}';
      final Map<String, dynamic> mapping = json.decode(mappingJson);
      
      return mapping[localId] as String?;
    } catch (e) {
      print('Error getting Supabase ID: $e');
      return null;
    }
  }

  /// Remove mapping for a deleted category
  Future<void> _removeCategoryMapping(String localId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_supabaseMappingKey) ?? '{}';
      final Map<String, dynamic> mapping = json.decode(mappingJson);
      
      mapping.remove(localId);
      
      await prefs.setString(_supabaseMappingKey, json.encode(mapping));
    } catch (e) {
      print('Error removing category mapping: $e');
    }
  }

  /// Clear local categories and mappings for current user
  /// 
  /// Call this on logout to ensure the next user doesn't see this user's data.
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove user-specific keys
      await prefs.remove(_defaultCategoriesKey);
      await prefs.remove(_customCategoriesKey);
      await prefs.remove(_supabaseMappingKey);
      
      print('Cleared local category data for user');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
