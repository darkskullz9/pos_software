import 'package:flutter/material.dart';

import '../core/widgets/app_shell.dart';
import 'theme/app_theme.dart';

class CaisseApp extends StatelessWidget {
  const CaisseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logiciel de caisse',
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}