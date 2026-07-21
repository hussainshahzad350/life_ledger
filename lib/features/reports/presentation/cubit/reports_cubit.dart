import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';

/// State for the Reports page (docs/08 F12).
class ReportsState extends Equatable {
  /// Creates a state.
  const ReportsState({
    this.range = ReportRange.week,
    this.summary,
    this.loading = true,
    this.error = false,
  });

  /// The selected range.
  final ReportRange range;

  /// The loaded report, or null while loading/on error.
  final ReportSummary? summary;

  /// Whether a load is in flight.
  final bool loading;

  /// Whether the last load failed.
  final bool error;

  /// Copy with updates.
  ReportsState copyWith({
    ReportRange? range,
    ReportSummary? summary,
    bool? loading,
    bool? error,
  }) {
    return ReportsState(
      range: range ?? this.range,
      summary: summary ?? this.summary,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [range, summary, loading, error];
}

/// Loads report summaries and switches the range (docs/08 F12).
class ReportsCubit extends Cubit<ReportsState> {
  /// Creates the cubit.
  ReportsCubit({required ReportRepository repository, required String userId})
    : _repository = repository,
      _userId = userId,
      super(const ReportsState());

  final ReportRepository _repository;
  final String _userId;

  /// Loads the report for the current (or given) range.
  Future<void> load([ReportRange? range]) async {
    final target = range ?? state.range;
    emit(state.copyWith(range: target, loading: true, error: false));
    final result = await _repository.summary(userId: _userId, range: target);
    emit(
      ReportsState(
        range: target,
        summary: result.valueOrNull,
        loading: false,
        error: result.isFailure,
      ),
    );
  }

  /// Switches to [range] and reloads.
  Future<void> setRange(ReportRange range) => load(range);
}
