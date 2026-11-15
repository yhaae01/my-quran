import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/presentation/pages/hijri_calendar_page.dart';

void main() {
  testWidgets(
    'HijriCalendarPage renders month, days of week and calendar cells',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedDate = DateTime(2026, 11, 15);

      await tester.pumpWidget(
        MaterialApp(home: HijriCalendarPage(initialDate: fixedDate)),
      );
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Kalender Hijriah'), findsOneWidget);

      // Verify Month Header
      expect(find.text('Jumadil Akhir 1448 H'), findsOneWidget);

      // Verify Weekday Headers
      for (final weekday in ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']) {
        expect(find.text(weekday), findsOneWidget);
      }

      // Verify day numbers are rendered
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);

      // Verify Next Month Navigation
      final nextButton = find.byTooltip('Bulan Berikutnya');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Rajab 1448 H'), findsOneWidget);

      // Verify Previous Month Navigation
      final prevButton = find.byTooltip('Bulan Sebelumnya');
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text('Jumadil Akhir 1448 H'), findsOneWidget);

      // Verify "Hari Ini" button resets
      final todayButton = find.text('Hari Ini');
      expect(todayButton, findsOneWidget);
      await tester.tap(todayButton);
      await tester.pumpAndSettle();

      // Tapping another day on the grid updates detail card
      final day10Key = find.byKey(const ValueKey('hijri_cell_6_10'));
      expect(day10Key, findsOneWidget);
      await tester.tap(day10Key);
      await tester.pumpAndSettle();

      expect(find.textContaining('10 Jumadil Akhir 1448 H'), findsOneWidget);
    },
  );
}
