import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/profile/application/profile_state.dart';
import 'package:vektorkite/features/profile/data/appsync_profile_repository.dart';
import 'package:vektorkite/features/profile/domain/customer_profile.dart';
import 'package:vektorkite/features/profile/domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => const AppSyncProfileRepository(),
);

final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(ref.read(profileRepositoryProvider)),
);

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.fetchCurrentProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load profile',
        name: 'Profile',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load profile.',
        ),
      );
    }
  }

  Future<CustomerProfile?> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String addressText,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.saveProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        addressText: addressText,
      );
      state = state.copyWith(isSaving: false, profile: saved);
      return saved;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save profile',
        name: 'Profile',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to save profile.',
        ),
      );
      return null;
    }
  }

  Future<CustomerProfile?> uploadAvatar(String filePath) async {
    final current = state.profile;
    if (current == null) return null;

    state = state.copyWith(isUploadingAvatar: true, clearError: true);
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final key = await _repository.uploadAvatar(
        userId: user.userId,
        filePath: filePath,
      );
      final saved = await _repository.saveProfile(
        firstName: current.firstName,
        lastName: current.lastName,
        phone: current.phone ?? '',
        addressText: current.addressText ?? '',
        avatarKey: key,
      );
      state = state.copyWith(
        isUploadingAvatar: false,
        profile: saved,
      );
      return saved;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to upload avatar',
        name: 'Profile',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to upload profile photo.',
        ),
      );
      return null;
    }
  }
}
