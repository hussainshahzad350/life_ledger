import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:life_ledger/features/water/presentation/cubit/water_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockWaterRepository extends Mock implements WaterRepository {}

void main() {
  late MockWaterRepository repository;

  WaterCubit build() => WaterCubit(
    repository: repository,
    clock: FixedClock(DateTime(2026, 7, 21)),
    userId: 'u1',
  );

  setUp(() => repository = MockWaterRepository());

  group('WaterCubit (docs/08 F4)', () {
    blocTest<WaterCubit, WaterState>(
      'load reads the day total',
      build: () {
        when(
          () => repository.totalForDate('u1', '2026-07-21'),
        ).thenAnswer((_) async => const Result.success(1400));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const WaterState(),
        const WaterState(totalMl: 1400, loading: false),
      ],
    );

    blocTest<WaterCubit, WaterState>(
      'add logs one increment and reflects the new total',
      build: () {
        when(
          () => repository.addWater(userId: 'u1', amountMl: 250),
        ).thenAnswer((_) async => const Result.success(250));
        return build();
      },
      act: (cubit) => cubit.add(),
      expect: () => [const WaterState(totalMl: 250, loading: false)],
      verify: (_) {
        verify(
          () => repository.addWater(userId: 'u1', amountMl: 250),
        ).called(1);
      },
    );
  });
}
