import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Log severity levels for [AppLogger].
enum LogLevel {
  /// Verbose diagnostic detail (debug builds only).
  debug,

  /// Normal operational events.
  info,

  /// Unexpected but recoverable situations.
  warning,

  /// Failures that were surfaced or swallowed intentionally.
  error,
}

/// Local-only logging abstraction.
///
/// Rules (docs/03-architecture.md §5, docs/13 §9):
/// - No PII in log messages, ever.
/// - No network sinks, ever — logs stay on the device.
/// - Verbose in debug, minimal in release.
abstract interface class AppLogger {
  /// Logs [message] at [level], with an optional [error] and [stackTrace].
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Convenience for [LogLevel.debug].
  void debug(String message) => log(LogLevel.debug, message);

  /// Convenience for [LogLevel.info].
  void info(String message) => log(LogLevel.info, message);

  /// Convenience for [LogLevel.warning].
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);

  /// Convenience for [LogLevel.error].
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

/// Default [AppLogger]: writes to the developer console.
///
/// Debug-level messages are dropped in release builds; nothing is ever sent
/// off-device.
class ConsoleLogger implements AppLogger {
  /// Creates a console logger.
  const ConsoleLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == LogLevel.debug && kReleaseMode) return;
    developer.log(
      message,
      name: 'LifeLedger',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message) => log(LogLevel.debug, message);

  @override
  void info(String message) => log(LogLevel.info, message);

  @override
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}
