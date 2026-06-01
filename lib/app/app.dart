import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../core/widgets/app_shell.dart';
import '../features/dashboard/dashboard_page.dart';

class CaisseApp extends StatelessWidget {
  const CaisseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logiciel de caisse',
      theme: AppTheme.lightTheme,
      home: const AppShell(
        title: 'Tableau de bord',
        child: DashboardPage(),
      ),
    );
  }
}