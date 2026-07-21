/// Time abstraction for the whole app.
///
/// Domain and application code never call `DateTime.now()` directly — they
/// depend on a [Clock] so day-boundary logic is deterministic and testable
/// (docs/03-architecture.md §5, docs/11 §5).
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();

  /// The current instant in the device's local time zone.
  DateTime nowLocal();

  /// The user's current local calendar date as `YYYY-MM-DD`.
  ///
  /// This is the canonical value stamped into every log row's `local_date`
  /// column at write time, making day-grouping a fast, timezone-safe indexed
  /// comparison (docs/04-database-design.md §4.4).
  String localDate() => formatLocalDate(nowLocal());

  /// Formats any [dateTime] as a `YYYY-MM-DD` local-date string.
  static String formatLocalDate(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

/// Production [Clock] backed by the system time.
class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime nowLocal() => DateTime.now();

  @override
  String localDate() => Clock.formatLocalDate(nowLocal());
}

/// Deterministic [Clock] for tests: always returns [fixed].
class FixedClock implements Clock {
  /// Creates a clock frozen at [fixed].
  const FixedClock(this.fixed);

  /// The frozen instant this clock reports.
  final DateTime fixed;

  @override
  DateTime nowUtc() => fixed.toUtc();

  @override
  DateTime nowLocal() => fixed.isUtc ? fixed.toLocal() : fixed;

  @override
  String localDate() => Clock.formatLocalDate(nowLocal());
}
