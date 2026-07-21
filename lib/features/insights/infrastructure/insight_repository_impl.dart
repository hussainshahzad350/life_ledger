import 'dart:convert';

import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [InsightRepository] over `insight` (docs/04 §4.7).
///
/// The `insight` table has no category column, so the rule category is stored
/// alongside the evidence in `evidence_json` (`{category, evidence}`) — one
/// blob, no schema change to the frozen v1 migration. Dates are stored as the
/// day's epoch-ms; feedback and dismissal are the user-owned columns the engine
/// never writes.
class InsightRepositoryImpl implements InsightRepository {
  /// Creates the repository.
  InsightRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required IdGenerator ids,
  }) : _db = db,
       _clock = clock,
       _ids = ids;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<List<InsightRecord>>> active(String userId) async {
    try {
      final rows = await _db.database.query(
        'insight',
        where: 'user_id = ? AND is_deleted = 0 AND dismissed = 0',
        whereArgs: [userId],
        orderBy: 'period_end DESC, rowid DESC',
      );
      return Result.success(rows.map(_fromRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('insight read failed', cause: e));
    }
  }

  @override
  Future<Result<void>> save(
    String userId,
    List<InsightCandidate> accepted,
  ) async {
    try {
      await _db.database.transaction((txn) async {
        final existing = await txn.query(
          'insight',
          where: 'user_id = ? AND is_deleted = 0',
          whereArgs: [userId],
        );
        final byRule = {
          for (final row in existing) row['rule_id']! as String: row,
        };
        final acceptedRuleIds = accepted.map((c) => c.ruleId).toSet();

        // Clear insights whose rule no longer fires — unless the user dismissed
        // them (dismissals are sticky tombstones).
        for (final row in existing) {
          final ruleId = row['rule_id']! as String;
          final dismissed = (row['dismissed']! as int) == 1;
          if (!dismissed && !acceptedRuleIds.contains(ruleId)) {
            await txn.delete(
              'insight',
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        }

        final now = _clock.nowUtc().millisecondsSinceEpoch;
        for (final c in accepted) {
          final row = byRule[c.ruleId];
          if (row != null && (row['dismissed']! as int) == 1) {
            continue; // respect a prior dismissal
          }
          final values = <String, Object?>{
            'rule_id': c.ruleId,
            'title': c.title,
            'body': c.body,
            'confidence': c.confidence.name,
            'evidence_json': jsonEncode({
              'category': c.category.name,
              'evidence': c.evidence,
            }),
            'period_start': _dateMs(c.periodStart),
            'period_end': _dateMs(c.periodEnd),
            'updated_at': now,
          };
          if (row != null) {
            await txn.update(
              'insight',
              values,
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          } else {
            await txn.insert('insight', {
              'id': _ids.newId(),
              'user_id': userId,
              ...values,
              'dismissed': 0,
              'created_at': now,
            });
          }
        }
      });
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('insight save failed', cause: e));
    }
  }

  @override
  Future<Result<void>> setFeedback(
    String insightId,
    InsightFeedback feedback,
  ) async {
    return _update(insightId, {'feedback': feedback.name});
  }

  @override
  Future<Result<void>> dismiss(String insightId) {
    return _update(insightId, {'dismissed': 1});
  }

  Future<Result<void>> _update(String id, Map<String, Object?> values) async {
    try {
      await _db.database.update(
        'insight',
        {...values, 'updated_at': _clock.nowUtc().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('insight update failed', cause: e));
    }
  }

  // Store the calendar day as UTC-midnight epoch-ms so it round-trips to the
  // exact same `YYYY-MM-DD` regardless of the device time zone.
  int _dateMs(String localDate) =>
      DateTime.parse('${localDate}T00:00:00Z').millisecondsSinceEpoch;

  String _dateString(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  InsightRecord _fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(row['evidence_json']! as String) as Map;
    final evidence = (decoded['evidence'] as Map).cast<String, Object?>();
    return InsightRecord(
      id: row['id']! as String,
      ruleId: row['rule_id']! as String,
      category: InsightCategory.values.byName(decoded['category'] as String),
      title: row['title']! as String,
      body: row['body']! as String,
      confidence: Confidence.values.byName(row['confidence']! as String),
      evidence: evidence,
      periodStart: _dateString(row['period_start']! as int),
      periodEnd: _dateString(row['period_end']! as int),
      feedback: row['feedback'] == null
          ? null
          : InsightFeedback.values.byName(row['feedback']! as String),
      dismissed: (row['dismissed']! as int) == 1,
    );
  }
}
