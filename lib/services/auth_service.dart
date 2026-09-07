import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Authentication service for SolveLog using Supabase
/// 
/// Manages Google Sign-In, session persistence, and logout functionality.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get the Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase
  /// 
  /// Call this once at app startup before using any auth features.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => client.auth.currentSession != null;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Sign in with Google
  /// 
  /// Opens browser for Google OAuth flow. Returns true if successful.
  Future<bool> signInWithGoogle() async {
    try {
      // For desktop, use the custom scheme redirect
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.solvelog://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  /// Sign out current user
  /// 
  /// Clears the session and returns to login screen.
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  /// 
  /// Use this to react to login/logout events in real-time.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Get user email
  String? get userEmail => currentUser?.email;

  /// Get user display name (from metadata)
  String? get userDisplayName {
    final metadata = currentUser?.userMetadata;
    if (metadata == null) return null;
    
    // Try different possible fields for display name
    return metadata['full_name'] as String? ?? 
           metadata['name'] as String? ??
           metadata['display_name'] as String?;
  }

  /// Get user avatar URL (from metadata)
  String? get userAvatarUrl {
    final metadata = currentUser?.userMetadata;
    if (metadata == null) return null;
    
    return metadata['avatar_url'] as String? ?? 
           metadata['picture'] as String?;
  }
}
