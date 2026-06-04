import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/widgets/otp_input.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders four single-digit boxes', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OtpInput(onCompleted: (_) {})));

    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('calls onCompleted with the joined code once all boxes are filled',
      (WidgetTester tester) async {
    String? completed;
    await tester.pumpWidget(wrap(OtpInput(onCompleted: (code) => completed = code)));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), '2');
    await tester.enterText(fields.at(2), '3');
    await tester.enterText(fields.at(3), '4');
    await tester.pump();

    expect(completed, '1234');
  });

  testWidgets('does not complete until every box is filled',
      (WidgetTester tester) async {
    String? completed;
    await tester.pumpWidget(wrap(OtpInput(onCompleted: (code) => completed = code)));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), '2');
    await tester.pump();

    expect(completed, isNull);
  });

  testWidgets('does not accept input when disabled', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OtpInput(enabled: false, onCompleted: (_) {})));

    final TextField first = tester.widget(find.byType(TextField).first);
    expect(first.enabled, isFalse);
  });
}
