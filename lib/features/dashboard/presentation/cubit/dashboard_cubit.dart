import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';

/// Dashboard states (docs/08 F10).
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Loading the summary (dashboard shows skeletons, docs/05 §6).
final class DashboardLoading extends DashboardState {
  /// Creates the loading state.
  const DashboardLoading();
}

/// The assembled at-a-glance summary.
final class DashboardLoaded extends DashboardState {
  /// Creates the loaded state.
  const DashboardLoaded(this.summary);

  /// The day's summary.
  final DailySummary summary;

  @override
  List<Object?> get props => [summary];
}

/// A metric failed to load; a retry chip is shown (docs/08 F10).
final class DashboardError extends DashboardState {
  /// Creates the error state.
  const DashboardError(this.failure);

  /// What went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Loads and refreshes the dashboard summary (docs/08 F10).
class DashboardCubit extends Cubit<DashboardState> {
  /// Creates the cubit.
  DashboardCubit({
    required GetDailySummary getDailySummary,
    required String userId,
  }) : _getDailySummary = getDailySummary,
       _userId = userId,
       super(const DashboardLoading());

  final GetDailySummary _getDailySummary;
  final String _userId;

  /// Loads today's summary.
  Future<void> load() async {
    emit(const DashboardLoading());
    final result = await _getDailySummary(userId: _userId);
    result.fold(
      (failure) => emit(DashboardError(failure)),
      (summary) => emit(DashboardLoaded(summary)),
    );
  }

  /// Refreshes without a full loading flash (after logging returns).
  Future<void> refresh() async {
    final result = await _getDailySummary(userId: _userId);
    result.fold(
      (failure) => emit(DashboardError(failure)),
      (summary) => emit(DashboardLoaded(summary)),
    );
  }
}
