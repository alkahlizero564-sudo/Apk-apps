import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:nawa/services/storage_service.dart';
import 'package:nawa/state/expense_provider.dart';
import 'package:nawa/state/theme_provider.dart';
import 'package:nawa/theme/app_theme.dart';
import 'package:nawa/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  final initialThemeMode = await storageService.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService, initialThemeMode),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(storageService)..loadTransactions(),
        ),
      ],
      child: const NawaApp(),
    ),
  );
}

class NawaApp extends StatelessWidget {
  const NawaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'نوى - إدارة المصروفات',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationScreen(),
    );
  }
}
