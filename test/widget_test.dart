import 'package:flutter_test/flutter_test.dart';

import 'package:mishkat/main.dart';

void main() {
  testWidgets('MishkatApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const MishkatApp());
    expect(find.byType(MishkatApp), findsOneWidget);
  });
}
