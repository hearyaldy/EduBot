import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';
import 'firebase_service.dart';
import 'firebase_admin_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  static AdminService get instance => _instance;

  AdminService._internal();

  // Synchronous check for UI updates
  bool get isAdmin {
    try {
      // This method now caches the superadmin state
      return FirebaseAdminService.instance.isAdmin;
    } catch (e) {
      debugPrint('Error checking superadmin status in AdminService: $e');
      return false;
    }
  }

  // Async method to refresh admin status
  Future<void> refreshAdminStatus() async {
    await FirebaseAdminService.instance.refreshAdminStatus();
  }

  Future<bool> checkAdminStatus(String? email) async {
    // Check if the currently authenticated user is an admin/superadmin
    // The email parameter is kept for compatibility but not used here
    // as the check is for the current user
    try {
      return FirebaseService.instance.isSuperadmin();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> grantAdminAccess(String email) async {
    // Implement admin access granting logic
    debugPrint('Admin access granted to: $email');
  }

  Future<void> revokeAdminAccess(String email) async {
    // Implement admin access revoking logic
    debugPrint('Admin access revoked from: $email');
  }

  // Admin dashboard methods - actual implementations
  Future<List<AdminUser>> getAllUsers({
    int page = 1,
    int limit = 0, // Changed default to 0 to get all users
    String? searchQuery,
    AccountType? accountTypeFilter,
    UserStatus? statusFilter,
  }) async {
    try {
      final firebaseService = FirebaseService.instance;
      QuerySnapshot querySnapshot;

      if (limit > 0) {
        querySnapshot = await firebaseService.firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
      } else {
        querySnapshot = await firebaseService.firestore
            .collection('users')
            .orderBy('createdAt', descending: true)
            .get();
      }

      final usersList = <AdminUser>[];

      for (final doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>?;
        if (userData == null) continue;

        try {
          // Map Firestore fields to AdminUser expected fields
          final adminUser = AdminUser.fromSupabaseUser({
            'id': doc.id,
            'email': userData['email']?.toString() ?? '',
            'name': userData['displayName']?.toString() ??
                userData['name']?.toString(),
            'account_type': userData['accountType']?.toString() ?? 'guest',
            'status': userData['status']?.toString() ?? 'active',
            'is_email_verified': userData['emailVerified'] ??
                userData['isEmailVerified'] ??
                false,
            'created_at': _formatTimestamp(userData['createdAt']) ??
                DateTime.now().toIso8601String(),
            'updated_at': _formatTimestamp(
                    userData['updatedAt'] ?? userData['lastSignInAt']) ??
                DateTime.now().toIso8601String(),
            'premium_expires_at':
                _formatTimestamp(userData['premiumExpiresAt']),
            'total_questions': userData['totalQuestions'] ?? 0,
            'daily_questions': userData['dailyQuestions'] ?? 0,
            'last_question_at': _formatTimestamp(userData['lastQuestionAt']),
            'metadata': userData['metadata'],
          });

          // Apply filters
          bool shouldInclude = true;

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final searchLower = searchQuery.toLowerCase();
            shouldInclude = adminUser.email
                    .toLowerCase()
                    .contains(searchLower) ||
                (adminUser.name?.toLowerCase().contains(searchLower) ?? false);
          }

          if (shouldInclude && accountTypeFilter != null) {
            shouldInclude = adminUser.accountType == accountTypeFilter;
          }

          if (shouldInclude && statusFilter != null) {
            shouldInclude = adminUser.status == statusFilter;
          }

          if (shouldInclude) {
            usersList.add(adminUser);
          }
        } catch (userError) {
          debugPrint('Error parsing user data for user ${doc.id}: $userError');
          continue; // Skip this user and continue with others
        }
      }

      return usersList;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final firebaseService = FirebaseService.instance;
      final querySnapshot =
          await firebaseService.firestore.collection('users').get();

      int totalUsers = 0;
      int premiumUsers = 0;
      int activeUsers = 0;
      int suspendedUsers = 0;
      int registeredUsers = 0;
      int guestUsers = 0;
      int superadminUsers = 0;
      int newUsers30Days = 0;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        totalUsers++;

        // Count by account type
        final accountType = userData['accountType']?.toString() ?? 'guest';
        switch (accountType.toLowerCase()) {
          case 'premium':
            premiumUsers++;
            break;
          case 'registered':
            registeredUsers++;
            break;
          case 'superadmin':
            superadminUsers++;
            break;
          default:
            guestUsers++; // Default to guest for any other type
        }

        // Count by status
        final status = userData['status']?.toString() ?? 'active';
        if (status.toLowerCase() == 'suspended') {
          suspendedUsers++;
        } else {
          activeUsers++;
        }

        // Count recent users (last 30 days)
        final createdAt = userData['createdAt'] as Timestamp?;
        if (createdAt != null) {
          if (createdAt.toDate().isAfter(thirtyDaysAgo)) {
            newUsers30Days++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'premiumUsers': premiumUsers,
        'activeUsers': activeUsers,
        'suspendedUsers': suspendedUsers,
        'guestUsers': guestUsers,
        'registeredUsers': registeredUsers,
        'superadminUsers': superadminUsers,
        'newUsers30Days': newUsers30Days,
        'total_users': totalUsers,
        'premium_users': premiumUsers,
        'active_users': activeUsers,
        'suspended_users': suspendedUsers,
        'guest_users': guestUsers,
        'registered_users': registeredUsers,
        'superadmin_users': superadminUsers,
        'new_users_30_days': newUsers30Days,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {
        'totalUsers': 0,
        'premiumUsers': 0,
        'activeUsers': 0,
        'suspendedUsers': 0,
        'guestUsers': 0,
        'registeredUsers': 0,
        'superadminUsers': 0,
        'newUsers30Days': 0,
        'total_users': 0,
        'premium_users': 0,
        'active_users': 0,
        'suspended_users': 0,
        'guest_users': 0,
        'registered_users': 0,
        'superadmin_users': 0,
        'new_users_30_days': 0,
      };
    }
  }

  Future<bool> upgradeToPremium(String userId, {DateTime? expiresAt}) async {
    try {
      final firebaseService = FirebaseService.instance;
      await firebaseService.updatePremiumStatus(
        isPremium: true,
        expiresAt: expiresAt,
      );

      // Update specific user document
      await firebaseService.firestore.collection('users').doc(userId).update({
        'accountType': 'premium',
        'premiumExpiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Upgraded user to premium: $userId');
      return true;
    } catch (e) {
      debugPrint('Error upgrading user to premium: $e');
      return false;
    }
  }

  Future<bool> downgradeFromPremium(String userId) async {
    try {
      final firebaseService = FirebaseService.instance;

      // Update specific user document
      await firebaseService.firestore.collection('users').doc(userId).update({
        'accountType': 'registered', // Back to registered user
        'premiumExpiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Downgraded user from premium: $userId');
      return true;
    } catch (e) {
      debugPrint('Error downgrading user from premium: $e');
      return false;
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      final firebaseService = FirebaseService.instance;

      // Update specific user document
      await firebaseService.firestore.collection('users').doc(userId).update({
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
        'suspensionReason': reason,
      });

      debugPrint('Suspended user: $userId, reason: $reason');
      return true;
    } catch (e) {
      debugPrint('Error suspending user: $e');
      return false;
    }
  }

  Future<bool> unsuspendUser(String userId) async {
    try {
      final firebaseService = FirebaseService.instance;

      // Update specific user document
      await firebaseService.firestore.collection('users').doc(userId).update({
        'status': 'active',
        'suspensionReason': FieldValue.delete(), // Remove suspension reason
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Unsuspended user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error unsuspending user: $e');
      return false;
    }
  }

  String? _formatTimestamp(dynamic timestampValue) {
    if (timestampValue == null) return null;
    if (timestampValue is Timestamp) {
      return timestampValue.toDate().toIso8601String();
    } else if (timestampValue is DateTime) {
      return timestampValue.toIso8601String();
    } else if (timestampValue is String) {
      // If it's already a string, return as is
      return timestampValue;
    }
    return null;
  }
}
