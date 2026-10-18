import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:nawa/main.dart';
import 'package:nawa/services/storage_service.dart';
import 'package:nawa/state/expense_provider.dart';
import 'package:nawa/state/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Nawa app renders dashboard header and title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(storage, ThemeMode.light),
          ),
          ChangeNotifierProvider(
            create: (_) => ExpenseProvider(storage),
          ),
        ],
        child: const NawaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('نَـوَى'), findsOneWidget);
    expect(find.text('الرصيد الإجمالي'), findsOneWidget);
    expect(find.text('معاملة جديدة'), findsOneWidget);
  });
}
