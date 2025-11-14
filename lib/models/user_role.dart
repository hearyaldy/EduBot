/// User roles for the application
enum UserRole {
  student,
  parent,
  teacher,
  admin,
  superAdmin,
}

/// User model with role and permissions
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final List<String> permissions;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.permissions = const [],
  });

  factory AppUser.admin({
    required String id,
    required String name,
    required String email,
  }) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
      permissions: [
        'manage_questions',
        'manage_subjects',
        'view_reports',
        'manage_users',
      ],
    );
  }

  factory AppUser.superAdmin({
    required String id,
    required String name,
    required String email,
  }) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: UserRole.superAdmin,
      isActive: true,
      createdAt: DateTime.now(),
      permissions: [
        'manage_questions',
        'manage_subjects',
        'view_reports',
        'manage_users',
        'system_admin',
        'manage_settings',
        'delete_content',
      ],
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || 
           role == UserRole.superAdmin;
  }

  bool get canManageQuestions => 
      role == UserRole.admin || role == UserRole.superAdmin;
  
  bool get canManageSubjects => 
      role == UserRole.admin || role == UserRole.superAdmin;
  
  bool get canManageUsers => 
      role == UserRole.admin || role == UserRole.superAdmin;
  
  bool get canDeleteContent => 
      role == UserRole.superAdmin;
}