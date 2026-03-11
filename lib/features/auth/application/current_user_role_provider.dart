import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/features/auth/data/appsync_user_role_repository.dart';
import 'package:vektorkite/features/auth/domain/app_user_role.dart';
import 'package:vektorkite/features/auth/domain/user_role_repository.dart';

final userRoleRepositoryProvider = Provider<UserRoleRepository>(
  (ref) => const AppSyncUserRoleRepository(),
);

final currentUserRoleProvider = FutureProvider<AppUserRole>((ref) async {
  return ref.read(userRoleRepositoryProvider).fetchCurrentUserRole();
});
