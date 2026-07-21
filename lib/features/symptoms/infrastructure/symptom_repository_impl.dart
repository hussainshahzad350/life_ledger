import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [SymptomRepository] over `symptom_entry` +
/// `symptom_type` (docs/04 §4.5/§4.6).
class SymptomRepositoryImpl implements SymptomRepository {
  /// Creates the repository.
  SymptomRepositoryImpl({
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
  Future<Result<List<SymptomType>>> types() async {
    try {
      final rows = await _db.database.query(
        'symptom_type',
        where: 'is_deleted = 0',
        orderBy: 'name',
      );
      return Result.success(
        rows
            .map(
              (r) => SymptomType(
                id: r['id']! as String,
                name: r['name']! as String,
                isCustom: (r['is_custom']! as int) == 1,
              ),
            )
            .toList(),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('symptom types failed', cause: e));
    }
  }

  @override
  Future<Result<SymptomEntry>> add({
    required String userId,
    required String symptomTypeId,
    required int severity,
    String? note,
  }) async {
    if (severity < 1 || severity > 5) {
      return const Result.failure(
        ValidationFailure(field: 'severity', reason: 'must be 1..5'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final id = _ids.newId();
      await _db.database.insert('symptom_entry', <String, Object?>{
        'id': id,
        'user_id': userId,
        'symptom_type_id': symptomTypeId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': _clock.localDate(),
        'severity': severity,
        'note': note,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      final list = await forDate(userId, _clock.localDate());
      return list.map((entries) => entries.firstWhere((e) => e.id == id));
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('symptom write failed', cause: e));
    }
  }

  @override
  Future<Result<List<SymptomEntry>>> forDate(
    String userId,
    String localDate,
  ) async {
    try {
      final rows = await _db.database.rawQuery(
        '''
        SELECT se.id AS id, se.user_id AS user_id, se.severity AS severity,
               se.note AS note, se.logged_at AS logged_at,
               se.local_date AS local_date,
               st.id AS type_id, st.name AS type_name,
               st.is_custom AS type_custom
        FROM symptom_entry se
        JOIN symptom_type st ON st.id = se.symptom_type_id
        WHERE se.user_id = ? AND se.local_date = ? AND se.is_deleted = 0
        ORDER BY se.logged_at DESC, se.rowid DESC
        ''',
        [userId, localDate],
      );
      return Result.success(
        rows
            .map(
              (r) => SymptomEntry(
                id: r['id']! as String,
                userId: r['user_id']! as String,
                severity: r['severity']! as int,
                note: r['note'] as String?,
                loggedAt: DateTime.fromMillisecondsSinceEpoch(
                  r['logged_at']! as int,
                  isUtc: true,
                ),
                localDate: r['local_date']! as String,
                type: SymptomType(
                  id: r['type_id']! as String,
                  name: r['type_name']! as String,
                  isCustom: (r['type_custom']! as int) == 1,
                ),
              ),
            )
            .toList(),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('symptom read failed', cause: e));
    }
  }
}
