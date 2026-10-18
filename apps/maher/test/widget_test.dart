import 'package:flutter_test/flutter_test.dart';
import 'package:maher/main.dart';
import 'package:maher/models/transaction_item.dart';
import 'package:provider/provider.dart';
import 'package:maher/state/expense_provider.dart';
import 'package:maher/state/theme_provider.dart';

void main() {
  testWidgets('Verify Maher app launches and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ],
        child: const MaherApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Arabic app title is rendered
    expect(find.text('تطبيق ماهر'), findsOneWidget);
    expect(find.text('الرصيد المتاح'), findsOneWidget);
  });

  test('TransactionItem model serialization test', () {
    final now = DateTime(2025, 1, 1, 10, 0);
    final tx = TransactionItem(
      id: 'test_1',
      title: 'بنزين',
      amount: 100.0,
      date: now,
      isExpense: true,
      categoryKey: 'transport',
      note: 'محطة الدريس',
    );

    final json = tx.toJson();
    final reconstructed = TransactionItem.fromJson(json);

    expect(reconstructed.id, 'test_1');
    expect(reconstructed.title, 'بنزين');
    expect(reconstructed.amount, 100.0);
    expect(reconstructed.isExpense, true);
    expect(reconstructed.categoryKey, 'transport');
    expect(reconstructed.note, 'محطة الدريس');
  });
}
