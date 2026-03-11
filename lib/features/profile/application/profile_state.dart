import 'package:vektorkite/features/profile/domain/customer_profile.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
    this.profile,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? errorMessage;
  final CustomerProfile? profile;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingAvatar,
    String? errorMessage,
    CustomerProfile? profile,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      profile: profile ?? this.profile,
    );
  }
}
