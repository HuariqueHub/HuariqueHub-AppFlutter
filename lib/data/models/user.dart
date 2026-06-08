enum UserRole { consumer, owner, admin }

class AppUser {
  final int id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?)?.toLowerCase() ?? 'consumer';
    final role = switch (roleStr) {
      'owner' => UserRole.owner,
      'admin' => UserRole.admin,
      _ => UserRole.consumer,
    };
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
    );
  }
}
