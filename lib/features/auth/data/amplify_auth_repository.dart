import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/auth/domain/auth_repository.dart';

class AmplifyAuthRepository implements AuthRepository {
  const AmplifyAuthRepository();

  @override
  Future<bool> isSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    return AuthActionResult(success: result.isSignedIn);
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final result = await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email,
          AuthUserAttributeKey.givenName: firstName,
          AuthUserAttributeKey.familyName: lastName,
        },
      ),
    );
    return AuthActionResult(
      success: result.isSignUpComplete,
      requiresConfirmation: !result.isSignUpComplete,
    );
  }

  @override
  Future<bool> confirmSignUp({
    required String email,
    required String code,
  }) async {
    final result = await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
    return result.isSignUpComplete;
  }

  @override
  Future<void> resendSignUpCode({required String email}) async {
    await Amplify.Auth.resendSignUpCode(username: email);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Amplify.Auth.resetPassword(username: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Amplify.Auth.confirmResetPassword(
      username: email,
      confirmationCode: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }
}
