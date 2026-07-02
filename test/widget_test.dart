import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:diaryapp/main.dart';
import 'package:diaryapp/sql_helper.dart';

void main() {
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await SQLHelper.db();
    await db.delete('diary');
  });

  testWidgets('Calendar view shows monthly grid and entry details', (
    WidgetTester tester,
  ) async {
    await SQLHelper.createDiary('Happy', 'Test entry');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar View'));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byType(GridView), findsWidgets);

    final today = DateTime.now();
    await tester.tap(find.text(today.day.toString()).first);
    await tester.pumpAndSettle();

    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Test entry'), findsOneWidget);
  });

  testWidgets(
      'Checklist view adds goals, tracks completion, and shows progress', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist / Daily Goals'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Drink water');
    await tester.tap(find.text('Add Goal'));
    await tester.pumpAndSettle();

    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
  });
}
