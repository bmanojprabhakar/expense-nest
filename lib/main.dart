import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'services/simple_data_init.dart';
import 'debug/database_debug_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔧 DEBUG: Set to true to reset database on app launch
  // ⚠️  WARNING: This will DELETE ALL existing data!
  const bool resetDatabaseOnLaunch = false;
  
  if (resetDatabaseOnLaunch) {
    print('🔄 DEBUG MODE: Resetting database...');
    await DatabaseDebugHelper.resetDatabaseCompletely();
  } else {
    await SimpleDataInit.initializeBasicData();
  }
  
  runApp(
    const ProviderScope(
      child: ExpenseNestApp(),
    ),
  );
}

class ExpenseNestApp extends StatelessWidget {
  const ExpenseNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseNest',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}