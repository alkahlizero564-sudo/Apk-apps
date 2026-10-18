import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/state/montage_provider.dart';
import 'package:awadalj/theme/app_theme.dart';
import 'package:awadalj/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MontageProvider()),
      ],
      child: const AwadaljApp(),
    ),
  );
}

class AwadaljApp extends StatelessWidget {
  const AwadaljApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عوض الج | Awadalj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
