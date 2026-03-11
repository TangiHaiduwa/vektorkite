enum AppUserRole {
  customer,
  provider,
}

AppUserRole appUserRoleFromApi(String? value) {
  switch (value?.toUpperCase()) {
    case 'PROVIDER':
      return AppUserRole.provider;
    case 'CUSTOMER':
    default:
      return AppUserRole.customer;
  }
}

String appUserRoleToApi(AppUserRole role) {
  switch (role) {
    case AppUserRole.provider:
      return 'PROVIDER';
    case AppUserRole.customer:
      return 'CUSTOMER';
  }
}
