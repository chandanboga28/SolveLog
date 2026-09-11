import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

/// Repository for managing categories in Supabase
/// 
/// Handles all cloud storage operations for user categories.
/// Uses Supabase RLS policies to ensure users can only access their own data.
/// 
/// IMPORTANT: This repository relies on Supabase Row Level Security (RLS)
/// for data isolation. Never bypass RLS by using service role keys in the client.
class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository(this._client);

  /// Get the current authenticated user's ID
  /// 
  /// Returns null if no user is authenticated.
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  /// Fetch all categories for the current authenticated user
  /// 
  /// Returns empty list if not authenticated or if user has no categories.
  /// RLS ensures only the user's own categories are returned.
  Future<List<Category>> fetchUserCategories() async {
    if (!isAuthenticated) {
      return [];
    }

    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: true);

      final data = response as List<dynamic>;
      
      return data.map((json) => _categoryFromSupabase(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Insert a new category for the current authenticated user
  /// 
  /// The user_id is automatically set to the authenticated user.
  /// RLS ensures users can only insert categories for themselves.
  /// 
  /// Returns the created category with its Supabase-generated UUID.
  /// Throws exception if not authenticated or if insert fails.
  Future<Category> insertCategory(Category category) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('categories')
          .insert({
            'user_id': _currentUserId!,
            'name': category.name,
            'icon': category.icon,
            'type': category.type.toString().split('.').last,
            'website': category.website,
            'integration_type': category.integrationType.toString().split('.').last,
          })
          .select()
          .single();

      return _categoryFromSupabase(response);
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  /// Update an existing category
  /// 
  /// RLS ensures users can only update their own categories.
  /// 
  /// Throws exception if not authenticated or if update fails.
  Future<void> updateCategory(String supabaseId, Category category) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('categories')
          .update({
            'name': category.name,
            'icon': category.icon,
            'type': category.type.toString().split('.').last,
            'website': category.website,
            'integration_type': category.integrationType.toString().split('.').last,
          })
          .eq('id', supabaseId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  /// Delete a category by its Supabase UUID
  /// 
  /// RLS ensures users can only delete their own categories.
  /// 
  /// Throws exception if not authenticated or if delete fails.
  Future<void> deleteCategory(String supabaseId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('categories')
          .delete()
          .eq('id', supabaseId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  /// Find a category by name for the current user
  /// 
  /// Returns null if not found or not authenticated.
  /// Useful for checking duplicates before insert.
  Future<Category?> findCategoryByName(String name) async {
    if (!isAuthenticated) {
      return null;
    }

    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('name', name)
          .maybeSingle();

      if (response == null) return null;
      
      return _categoryFromSupabase(response);
    } catch (e) {
      print('Error finding category: $e');
      return null;
    }
  }

  /// Convert Supabase JSON to Category model
  /// 
  /// Maps Supabase UUID and metadata to the local Category model.
  Category _categoryFromSupabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String, // Supabase UUID
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '📝',
      type: _parseCategoryType(json['type'] as String?),
      website: json['website'] as String?,
      integrationType: _parseIntegrationType(json['integration_type'] as String?),
    );
  }

  CategoryType _parseCategoryType(String? typeStr) {
    if (typeStr == null) return CategoryType.custom;
    try {
      return CategoryType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => CategoryType.custom,
      );
    } catch (_) {
      return CategoryType.custom;
    }
  }

  IntegrationType _parseIntegrationType(String? typeStr) {
    if (typeStr == null) return IntegrationType.none;
    try {
      return IntegrationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => IntegrationType.none,
      );
    } catch (_) {
      return IntegrationType.none;
    }
  }
}
