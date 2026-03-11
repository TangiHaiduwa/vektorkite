import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:vektorkite/features/auth/domain/app_user_role.dart';
import 'package:vektorkite/features/profile/domain/customer_profile.dart';
import 'package:vektorkite/features/profile/domain/profile_repository.dart';

class AppSyncProfileRepository implements ProfileRepository {
  const AppSyncProfileRepository();

  static const String _getUserProfileQuery = r'''
query GetUserProfile($id: ID!) {
  getUserProfile(id: $id) {
    id
    firstName
    lastName
    email
    phone
    addressText
    avatarKey
    role
    isActive
  }
}
''';

  static const String _createUserProfileMutation = r'''
mutation CreateUserProfile($input: CreateUserProfileInput!) {
  createUserProfile(input: $input) {
    id
    firstName
    lastName
    email
    phone
    addressText
    avatarKey
    role
    isActive
  }
}
''';

  static const String _updateUserProfileMutation = r'''
mutation UpdateUserProfile($input: UpdateUserProfileInput!) {
  updateUserProfile(input: $input) {
    id
    firstName
    lastName
    email
    phone
    addressText
    avatarKey
    role
    isActive
  }
}
''';

  static const String _repairRoleMutation = r'''
mutation RepairUserProfileRole($input: UpdateUserProfileInput!) {
  updateUserProfile(input: $input) {
    id
    role
  }
}
''';

  @override
  Future<CustomerProfile> fetchCurrentProfile() async {
    final user = await Amplify.Auth.getCurrentUser();
    final existing = await _fetchById(user.userId);
    if (existing != null) {
      final avatarUrl = await resolveAvatarUrl(existing.avatarKey);
      return existing.copyWith(avatarUrl: avatarUrl);
    }

    final attrs = await Amplify.Auth.fetchUserAttributes();
    final attrMap = <String, String>{
      for (final attribute in attrs) attribute.userAttributeKey.key: attribute.value,
    };

    final firstName = _normalize(attrMap['given_name']) ?? 'Customer';
    final lastName = _normalize(attrMap['family_name']) ?? 'User';
    final email = _normalize(attrMap['email']) ?? '';

    final created = await _mutateProfile(
      create: true,
      input: {
        'id': user.userId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': _normalize(attrMap['phone_number']),
        'role': appUserRoleToApi(AppUserRole.customer),
        'isActive': true,
      },
    );
    final avatarUrl = await resolveAvatarUrl(created.avatarKey);
    return created.copyWith(avatarUrl: avatarUrl);
  }

  @override
  Future<CustomerProfile> saveProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String addressText,
    String? avatarKey,
  }) async {
    final user = await Amplify.Auth.getCurrentUser();
    final existing = await _fetchById(user.userId);
    final attrs = await Amplify.Auth.fetchUserAttributes();
    final attrMap = <String, String>{
      for (final attribute in attrs) attribute.userAttributeKey.key: attribute.value,
    };

    final input = <String, dynamic>{
      'id': user.userId,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': _normalize(attrMap['email']) ?? '',
      'phone': phone.trim().isEmpty ? null : phone.trim(),
      'addressText': addressText.trim().isEmpty ? null : addressText.trim(),
      'avatarKey': avatarKey ?? existing?.avatarKey,
      'role': appUserRoleToApi(existing?.role ?? AppUserRole.customer),
      'isActive': true,
    };

    final saved = await _mutateProfile(create: existing == null, input: input);
    final avatarUrl = await resolveAvatarUrl(saved.avatarKey);
    return saved.copyWith(avatarUrl: avatarUrl);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    final extensionIndex = filePath.lastIndexOf('.');
    final extension = extensionIndex >= 0
        ? filePath.substring(extensionIndex).toLowerCase()
        : '';
    final safeExt = extension.isEmpty ? '.jpg' : extension;
    final key = 'user_profiles/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    try {
      await Amplify.Storage.uploadFile(
        path: StoragePath.fromString(key),
        localFile: AWSFile.fromPath(filePath),
        options: const StorageUploadFileOptions(
          pluginOptions: S3UploadFilePluginOptions(
            getProperties: true,
          ),
        ),
      ).result;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('storage') && message.contains('not') && message.contains('configured')) {
        throw Exception('Storage is not configured. Run "amplify add storage" then "amplify push".');
      }
      rethrow;
    }
    return key;
  }

  @override
  Future<String?> resolveAvatarUrl(String? avatarKey) async {
    if (avatarKey == null || avatarKey.trim().isEmpty) return null;
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(avatarKey),
        options: const StorageGetUrlOptions(),
      ).result;
      return result.url.toString();
    } catch (_) {
      return null;
    }
  }

  Future<CustomerProfile?> _fetchById(String id) async {
    final request = GraphQLRequest<String>(
      document: _getUserProfileQuery,
      variables: {'id': id},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      final hasMissingRoleError = response.errors.any(
        (error) =>
            error.message.contains("Cannot return null for non-nullable type: 'UserRole'"),
      );
      if (hasMissingRoleError) {
        await _repairMissingRole(id);
        return _fetchByIdAfterRepair(id);
      }
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final data = parsed['getUserProfile'];
    if (data == null || data is! Map<String, dynamic>) return null;
    return _parseProfile(data);
  }

  Future<CustomerProfile?> _fetchByIdAfterRepair(String id) async {
    final retry = GraphQLRequest<String>(
      document: _getUserProfileQuery,
      variables: {'id': id},
    );
    final retryResponse = await Amplify.API.query(request: retry).response;
    if (retryResponse.errors.isNotEmpty) {
      throw Exception(retryResponse.errors.first.message);
    }
    final parsed = jsonDecode(retryResponse.data ?? '{}') as Map<String, dynamic>;
    final data = parsed['getUserProfile'];
    if (data == null || data is! Map<String, dynamic>) return null;
    return _parseProfile(data);
  }

  Future<void> _repairMissingRole(String id) async {
    final request = GraphQLRequest<String>(
      document: _repairRoleMutation,
      variables: {
        'input': {
          'id': id,
          'role': appUserRoleToApi(AppUserRole.customer),
          'isActive': true,
        },
      },
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
  }

  Future<CustomerProfile> _mutateProfile({
    required bool create,
    required Map<String, dynamic> input,
  }) async {
    final request = GraphQLRequest<String>(
      document: create ? _createUserProfileMutation : _updateUserProfileMutation,
      variables: {'input': input},
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final data = parsed[create ? 'createUserProfile' : 'updateUserProfile'];
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Unexpected profile response.');
    }
    return _parseProfile(data);
  }

  CustomerProfile _parseProfile(Map<String, dynamic> json) {
    return CustomerProfile(
      id: (json['id'] as String?) ?? '',
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      addressText: json['addressText'] as String?,
      avatarKey: json['avatarKey'] as String?,
      role: appUserRoleFromApi(json['role'] as String?),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
