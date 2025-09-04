import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';
import '../utils/environment_config.dart';
import 'supabase_service.dart';

class AdminService {
  static AdminService? _instance;
  static AdminService get instance {
    _instance ??= AdminService._();
    return _instance!;
  }

  AdminService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static final _config = EnvironmentConfig.instance;
  final _supabaseService = SupabaseService.instance;

  // Check if current user has admin privileges
  bool get isAdmin {
    final user = _supabaseService.currentUser;
    return user?.userMetadata?['is_superadmin'] == true;
  }

  // Check if admin operations are properly configured
  bool get isAdminConfigured {
    return _config.isSupabaseAdminConfigured && isAdmin;
  }

  // Get all users for admin management
  Future<List<AdminUser>> getAllUsers({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
    AccountType? accountTypeFilter,
    UserStatus? statusFilter,
  }) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      // Note: In a real app, you would need to create a custom API endpoint
      // on your Supabase backend to fetch user data as the auth.users table
      // is not directly accessible from the client side for security reasons.
      // This is a conceptual implementation.
      
      if (_config.isDebugMode) {
        debugPrint('Fetching users with limit: $limit, offset: $offset');
      }

      // For now, we'll simulate getting users from a custom users table
      // In production, you'd need to:
      // 1. Create a 'profiles' table that mirrors user data
      // 2. Use database triggers to sync auth.users with profiles
      // 3. Query the profiles table instead
      
      var query = _client.from('profiles').select('''
        id, email, name, account_type, status, is_email_verified,
        created_at, last_sign_in, premium_expires_at, total_questions,
        daily_questions, last_question_at, metadata
      ''');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('email.ilike.%$searchQuery%,name.ilike.%$searchQuery%');
      }

      if (accountTypeFilter != null) {
        query = query.eq('account_type', accountTypeFilter.name);
      }

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final users = (response as List)
          .map((userData) => AdminUser.fromSupabaseUser(userData))
          .toList();

      if (_config.isDebugMode) {
        debugPrint('Fetched ${users.length} users');
      }

      return users;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error fetching users: $e');
      }
      rethrow;
    }
  }

  // Get user by ID
  Future<AdminUser?> getUserById(String userId) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      final response = await _client
          .from('profiles')
          .select('''
            id, email, name, account_type, status, is_email_verified,
            created_at, last_sign_in, premium_expires_at, total_questions,
            daily_questions, last_question_at, metadata
          ''')
          .eq('id', userId)
          .single();

      return AdminUser.fromSupabaseUser(response);
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error fetching user $userId: $e');
      }
      return null;
    }
  }

  // Upgrade user to premium
  Future<bool> upgradeToPremium(String userId, {
    DateTime? expiresAt,
    bool isLifetime = false,
  }) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      final premiumExpiresAt = isLifetime ? null : expiresAt;
      
      // Update user profile
      await _client.from('profiles').update({
        'account_type': AccountType.premium.name,
        'premium_expires_at': premiumExpiresAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Note: Admin API access would require server-side implementation
      // For client-side, we'll focus on the profiles table
      
      if (_config.isDebugMode) {
        debugPrint('Would update auth metadata for user $userId via server-side admin API');
      }

      if (_config.isDebugMode) {
        debugPrint('User $userId upgraded to premium');
      }

      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error upgrading user $userId to premium: $e');
      }
      return false;
    }
  }

  // Downgrade user from premium
  Future<bool> downgradeFromPremium(String userId) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      // Update user profile
      await _client.from('profiles').update({
        'account_type': AccountType.registered.name,
        'premium_expires_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Note: Admin API access would require server-side implementation
      if (_config.isDebugMode) {
        debugPrint('Would update auth metadata for user $userId via server-side admin API');
      }

      if (_config.isDebugMode) {
        debugPrint('User $userId downgraded from premium');
      }

      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error downgrading user $userId from premium: $e');
      }
      return false;
    }
  }

  // Suspend user
  Future<bool> suspendUser(String userId, String reason) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      await _client.from('profiles').update({
        'status': UserStatus.suspended.name,
        'suspension_reason': reason,
        'suspended_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (_config.isDebugMode) {
        debugPrint('User $userId suspended: $reason');
      }

      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error suspending user $userId: $e');
      }
      return false;
    }
  }

  // Unsuspend user
  Future<bool> unsuspendUser(String userId) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      await _client.from('profiles').update({
        'status': UserStatus.active.name,
        'suspension_reason': null,
        'suspended_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (_config.isDebugMode) {
        debugPrint('User $userId unsuspended');
      }

      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error unsuspending user $userId: $e');
      }
      return false;
    }
  }

  // Get user statistics (simplified version for demonstration)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      // Note: In a real implementation, you would use proper count queries
      // For now, we'll simulate statistics
      
      if (_config.isDebugMode) {
        debugPrint('Fetching user statistics...');
      }

      // Simulate getting all users and calculating stats
      final allUsers = await getAllUsers(limit: 1000);
      
      final guestCount = allUsers.where((u) => u.accountType == AccountType.guest).length;
      final registeredCount = allUsers.where((u) => u.accountType == AccountType.registered).length;
      final premiumCount = allUsers.where((u) => u.accountType == AccountType.premium).length;
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final newUsersCount = allUsers.where((u) => u.createdAt.isAfter(thirtyDaysAgo)).length;

      return {
        'total_users': allUsers.length,
        'guest_users': guestCount,
        'registered_users': registeredCount,
        'premium_users': premiumCount,
        'new_users_30_days': newUsersCount,
      };
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error fetching user stats: $e');
      }
      return {
        'total_users': 0,
        'guest_users': 0,
        'registered_users': 0,
        'premium_users': 0,
        'new_users_30_days': 0,
      };
    }
  }

  // Update user details
  Future<bool> updateUserDetails(String userId, {
    String? name,
    String? email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (metadata != null) updates['metadata'] = metadata;

      await _client.from('profiles').update(updates).eq('id', userId);

      if (_config.isDebugMode) {
        debugPrint('User $userId details updated');
      }

      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error updating user $userId details: $e');
      }
      return false;
    }
  }

  // Search users by email or name
  Future<List<AdminUser>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (!isAdmin) {
        throw Exception('Access denied. Admin privileges required.');
      }

      final response = await _client
          .from('profiles')
          .select('''
            id, email, name, account_type, status, is_email_verified,
            created_at, last_sign_in, premium_expires_at, total_questions,
            daily_questions, last_question_at, metadata
          ''')
          .or('email.ilike.%$query%,name.ilike.%$query%')
          .limit(limit);

      return (response as List)
          .map((userData) => AdminUser.fromSupabaseUser(userData))
          .toList();
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error searching users: $e');
      }
      return [];
    }
  }
}