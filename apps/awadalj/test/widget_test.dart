import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:awadalj/main.dart';
import 'package:awadalj/state/montage_provider.dart';

void main() {
  testWidgets('App loads home screen with montage action button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MontageProvider()),
        ],
        child: const AwadaljApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Arabic app title or main UI elements exist
    expect(find.text('عوض الج | Awadalj'), findsOneWidget);
    expect(find.text('إرفاق فيديو جديد'), findsOneWidget);
    expect(find.text('تجربة عينة فيديو فورية (بدون رفع)'), findsOneWidget);
  });
}
