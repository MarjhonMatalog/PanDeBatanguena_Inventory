import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/main.dart';

void main() {
  testWidgets('shows the dashboard title', (tester) async {
    await tester.pumpWidget(const InventoryApp());

    expect(find.text('Inventory Dashboard'), findsOneWidget);
  });
}
