import 'package:vektorkite/features/auth/domain/app_user_role.dart';

abstract class UserRoleRepository {
  Future<AppUserRole> fetchCurrentUserRole();
}
