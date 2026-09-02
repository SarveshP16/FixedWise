import 'dart:io';

import 'package:fixedwise_app/app.dart';
import 'package:fixedwise_app/core/storage/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Hive does real file I/O, which doesn't play well with `pumpAndSettle`'s
/// fake-async clock (a real I/O callback can arrive after `pumpAndSettle`
/// already decided no more frames are scheduled, or — worse — never get
/// serviced at all and wedge every later test in the file). Boxes are
/// opened once for the whole file and just `clear()`ed between tests
/// (`Hive.close()`/`deleteFromDisk()` were both observed to hang here after
/// a write) and every pump happens inside `tester.runAsync`, which runs
/// the real event loop instead of the fake one.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const ProviderScope(child: FixedWiseApp()));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pump();
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('fixedwise_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveBoxes.holders);
    await Hive.openBox<Map>(HiveBoxes.fixedDeposits);
    await Hive.openBox(HiveBoxes.settings);
  });

  setUp(() async {
    await Hive.box<Map>(HiveBoxes.holders).clear();
    await Hive.box<Map>(HiveBoxes.fixedDeposits).clear();
    await Hive.box(HiveBoxes.settings).clear();
  });

  testWidgets('app boots to the dashboard with an empty portfolio', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Total across deposits'), findsOneWidget);
    expect(find.text('No deposits yet — add your first one to see it here.'), findsOneWidget);

    // Bottom nav destinations from the mockup. "Calculator" also labels the
    // dashboard's own quick-action button, so it appears twice.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Deposits'), findsOneWidget);
    expect(find.text('Calculator'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('switching to the Deposits tab shows the empty state', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Deposits'));
    await _settle(tester);

    expect(find.text('No deposits yet. Tap + to add your first Fixed Deposit.'), findsOneWidget);
  });

  testWidgets('creating a deposit from the New Deposit form shows it on the list', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Deposits'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.add));
    await _settle(tester);

    expect(find.text('New deposit'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'e.g. Anchor Bank'), 'Test Bank');
    await tester.pump();

    await tester.tap(find.text('Create deposit'));
    await _settle(tester);

    expect(find.text('Test Bank'), findsWidgets);
  });
}
