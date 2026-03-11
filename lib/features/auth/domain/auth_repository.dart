class AuthActionResult {
  const AuthActionResult({
    required this.success,
    this.requiresConfirmation = false,
  });

  final bool success;
  final bool requiresConfirmation;
}

abstract class AuthRepository {
  Future<bool> isSignedIn();
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  });
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<bool> confirmSignUp({
    required String email,
    required String code,
  });
  Future<void> resendSignUpCode({required String email});
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<void> signOut();
}
