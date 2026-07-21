import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';

/// Journal/timeline states (docs/08 F3, docs/05 §5.3).
sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

/// Loading the day.
final class JournalLoading extends JournalState {
  /// Creates the loading state.
  const JournalLoading();
}

/// The day's grouped timeline (possibly empty).
final class JournalLoaded extends JournalState {
  /// Creates the loaded state.
  const JournalLoaded(this.timeline);

  /// The grouped, totaled day.
  final DayTimeline timeline;

  @override
  List<Object?> get props => [timeline.byMeal, timeline.total];
}

/// Loading failed.
final class JournalError extends JournalState {
  /// Creates the error state.
  const JournalError(this.failure);

  /// What went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Loads and manages a day's meal timeline, including soft-delete with Undo
/// (docs/05 §6 — undo over confirm).
class JournalCubit extends Cubit<JournalState> {
  /// Creates the cubit.
  JournalCubit({
    required FoodRepository repository,
    required GetDayTimeline getDayTimeline,
    required Clock clock,
    required String userId,
  }) : _repository = repository,
       _getDayTimeline = getDayTimeline,
       _clock = clock,
       _userId = userId,
       super(const JournalLoading());

  final FoodRepository _repository;
  final GetDayTimeline _getDayTimeline;
  final Clock _clock;
  final String _userId;

  /// Loads [localDate] (defaults to today).
  Future<void> load([String? localDate]) async {
    emit(const JournalLoading());
    final result = await _getDayTimeline(
      userId: _userId,
      localDate: localDate ?? _clock.localDate(),
    );
    result.fold(
      (failure) => emit(JournalError(failure)),
      (timeline) => emit(JournalLoaded(timeline)),
    );
  }

  /// Soft-deletes [entry] and reloads (the Undo path calls [undoDelete]).
  Future<void> delete(FoodEntry entry) async {
    await _repository.deleteEntry(entry.id);
    await load(entry.localDate);
  }

  /// Restores a soft-deleted entry (Undo) and reloads.
  Future<void> undoDelete(FoodEntry entry) async {
    await _repository.restoreEntry(entry.id);
    await load(entry.localDate);
  }
}
