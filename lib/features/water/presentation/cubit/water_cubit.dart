import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';

/// Water tracker state (docs/08 F4): today's total in ml.
class WaterState extends Equatable {
  /// Creates a state.
  const WaterState({this.totalMl = 0, this.loading = true});

  /// Total water logged today (ml).
  final double totalMl;

  /// Whether the day total is loading.
  final bool loading;

  /// Copy with updates.
  WaterState copyWith({double? totalMl, bool? loading}) => WaterState(
    totalMl: totalMl ?? this.totalMl,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [totalMl, loading];
}

/// One-tap water logging (docs/08 F4). Optimistic-friendly: the increment is
/// tiny and the total refreshes from the aggregate query.
class WaterCubit extends Cubit<WaterState> {
  /// Creates the cubit.
  WaterCubit({
    required WaterRepository repository,
    required Clock clock,
    required String userId,
  }) : _repository = repository,
       _clock = clock,
       _userId = userId,
       super(const WaterState());

  final WaterRepository _repository;
  final Clock _clock;
  final String _userId;

  /// Default increment (ml) for the one-tap chip (docs/05 §5.1).
  static const double defaultIncrementMl = 250;

  /// Loads today's total.
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _repository.totalForDate(_userId, _clock.localDate());
    emit(WaterState(totalMl: result.valueOrNull ?? 0, loading: false));
  }

  /// Adds [amountMl] (default one increment) and updates the total.
  Future<void> add([double amountMl = defaultIncrementMl]) async {
    final result = await _repository.addWater(
      userId: _userId,
      amountMl: amountMl,
    );
    if (result.valueOrNull case final total?) {
      emit(state.copyWith(totalMl: total, loading: false));
    }
  }
}
