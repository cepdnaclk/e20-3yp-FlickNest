import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flicknest_flutter_frontend/helpers/utils.dart';
import 'package:flicknest_flutter_frontend/helpers/theme_notifier.dart';

void main() {
  group('Helper Functions Tests', () {
    group('Navigator Key Tests', () {
      test('mainNav key is initialized', () {
        expect(Utils.mainNav, isNotNull);
        expect(Utils.mainNav, isA<GlobalKey<NavigatorState>>());
      });

      test('tabNav key is initialized', () {
        expect(Utils.tabNav, isNotNull);
        expect(Utils.tabNav, isA<GlobalKey<NavigatorState>>());
      });

      test('scaffoldKey is initialized', () {
        expect(Utils.scaffoldKey, isNotNull);
        expect(Utils.scaffoldKey, isA<GlobalKey<ScaffoldState>>());
      });
    });

    group('Theme Notifier Tests', () {
      late ThemeNotifier themeNotifier;

      setUp(() {
        themeNotifier = ThemeNotifier();
      });

      test('initial theme mode is system', () {
        expect(themeNotifier.value, equals(ThemeMode.system));
      });

      test('can change theme', () {
        themeNotifier.setTheme(ThemeMode.light);
        expect(themeNotifier.value, equals(ThemeMode.light));

        themeNotifier.setTheme(ThemeMode.dark);
        expect(themeNotifier.value, equals(ThemeMode.dark));

        themeNotifier.setTheme(ThemeMode.light);
        expect(themeNotifier.value, equals(ThemeMode.light));
      });

      test('notifies listeners when theme changes', () {
        var notificationCount = 0;
        themeNotifier.addListener(() {
          notificationCount++;
        });

        themeNotifier.setTheme(ThemeMode.dark);
        expect(notificationCount, 1);

        themeNotifier.setTheme(ThemeMode.light);
        expect(notificationCount, 2);
      });
    });
  });
}
