enum AuthStatus {
  unknown,
  loading,
  unauthenticated,
  needsConfirmation,
  authenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.isBusy = false,
    this.errorMessage,
    this.pendingEmail,
  });

  final AuthStatus status;
  final bool isBusy;
  final String? errorMessage;
  final String? pendingEmail;

  AuthState copyWith({
    AuthStatus? status,
    bool? isBusy,
    String? errorMessage,
    String? pendingEmail,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}
