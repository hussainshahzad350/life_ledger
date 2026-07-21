import 'package:life_ledger/core/error/result.dart';

/// The tables a backup covers, ordered parents → children so imports satisfy
/// foreign keys and wipes reverse cleanly (docs/04 §8, docs/08 F14).
const List<String> kBackupTables = [
  'user_profile',
  'food_item',
  'symptom_type',
  'goal',
  'food_entry',
  'water_entry',
  'weight_entry',
  'sleep_entry',
  'mood_entry',
  'symptom_entry',
  'exercise_entry',
  'insight',
  'app_meta',
];

/// The backup format version. Bumped when the on-disk shape changes; an import
/// refuses a document newer than the running app (docs/08 F14 validation).
const int kBackupFormatVersion = 1;

/// Outcome of an import (docs/08 F14): how many rows were written and whether
/// the document had to migrate on restore.
class ImportResult {
  /// Creates a result.
  const ImportResult({required this.rowsWritten, required this.migrated});

  /// Total rows upserted across all tables.
  final int rowsWritten;

  /// Whether the document's format version was older than the app's.
  final bool migrated;
}

/// Data ownership operations (docs/08 F14, FR-36–39): a versioned, encrypted
/// backup and a plain JSON/CSV export the user fully controls.
abstract interface class DataRepository {
  /// Serializes every backup table to a versioned JSON document (unencrypted;
  /// callers wrap it with a [BackupCipher] before it leaves the device).
  Future<Result<String>> exportJson();

  /// Restores a JSON document produced by [exportJson], upserting by primary
  /// key so re-importing the same file is idempotent (FR-39). Refuses a
  /// document newer than [kBackupFormatVersion].
  Future<Result<ImportResult>> importJson(String json);

  /// Hard-deletes all user data (docs/04 §8). Irreversible; the UI gates this
  /// behind a typed confirmation.
  Future<Result<void>> wipeAll();
}

/// The encryption seam for backups (docs/08 F14, docs/13 §10).
///
/// v1 ships an identity codec so the versioned backup/restore round-trip is
/// testable and functional today; the production binding is an Android
/// keystore-backed AES-GCM cipher wired at the platform boundary (a documented
/// hardening task, not faked here).
abstract interface class BackupCipher {
  /// Wraps plaintext backup bytes for storage/transfer.
  String seal(String plaintext);

  /// Reverses [seal].
  String open(String sealed);
}

/// The default pass-through cipher (no encryption). Clearly named so it can
/// never be mistaken for the keystore-backed production cipher.
class IdentityBackupCipher implements BackupCipher {
  /// Creates the identity cipher.
  const IdentityBackupCipher();

  @override
  String seal(String plaintext) => plaintext;

  @override
  String open(String sealed) => sealed;
}
