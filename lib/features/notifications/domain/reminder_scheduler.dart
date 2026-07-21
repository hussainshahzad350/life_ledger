import 'package:life_ledger/core/error/result.dart';

/// Schedules gentle, local, opt-in reminders (docs/08 F13, FR-34).
///
/// The contract is intentionally tiny and network-free. The production binding
/// uses `flutter_local_notifications` at the platform boundary (a documented
/// platform task, verified on-device); the pure app layer depends only on this
/// interface so reminder logic stays unit-testable off-device.
abstract interface class ReminderScheduler {
  /// Schedules a daily reminder at [hour]:[minute] (local time), replacing any
  /// existing one.
  Future<Result<void>> scheduleDaily({required int hour, required int minute});

  /// Cancels all scheduled reminders.
  Future<Result<void>> cancelAll();
}

/// The default no-op scheduler used until the platform notification binding is
/// wired (docs/08 F13). Enabling reminders is persisted in settings regardless;
/// this keeps the app fully functional and offline without a platform channel.
class NoopReminderScheduler implements ReminderScheduler {
  /// Creates the no-op scheduler.
  const NoopReminderScheduler();

  @override
  Future<Result<void>> scheduleDaily({
    required int hour,
    required int minute,
  }) async => const Result.success(null);

  @override
  Future<Result<void>> cancelAll() async => const Result.success(null);
}
