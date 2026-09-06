import 'package:flutter/material.dart';
import 'screens/platform_selection_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SolveLogApp());
}

class SolveLogApp extends StatelessWidget {
  const SolveLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolveLog',
      theme: AppTheme.theme,
      home: const PlatformSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}