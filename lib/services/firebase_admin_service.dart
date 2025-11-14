import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../utils/environment_config.dart';

class FirebaseAdminService {
  static FirebaseAdminService? _instance;
  static FirebaseAdminService get instance =>
      _instance ??= FirebaseAdminService._();

  FirebaseAdminService._();

  final FirebaseService _firebase = FirebaseService.instance;
  final EnvironmentConfig _config = EnvironmentConfig.instance;

  bool _isAdmin = false;
  bool _isInitialized = false;

  // Getters
  bool get isAdmin => _isAdmin;
  bool get isInitialized => _isInitialized;

  // Initialize admin service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _checkAdminStatus();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize FirebaseAdminService: $e');
    }
  }

  // Check if current user is admin based on Firestore user document
  Future<void> _checkAdminStatus() async {
    try {
      if (!_firebase.isAuthenticated) {
        _isAdmin = false;
        return;
      }

      // Get user profile from Firestore
      final userProfile = await _firebase.getUserProfile();

      if (userProfile != null) {
        // Check if accountType is 'superadmin' or if there's an isSuperadmin boolean
        final accountType = userProfile['accountType']?.toString().toLowerCase();
        final isSuperadminBool = userProfile['isSuperadmin'] as bool?;

        _isAdmin = accountType == 'superadmin' || isSuperadminBool == true;
        debugPrint('Checked admin status from Firestore: $_isAdmin (accountType: $accountType, isSuperadmin: $isSuperadminBool) for user ${_firebase.currentUserId}');
      } else {
        _isAdmin = false;
        debugPrint('No user profile found in Firestore for user ${_firebase.currentUserId}');
      }
    } catch (e) {
      debugPrint('Failed to check admin status: $e');
      _isAdmin = false;
    }
  }

  // Enable admin mode with password
  Future<bool> enableAdminMode(String password) async {
    try {
      final correctPassword = _config.superadminPassword;

      if (password == correctPassword) {
        // For Firebase, we could set a custom claim or use a special collection
        // For now, we'll use local state and verify against Firebase on app restart
        _isAdmin = true;

        // Optionally, you could store admin status in Firebase user profile
        if (_firebase.isAuthenticated) {
          await _updateAdminStatusInFirebase(true);
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to enable admin mode: $e');
      return false;
    }
  }

  // Disable admin mode
  Future<void> disableAdminMode() async {
    try {
      _isAdmin = false;

      // Update status in Firebase if user is authenticated
      if (_firebase.isAuthenticated) {
        await _updateAdminStatusInFirebase(false);
      }
    } catch (e) {
      debugPrint('Failed to disable admin mode: $e');
    }
  }

  // Update admin status in Firebase (custom implementation)
  Future<void> _updateAdminStatusInFirebase(bool isAdmin) async {
    try {
      // This would typically be done through Firebase Admin SDK on the backend
      // For now, we'll store it in the user's profile metadata
      // Note: In production, you should use Firebase Custom Claims for security

      final userId = _firebase.currentUserId;
      if (userId != null) {
        // Update account type in user profile
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'accountType': isAdmin ? 'superadmin' : 'registered',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Admin status updated locally: $isAdmin');
      }
    } catch (e) {
      debugPrint('Failed to update admin status in Firebase: $e');
    }
  }

  // Verify admin access for sensitive operations
  bool verifyAdminAccess() {
    return _isAdmin && _firebase.isAuthenticated;
  }

  // Refresh admin status from Firebase
  Future<void> refreshAdminStatus() async {
    await _checkAdminStatus();
  }

  // Get all users (admin only) - would need Firebase Admin SDK
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!verifyAdminAccess()) {
      throw Exception('Admin access required');
    }

    try {
      // This would require Firebase Admin SDK in a cloud function
      // For now, return empty list as placeholder
      debugPrint(
          'getAllUsers called - requires Firebase Admin SDK implementation');
      return [];
    } catch (e) {
      debugPrint('Failed to get all users: $e');
      return [];
    }
  }

  // Update user status (admin only) - would need Firebase Admin SDK
  Future<bool> updateUserStatus(String userId, String status) async {
    if (!verifyAdminAccess()) {
      throw Exception('Admin access required');
    }

    try {
      // This would require Firebase Admin SDK in a cloud function
      // For local testing, we can update Firestore directly
      // Note: This is insecure for production use - server-side validation required
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'accountType': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('User status updated: $userId -> $status');
      return true;
    } catch (e) {
      debugPrint('Failed to update user status: $e');
      return false;
    }
  }

  // Add superadmin by email (admin only) - requires Firebase Admin SDK in production
  Future<bool> addSuperadminByEmail(String email) async {
    if (!verifyAdminAccess()) {
      throw Exception('Admin access required');
    }

    try {
      // Find user by email
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No user found with email: $email');
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final userId = userDoc.id;

      // Update account type to superadmin
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'accountType': 'superadmin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Superadmin status added for user: $userId (email: $email)');
      return true;
    } catch (e) {
      debugPrint('Failed to add superadmin by email: $e');
      return false;
    }
  }

  // Get app analytics (admin only) - would need Firebase Analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    if (!verifyAdminAccess()) {
      throw Exception('Admin access required');
    }

    try {
      // This would integrate with Firebase Analytics
      debugPrint(
          'getAnalytics called - requires Firebase Analytics implementation');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalQuestions': 0,
        'premiumUsers': 0,
      };
    } catch (e) {
      debugPrint('Failed to get analytics: $e');
      return {};
    }
  }
}
