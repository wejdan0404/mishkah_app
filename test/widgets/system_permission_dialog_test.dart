import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/widgets/dialogs/system_permission_dialog.dart';

void main() {
  Widget host(void Function(bool) onResult) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final r = await showSystemPermissionDialog(
                context,
                title: 'عنوان',
                message: 'رسالة',
                confirmLabel: 'السماح',
                cancelLabel: 'إلغاء',
              );
              onResult(r);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows title, message and both labels', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان'), findsOneWidget);
    expect(find.text('رسالة'), findsOneWidget);
    expect(find.text('السماح'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('returns true when confirm tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السماح'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false when cancel tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('wraps content in RTL Directionality by default', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Directionality dir = tester.widget(
      find
          .ancestor(
            of: find.text('عنوان'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(dir.textDirection, TextDirection.rtl);
  });
}
