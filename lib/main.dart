import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/platform_selection_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

/// Main entry point for SolveLog
/// 
/// Initializes Supabase and handles authentication routing.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await AuthService.initialize();
  
  runApp(const SolveLogApp());
}

class SolveLogApp extends StatelessWidget {
  const SolveLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolveLog',
      theme: AppTheme.theme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Authentication gate that routes to login or home based on session
/// 
/// Listens to auth state changes and automatically navigates when
/// user signs in or out.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes and handle navigation
    _authService.authStateChanges.listen((AuthState state) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with the correct screen
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking initial auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          );
        }

        // Check if user is authenticated
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is logged in, show platform selection
          // Using Navigator to ensure clean navigation stack
          return WillPopScope(
            onWillPop: () async => false, // Disable back button
            child: const PlatformSelectionScreen(),
          );
        } else {
          // User is not logged in, show login screen
          return WillPopScope(
            onWillPop: () async => false, // Disable back button
            child: const LoginScreen(),
          );
        }
      },
    );
  }
}