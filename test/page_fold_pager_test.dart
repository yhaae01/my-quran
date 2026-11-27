import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/presentation/widgets/page_fold_pager.dart';

void main() {
  late List<int> changes;
  late PageFoldPagerController controller;

  Widget harness({int initialPage = 0}) {
    changes = [];
    controller = PageFoldPagerController();
    return MaterialApp(
      home: Scaffold(
        body: PageFoldPager(
          controller: controller,
          pageCount: 5,
          initialPage: initialPage,
          pageBuilder: (index) => Center(child: Text('p$index')),
          onPageChanged: changes.add,
        ),
      ),
    );
  }

  testWidgets('left swipe turns forward and shows the next page', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    // The next page is already mounted behind the active one.
    expect(find.text('p0'), findsOneWidget);
    expect(find.text('p1'), findsOneWidget);

    await tester.drag(find.byType(PageFoldPager), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(changes, [1]);
    expect(controller.page, 1);
  });

  testWidgets('right swipe on the first page cannot go back', (tester) async {
    await tester.pumpWidget(harness());

    await tester.drag(find.byType(PageFoldPager), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(controller.page, 0);
  });

  testWidgets('right swipe turns back to the previous page', (tester) async {
    await tester.pumpWidget(harness(initialPage: 2));

    await tester.drag(find.byType(PageFoldPager), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(changes, [1]);
    expect(controller.page, 1);
  });

  testWidgets('a short swipe snaps back to the same page', (tester) async {
    await tester.pumpWidget(harness());

    await tester.timedDrag(
      find.byType(PageFoldPager),
      const Offset(-60, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(controller.page, 0);
  });

  testWidgets('jumpToPage swaps pages without a turn', (tester) async {
    await tester.pumpWidget(harness(initialPage: 1));

    controller.jumpToPage(4);
    await tester.pumpAndSettle();

    expect(changes, [4]);
    expect(controller.page, 4);
  });
}
