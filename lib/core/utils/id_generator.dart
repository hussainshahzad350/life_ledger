import 'package:uuid/uuid.dart';

/// Produces globally-unique row ids (UUID v4 — docs/04 §2 merge-safe PKs).
///
/// Injected so tests can supply deterministic ids.
abstract interface class IdGenerator {
  /// Returns a new unique id.
  String newId();
}

/// Production UUID v4 generator.
class UuidGenerator implements IdGenerator {
  /// Creates the generator.
  const UuidGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
