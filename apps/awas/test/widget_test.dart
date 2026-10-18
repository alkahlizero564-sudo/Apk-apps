import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:awas/main.dart';
import 'package:awas/state/expense_provider.dart';

void main() {
  testWidgets('App renders Awas home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ],
        child: const AwasApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify app title or core UI element is displayed
    expect(find.text('عوّاس - المصروفات'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
