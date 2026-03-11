import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void info(String message, {String name = 'VektorKiteProvider'}) {
    developer.log(message, name: name);
  }

  static void error(
    String message, {
    String name = 'VektorKiteProvider',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}
