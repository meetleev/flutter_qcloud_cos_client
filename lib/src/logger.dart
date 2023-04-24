import 'package:flutter/foundation.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warn,
  error,
}

class Log {
  static LogLevel logLevel = LogLevel.warn;

  static v(Object message) {
    _log(LogLevel.verbose, message);
  }

  static d(Object message) {
    if (logLevel.index <= LogLevel.debug.index) {
      _log(LogLevel.debug, message);
    }
  }

  static i(Object message) {
    if (logLevel.index <= LogLevel.info.index) {
      _log(LogLevel.info, message);
    }
  }

  static w(Object message) {
    if (logLevel.index <= LogLevel.warn.index) {
      _log(LogLevel.warn, message);
    }
  }

  static e(Object message, {required Error error, StackTrace? stackTrace}) {
    if (logLevel.index <= LogLevel.error.index) {
      _log(LogLevel.error, message, error, stackTrace);
    }
  }

  static void _log(LogLevel logLevel, Object message,
      [Error? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('${logLevel.name} $message');
    }
    if (null != error) Future.error(error, stackTrace);
  }
}
