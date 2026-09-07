/// Supabase configuration for SolveLog
/// 
/// Contains the project URL and publishable anon key for client-side authentication.
/// These credentials are safe to use in client applications.
class SupabaseConfig {
  // Supabase project URL
  static const String supabaseUrl = 'https://jhndmiuhbiyftnafhphk.supabase.co';
  
  // Supabase publishable anon key (client-safe)
  static const String supabaseAnonKey = 'sb_publishable_q-Y9p7qcWLWGz9IQkMtyhA_lifWIsQw';
  
  // Deep link scheme for OAuth redirects (macOS)
  static const String deepLinkScheme = 'io.supabase.solvelog';
}
