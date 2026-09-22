import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assocmap_mobile_app/main.dart';

void main() {
  testWidgets('guest can explore published sites without logging in', (
    tester,
  ) async {
    await tester.pumpWidget(const AssocMapApp());
    await tester.tap(find.text('Explore public map'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2 published locations'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('2 published locations'), findsOneWidget);
    expect(find.text('Unverified site'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('member can login and navigate programs at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AssocMapApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'member@assocmap.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'AssocMap123!');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programs'));
    await tester.pumpAndSettle();
    expect(find.text('Bangus livelihood development'), findsOneWidget);
    await tester.tap(find.text('Trainings').last);
    await tester.pumpAndSettle();
    expect(find.text('Association record keeping'), findsOneWidget);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Elena');
    await tester.enterText(find.byType(TextFormField).at(2), 'Villanueva');
    await tester.ensureVisible(find.text('Select date of birth'));
    await tester.tap(find.text('Select date of birth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit Registration'));
    await tester.tap(find.text('Submit Registration'));
    await tester.pumpAndSettle();
    expect(
      find.text('Elena Villanueva has been submitted for review.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to Registration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Members').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrations'));
    await tester.pumpAndSettle();
    expect(find.text('Elena Villanueva'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
