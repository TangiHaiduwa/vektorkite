import 'package:vektorkite/features/auth/domain/app_user_role.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.addressText,
    this.avatarKey,
    this.avatarUrl,
    this.role = AppUserRole.customer,
    this.isActive = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? addressText;
  final String? avatarKey;
  final String? avatarUrl;
  final AppUserRole role;
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();

  CustomerProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? addressText,
    String? avatarKey,
    String? avatarUrl,
    AppUserRole? role,
    bool? isActive,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      addressText: addressText ?? this.addressText,
      avatarKey: avatarKey ?? this.avatarKey,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
