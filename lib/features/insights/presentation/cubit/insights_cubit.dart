import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';

/// State for the Insights page (docs/08 F11).
class InsightsState extends Equatable {
  /// Creates a state.
  const InsightsState({
    this.insights = const [],
    this.loading = true,
    this.error = false,
  });

  /// The active (non-dismissed) insights, newest period first.
  final List<InsightRecord> insights;

  /// Whether a load/generation is in flight.
  final bool loading;

  /// Whether the last load failed.
  final bool error;

  /// Copy with updates.
  InsightsState copyWith({
    List<InsightRecord>? insights,
    bool? loading,
    bool? error,
  }) {
    return InsightsState(
      insights: insights ?? this.insights,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [insights, loading, error];
}

/// Generates, lists, and reacts to insights (docs/08 F11).
class InsightsCubit extends Cubit<InsightsState> {
  /// Creates the cubit.
  InsightsCubit({
    required GenerateInsights generate,
    required InsightRepository repository,
    required String userId,
  }) : _generate = generate,
       _repository = repository,
       _userId = userId,
       super(const InsightsState());

  final GenerateInsights _generate;
  final InsightRepository _repository;
  final String _userId;

  /// Regenerates insights, then loads the active list. A generation failure is
  /// non-fatal — the last stored insights still show (docs/08 F11 errors).
  Future<void> load() async {
    emit(state.copyWith(loading: true, error: false));
    await _generate(_userId);
    final result = await _repository.active(_userId);
    emit(
      InsightsState(
        insights: result.valueOrNull ?? const [],
        loading: false,
        error: result.isFailure,
      ),
    );
  }

  /// Records [feedback] on an insight and refreshes the list.
  Future<void> giveFeedback(String insightId, InsightFeedback feedback) async {
    await _repository.setFeedback(insightId, feedback);
    await _reload();
  }

  /// Dismisses an insight and refreshes the list.
  Future<void> dismiss(String insightId) async {
    await _repository.dismiss(insightId);
    await _reload();
  }

  Future<void> _reload() async {
    final result = await _repository.active(_userId);
    emit(
      state.copyWith(
        insights: result.valueOrNull ?? const [],
        error: result.isFailure,
      ),
    );
  }
}
