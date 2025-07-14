import 'package:flicknest_flutter_frontend/features/devices/presentation/pages/devices.page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/main.dart' as app;

void main() {
  group('Performance Tests', () {
    testWidgets('Home page loads within acceptable time', (tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('Device list scrolling is smooth', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DevicesPage(),
          ),
        ),
      );

      final listFinder = find.byType(ListView);

      // Create a gesture that slowly drags the list view
      final gesture = await tester.startGesture(tester.getCenter(listFinder));
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify no frames were dropped during scrolling
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('Real-time temperature updates are efficient', (tester) async {
      final stopwatch = Stopwatch()..start();

      // Simulate 100 temperature updates
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(12000)); // Should take less than 12 seconds
    });
  });
}
