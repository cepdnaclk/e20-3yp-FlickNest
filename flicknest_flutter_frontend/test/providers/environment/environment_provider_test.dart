import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flicknest_flutter_frontend/providers/environment/environment_provider.dart';

void main() {
  group('Environment Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    test('initial environment state is null', () {
      final environment = container.read(currentEnvironmentProvider);
      expect(environment, isNull);
    });

    test('can set current environment', () {
      container.read(currentEnvironmentProvider.notifier).state = 'test-env-1';
      expect(container.read(currentEnvironmentProvider), equals('test-env-1'));
    });

    test('can update current environment', () {
      container.read(currentEnvironmentProvider.notifier).state = 'test-env-1';
      container.read(currentEnvironmentProvider.notifier).state = 'test-env-2';
      expect(container.read(currentEnvironmentProvider), equals('test-env-2'));
    });

    test('can clear current environment', () {
      container.read(currentEnvironmentProvider.notifier).state = 'test-env-1';
      container.read(currentEnvironmentProvider.notifier).state = null;
      expect(container.read(currentEnvironmentProvider), isNull);
    });
  });
} 