import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/auth/domain/app_user_role.dart';
import 'package:vektorkite/features/auth/domain/user_role_repository.dart';

class AppSyncUserRoleRepository implements UserRoleRepository {
  const AppSyncUserRoleRepository();

  static const String _getUserProfileRoleQuery = r'''
query GetUserProfileRole($id: ID!) {
  getUserProfile(id: $id) {
    role
  }
}
''';

  @override
  Future<AppUserRole> fetchCurrentUserRole() async {
    final user = await Amplify.Auth.getCurrentUser();
    final request = GraphQLRequest<String>(
      document: _getUserProfileRoleQuery,
      variables: {'id': user.userId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final raw = parsed['getUserProfile'];
    if (raw is! Map<String, dynamic>) {
      return AppUserRole.customer;
    }
    return appUserRoleFromApi(raw['role'] as String?);
  }
}
