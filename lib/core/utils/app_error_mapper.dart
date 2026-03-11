import 'package:amplify_flutter/amplify_flutter.dart';

class AppErrorMapper {
  const AppErrorMapper._();

  static String toUserMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is AuthException) {
      return _mapAuthException(error, fallback: fallback);
    }

    final raw = error.toString().toLowerCase();

    if (_containsAny(raw, const ['network', 'socket', 'connection refused'])) {
      return 'No internet connection. Check your network and try again.';
    }
    if (_containsAny(raw, const ['timed out', 'timeout'])) {
      return 'The request timed out. Please try again.';
    }
    if (_containsAny(raw, const ['not authorized', 'unauthorized', 'forbidden'])) {
      return 'Your session is not authorized for this action. Please sign in again.';
    }
    if (_containsAny(raw, const ['rate exceeded', 'too many requests'])) {
      return 'Too many requests right now. Please wait and retry.';
    }
    if (_containsAny(raw, const ['storage is not configured', 'storage plugin'])) {
      return 'Storage is not configured yet. Complete Amplify storage setup and retry.';
    }
    if (_containsAny(raw, const ['validation', 'invalid'])) {
      return 'Some input is invalid. Review your details and try again.';
    }
    if (_containsAny(raw, const ['service unavailable', 'internal server error'])) {
      return 'Service is temporarily unavailable. Please retry shortly.';
    }

    return fallback;
  }

  static String _mapAuthException(
    AuthException error, {
    required String fallback,
  }) {
    final name = error.runtimeType.toString().toLowerCase();
    final message = error.message.toLowerCase();

    if (_containsAny(name, const ['usernotfound']) ||
        _containsAny(message, const ['user does not exist'])) {
      return 'Account not found. Check your email or create a new account.';
    }
    if (_containsAny(name, const ['notauthorized']) ||
        _containsAny(message, const ['incorrect username or password'])) {
      return 'Incorrect email or password.';
    }
    if (_containsAny(name, const ['usernotconfirmed'])) {
      return 'Please confirm your email before signing in.';
    }
    if (_containsAny(name, const ['code', 'verification']) &&
        _containsAny(message, const ['expired'])) {
      return 'Confirmation code expired. Request a new code.';
    }
    if (_containsAny(name, const ['code', 'verification']) &&
        _containsAny(message, const ['invalid', 'mismatch'])) {
      return 'Invalid confirmation code. Check and try again.';
    }
    if (_containsAny(message, const ['password'])) {
      return 'Password does not meet security requirements.';
    }
    if (_containsAny(name, const ['limitexceeded']) ||
        _containsAny(message, const ['attempts exceeded'])) {
      return 'Too many attempts. Wait a moment before trying again.';
    }
    if (_containsAny(message, const ['network', 'socket', 'timeout'])) {
      return 'Network issue while contacting authentication service.';
    }

    return fallback;
  }

  static bool _containsAny(String source, List<String> patterns) {
    for (final pattern in patterns) {
      if (source.contains(pattern)) return true;
    }
    return false;
  }
}
