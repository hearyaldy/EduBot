import 'package:flutter/foundation.dart';
import '../models/user_role.dart';

class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  AppUser? _currentUser;
  bool _isAdminAuthenticated = false;

  AppUser? get currentUser => _currentUser;
  bool get isAdminAuthenticated => _isAdminAuthenticated;
  bool get isSuperAdmin => _currentUser?.role == UserRole.superAdmin;

  /// Initialize the service with a default admin user for development
  Future<void> initialize() async {
    // In a real app, you would load the user from secure storage or session
    // For now, create a default admin user for development
    if (_currentUser == null) {
      _currentUser = AppUser.admin(
        id: 'admin_user',
        name: 'System Admin',
        email: 'admin@edubot.com',
      );
      _isAdminAuthenticated = true;
      debugPrint('🔐 AdminAuthService: Initialized with default admin user');
    }
  }

  /// Login with credentials (simplified for this example)
  Future<bool> login(String username, String password) async {
    // In a real app, this would validate against a backend
    // For now, use simple validation
    if (username == 'admin' && password == 'admin123') {
      _currentUser = AppUser.admin(
        id: 'admin_user',
        name: 'System Admin',
        email: 'admin@edubot.com',
      );
      _isAdminAuthenticated = true;
      debugPrint('🔐 AdminAuthService: Admin user logged in');
      return true;
    } else if (username == 'superadmin' && password == 'superadmin123') {
      _currentUser = AppUser.superAdmin(
        id: 'superadmin_user',
        name: 'Super Admin',
        email: 'superadmin@edubot.com',
      );
      _isAdminAuthenticated = true;
      debugPrint('🔐 AdminAuthService: Super admin user logged in');
      return true;
    }
    
    return false;
  }

  /// Login with a specific user (for testing)
  void loginWithUser(AppUser user) {
    _currentUser = user;
    _isAdminAuthenticated = user.role == UserRole.admin || user.role == UserRole.superAdmin;
    debugPrint('🔐 AdminAuthService: Logged in user ${user.name} with role ${user.role}');
  }

  /// Logout the current user
  void logout() {
    _currentUser = null;
    _isAdminAuthenticated = false;
    debugPrint('🔐 AdminAuthService: User logged out');
  }

  /// Check if current user has permission
  bool hasPermission(String permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Check if user can access admin features
  bool canAccessAdminFeatures() {
    return _isAdminAuthenticated && 
           (_currentUser?.role == UserRole.admin || 
            _currentUser?.role == UserRole.superAdmin);
  }

  /// Check if user is super admin
  bool isUserSuperAdmin() {
    return _currentUser?.role == UserRole.superAdmin;
  }

  /// Check if user is regular admin
  bool isUserAdmin() {
    return _currentUser?.role == UserRole.admin;
  }
}