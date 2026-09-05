import 'package:flutter/material.dart';
import 'screens/platform_selection_screen.dart';

void main() {
  runApp(const SolveLogApp());
}

class SolveLogApp extends StatelessWidget {
  const SolveLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolveLog',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        // Custom dark theme colors
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      home: const PlatformSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}