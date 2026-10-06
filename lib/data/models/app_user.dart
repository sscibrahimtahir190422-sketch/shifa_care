enum UserRole {
  patient,
  doctor,
  admin;

  static UserRole parse(String? value) {
    switch (value) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: (json['full_name'] as String?) ?? 'Patient',
        email: json['email'] as String?,
        role: UserRole.parse(json['role'] as String?),
      );
}
