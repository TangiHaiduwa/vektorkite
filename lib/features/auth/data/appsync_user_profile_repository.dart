import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/auth/domain/user_profile_repository.dart';

class AppSyncUserProfileRepository implements UserProfileRepository {
  const AppSyncUserProfileRepository();

  static const String _getUserProfileQuery = r'''
query GetUserProfile($id: ID!) {
  getUserProfile(id: $id) {
    id
  }
}
''';

  static const String _createUserProfileMutation = r'''
mutation CreateUserProfile($input: CreateUserProfileInput!) {
  createUserProfile(input: $input) {
    id
  }
}
''';

  static const String _updateUserProfileMutation = r'''
mutation UpdateUserProfile($input: UpdateUserProfileInput!) {
  updateUserProfile(input: $input) {
    id
  }
}
''';

  @override
  Future<void> upsertCurrentUserProfile() async {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    final attrMap = <String, String>{
      for (final attribute in attributes)
        attribute.userAttributeKey.key: attribute.value,
    };

    final userId = attrMap['sub'];
    final email = attrMap['email'];
    final givenName = _normalize(attrMap['given_name']);
    final familyName = _normalize(attrMap['family_name']);

    if (userId == null || userId.isEmpty) {
      throw Exception('Missing Cognito sub attribute.');
    }
    if (email == null || email.isEmpty) {
      throw Exception('Missing Cognito email attribute.');
    }
    final resolvedFirstName = givenName ?? _deriveFirstName(email);
    final resolvedLastName = familyName ?? _deriveLastName();

    await _ensureCognitoNameAttributes(
      currentGivenName: givenName,
      currentFamilyName: familyName,
      resolvedFirstName: resolvedFirstName,
      resolvedLastName: resolvedLastName,
    );

    final getRequest = GraphQLRequest<String>(
      document: _getUserProfileQuery,
      variables: {'id': userId},
    );

    final getResponse = await Amplify.API.query(request: getRequest).response;
    if (getResponse.errors.isNotEmpty) {
      throw Exception(getResponse.errors.first.message);
    }

    final parsed = jsonDecode(getResponse.data ?? '{}') as Map<String, dynamic>;
    final exists = parsed['getUserProfile'] != null;
    final input = <String, dynamic>{
      'id': userId,
      'firstName': resolvedFirstName,
      'lastName': resolvedLastName,
      'email': email,
      if (!exists) 'role': 'CUSTOMER',
      'isActive': true,
    };
    final request = GraphQLRequest<String>(
      document: exists
          ? _updateUserProfileMutation
          : _createUserProfileMutation,
      variables: {'input': input},
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _deriveFirstName(String email) {
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Customer' : localPart;
  }

  String _deriveLastName() {
    return 'User';
  }

  Future<void> _ensureCognitoNameAttributes({
    required String? currentGivenName,
    required String? currentFamilyName,
    required String resolvedFirstName,
    required String resolvedLastName,
  }) async {
    final attributesToUpdate = <AuthUserAttribute>[];
    if (currentGivenName == null) {
      attributesToUpdate.add(
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.givenName,
          value: resolvedFirstName,
        ),
      );
    }
    if (currentFamilyName == null) {
      attributesToUpdate.add(
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.familyName,
          value: resolvedLastName,
        ),
      );
    }

    if (attributesToUpdate.isEmpty) return;

    try {
      await Amplify.Auth.updateUserAttributes(attributes: attributesToUpdate);
    } on AuthException {
      // Non-fatal; AppSync persistence still uses resolved values.
    }
  }
}
