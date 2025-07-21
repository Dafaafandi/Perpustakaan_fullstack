class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'member',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isMember => role.toLowerCase() == 'member';
  bool get isVisitor => role.toLowerCase() == 'visitor';
}

enum UserRole { admin, member, visitor }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.member:
        return 'Member';
      case UserRole.visitor:
        return 'Visitor';
    }
  }

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.member:
        return 'member';
      case UserRole.visitor:
        return 'visitor';
    }
  }
}
