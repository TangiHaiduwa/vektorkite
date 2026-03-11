import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/auth/application/auth_state.dart';
import 'package:vektorkite/features/auth/data/amplify_auth_repository.dart';
import 'package:vektorkite/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AmplifyAuthRepository(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    authRepository: ref.read(authRepositoryProvider),
  ),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository,
       super(const AuthState(status: AuthStatus.unknown));

  final AuthRepository _authRepository;

  Future<void> bootstrap() async {
    state = state.copyWith(
      status: AuthStatus.loading,
      isBusy: true,
      clearError: true,
    );
    try {
      final signedIn = await _authRepository.isSignedIn();
      if (!signedIn) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isBusy: false,
        );
        return;
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isBusy: false,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Auth bootstrap failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isBusy: false,
      );
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _authRepository.signIn(
        email: email,
        password: password,
      );
      if (!result.success) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isBusy: false,
          errorMessage: 'Sign in not completed.',
          pendingEmail: email,
        );
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isBusy: false,
        pendingEmail: email,
      );
      return true;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Sign in failed', error: error, stackTrace: stackTrace);
      if (error.runtimeType.toString() == 'UserNotConfirmedException') {
        state = state.copyWith(
          status: AuthStatus.needsConfirmation,
          isBusy: false,
          pendingEmail: email,
          errorMessage: 'Please confirm your email before signing in.',
        );
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isBusy: false,
        errorMessage: error.message,
        pendingEmail: email,
      );
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Sign in failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isBusy: false,
        errorMessage: 'Unable to sign in.',
        pendingEmail: email,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _authRepository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(
        status: result.requiresConfirmation
            ? AuthStatus.needsConfirmation
            : AuthStatus.unauthenticated,
        isBusy: false,
        pendingEmail: email,
      );
      return result.success || result.requiresConfirmation;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Sign up failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(isBusy: false, errorMessage: error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Sign up failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to create account.',
      );
      return false;
    }
  }

  Future<bool> confirmSignUp({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final success = await _authRepository.confirmSignUp(email: email, code: code);
      state = state.copyWith(
        status: success ? AuthStatus.unauthenticated : AuthStatus.needsConfirmation,
        isBusy: false,
        pendingEmail: email,
      );
      return success;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Confirm failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(isBusy: false, errorMessage: error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Confirm failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to confirm account.',
      );
      return false;
    }
  }

  Future<void> resendCode(String email) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _authRepository.resendSignUpCode(email: email);
      state = state.copyWith(isBusy: false, pendingEmail: email);
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Resend failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(isBusy: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      AppLogger.error('Resend failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to resend code.',
      );
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _authRepository.forgotPassword(email: email);
      state = state.copyWith(isBusy: false, pendingEmail: email);
      return true;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Forgot password failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(isBusy: false, errorMessage: error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Forgot password failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to start password reset.',
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _authRepository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isBusy: false,
        pendingEmail: email,
      );
      return true;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Reset password failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(isBusy: false, errorMessage: error.message);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('Reset password failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to reset password.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _authRepository.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isBusy: false,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Sign out failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to sign out.',
      );
    }
  }
}
