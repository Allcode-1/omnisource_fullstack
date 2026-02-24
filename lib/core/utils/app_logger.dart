import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {String name = 'OmniSource'}) {
    developer.log(message, name: name);
  }

  static void warning(String message, {String name = 'OmniSource'}) {
    developer.log(message, name: name, level: 900);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'OmniSource',
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
