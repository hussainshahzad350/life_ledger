import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';

void main() {
  group('Result', () {
    const failure = DatabaseFailure('boom');

    test('success exposes value and flags', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('failure exposes failure and flags', () {
      const result = Result<int>.failure(failure);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('fold runs exactly the matching branch', () {
      expect(const Result<int>.success(2).fold((f) => 'f', (v) => 'v$v'), 'v2');
      expect(
        const Result<int>.failure(
          failure,
        ).fold((f) => 'f:${f.message}', (v) => 'v'),
        'f:boom',
      );
    });

    test('map transforms success and passes failure through', () {
      expect(const Result<int>.success(2).map((v) => v * 3).valueOrNull, 6);
      final mapped = const Result<int>.failure(failure).map((v) => v * 3);
      expect(mapped.failureOrNull, failure);
    });

    test('andThen chains and short-circuits on failure', () {
      Result<String> describe(int v) => Result.success('n=$v');
      expect(const Result<int>.success(7).andThen(describe).valueOrNull, 'n=7');
      expect(
        const Result<int>.failure(failure).andThen(describe).failureOrNull,
        failure,
      );
    });
  });

  group('Failure equality', () {
    test('same type and content are equal (Equatable)', () {
      expect(const DatabaseFailure('x'), const DatabaseFailure('x'));
      expect(
        const ValidationFailure(field: 'height_cm', reason: 'must be > 0'),
        const ValidationFailure(field: 'height_cm', reason: 'must be > 0'),
      );
      expect(
        const NotFoundFailure(entity: 'FoodEntry', id: 'abc'),
        isNot(const NotFoundFailure(entity: 'FoodEntry', id: 'def')),
      );
    });

    test('ValidationFailure carries field and reason', () {
      const f = ValidationFailure(field: 'weight_kg', reason: 'missing');
      expect(f.field, 'weight_kg');
      expect(f.reason, 'missing');
      expect(f.message, contains('weight_kg'));
    });

    test('BackupFailure carries the failing stage', () {
      const f = BackupFailure(stage: 'encrypt');
      expect(f.stage, 'encrypt');
      expect(f.message, contains('encrypt'));
    });
  });
}
