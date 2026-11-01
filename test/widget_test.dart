import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/main.dart';

void main() {
  testWidgets('Mobile invoice flow saves, edits and approves a draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const InvoFlowApp());
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create invoice'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Test customer');
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USB-C hub'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save draft'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Test customer'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test customer'));
    await tester.pumpAndSettle();
    expect(find.text('JOD 40.600'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Approve invoice'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Approve invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Edit draft'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small mobile screen remains usable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const InvoFlowApp());
    await tester.scrollUntilVisible(find.text('Explore demo'), 100);
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    expect(find.text('Your invoices'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Invoice defaults'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
