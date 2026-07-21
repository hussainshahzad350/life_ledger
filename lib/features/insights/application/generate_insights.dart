import 'package:life_ledger/core/ai/insight_engine.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';

/// Runs the Phase-1 insight engine over the user's data and persists the
/// accepted results (docs/07, docs/08 F11).
///
/// The engine itself is pure; this use case supplies its input (via the
/// [InsightContextGateway]) and its output sink (the [InsightRepository]),
/// keeping the safety filter and idempotent storage rules in one place. Engine
/// failures never surface to the user as a crash — the caller logs and moves on
/// (docs/08 F11 errors).
class GenerateInsights {
  /// Creates the use case.
  GenerateInsights({
    required InsightContextGateway gateway,
    required InsightRepository repository,
    InsightEngine? engine,
  }) : _gateway = gateway,
       _repository = repository,
       _engine = engine ?? InsightEngine.standard();

  final InsightContextGateway _gateway;
  final InsightRepository _repository;
  final InsightEngine _engine;

  /// Regenerates insights for [userId] and returns the count now stored.
  Future<Result<int>> call(String userId) async {
    final contextResult = await _gateway.buildContext(userId);
    final context = contextResult.valueOrNull;
    if (context == null) {
      return Result.failure(contextResult.failureOrNull!);
    }
    final safety = _engine.run(context);
    final saved = await _repository.save(userId, safety.accepted);
    return saved.map((_) => safety.accepted.length);
  }
}
