import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/presentation/widgets/double_back_exit.dart';

void main() {
  testWidgets('first back press warns, second press exits', (tester) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DoubleBackExit(
          child: Scaffold(body: Center(child: Text('Beranda'))),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      find.text('Tekan sekali lagi untuk keluar aplikasi'),
      findsOneWidget,
    );
    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });
}
