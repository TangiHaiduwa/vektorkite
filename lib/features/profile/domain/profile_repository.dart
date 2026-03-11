import 'package:vektorkite/features/profile/domain/customer_profile.dart';

abstract class ProfileRepository {
  Future<CustomerProfile> fetchCurrentProfile();
  Future<CustomerProfile> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String addressText,
    String? avatarKey,
  });
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  });
  Future<String?> resolveAvatarUrl(String? avatarKey);
}
