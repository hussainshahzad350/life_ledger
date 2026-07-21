import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:life_ledger/core/time/clock.dart';

void main() {
  group('composition root', () {
    setUp(configureDependencies);
    tearDown(resetDependencies);

    test('registers every core service', () {
      expect(getIt<AppLogger>(), isA<ConsoleLogger>());
      expect(getIt<Clock>(), isA<SystemClock>());
      expect(getIt<AppDatabase>(), isA<AppDatabase>());
    });

    test('diSelfCheck passes on a correctly wired graph (M0 DoD)', () {
      expect(diSelfCheck, returnsNormally);
    });

    test('singletons resolve to the same instance', () {
      expect(identical(getIt<Clock>(), getIt<Clock>()), isTrue);
      expect(identical(getIt<AppDatabase>(), getIt<AppDatabase>()), isTrue);
    });
  });

  group('miswired graph', () {
    tearDown(resetDependencies);

    test('diSelfCheck fails fast when a registration is missing', () {
      // Nothing registered: the self-check must throw, not defer the error.
      expect(diSelfCheck, throwsA(isA<Error>()));
    });
  });
}
