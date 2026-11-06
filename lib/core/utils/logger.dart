import 'dart:developer' as dev;

import 'package:zedu/core/core.dart';

/// Log level severity, aligned with java.util.logging integers used by dart:developer.
enum LogLevel {
  verbose(300),
  debug(500),
  info(800),
  warning(900),
  error(1000),
  fatal(1200);

  const LogLevel(this.value);
  final int value;
}

/// Project-wide static logger backed by dart:developer.
///
/// In release builds, levels below [LogLevel.warning] are suppressed.
/// ANSI color formatting is applied only in debug builds.
///
/// Output appears in the Flutter DevTools "Logging" tab (not the Debug Console).
///
/// Usage:
///   AppLogger.d('Fetching tasks');
///   AppLogger.e('Login failed', tag: 'AuthNotifier', error: e, stackTrace: st);
abstract final class AppLogger {
  AppLogger._();

  /// Recent log entries kept in memory so diagnostics export can include them.
  static const int _bufferCapacity = 2000;
  static final List<_LogEntry> _buffer = [];

  /// The most recent entries, oldest first, formatted one per line.
  static String logDump() => _buffer.map((e) => e.render()).join('\n');

  static void v(String message, {String? tag}) =>
      _log(LogLevel.verbose, message, tag: tag);

  static void d(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void i(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.warning,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void f(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _log(
    LogLevel.fatal,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode && level.value < LogLevel.warning.value) return;

    final time = DateTime.now();
    _buffer.add(
      _LogEntry(
        level: level,
        time: time,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
    if (_buffer.length > _bufferCapacity) {
      _buffer.removeRange(0, _buffer.length - _bufferCapacity);
    }

    dev.log(
      kDebugMode ? '${_prefix(level)}$message\x1B[0m' : message,
      name: tag ?? 'AppLogger',
      level: level.value,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  static String _prefix(LogLevel level) => switch (level) {
    LogLevel.verbose => '\x1B[37m[V] ', // grey
    LogLevel.debug => '\x1B[36m[D] ', // cyan
    LogLevel.info => '\x1B[32m[I] ', // green
    LogLevel.warning => '\x1B[33m[W] ', // yellow
    LogLevel.error => '\x1B[31m[E] ', // red
    LogLevel.fatal => '\x1B[1;31m[F] ', // bold bright red
  };
}

class _LogEntry {
  _LogEntry({
    required this.level,
    required this.time,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final DateTime time;
  final String? tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  String render() {
    final buffer = StringBuffer(
      '${time.toIso8601String()} [${level.name.toUpperCase()}] '
      '${tag ?? 'AppLogger'}: $message',
    );
    if (error != null) buffer.write('\n  error: $error');
    if (stackTrace != null) buffer.write('\n  stack: $stackTrace');
    return buffer.toString();
  }
}
