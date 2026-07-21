import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/app/app.dart';

void main() {
  testWidgets('app shell renders the M0 placeholder', (tester) async {
    await tester.pumpWidget(const LifeLedgerApp());
    expect(find.text('LifeLedger'), findsOneWidget);
    expect(
      find.text('Understand your body, one day at a time.'),
      findsOneWidget,
    );
  });
}
