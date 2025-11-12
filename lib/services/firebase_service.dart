import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Firestore instance
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      // Check if Firebase is available
      if (!_isConfigurationValid()) {
        debugPrint(
            'Firebase configuration not available. Skipping initialization.');
        _isInitialized = false;
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;

  static bool _isConfigurationValid() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return options.projectId != 'your-project-id' &&
          options.apiKey != 'your-android-api-key' &&
          options.apiKey != 'your-ios-api-key' &&
          options.apiKey != 'your-web-api-key';
    } catch (e) {
      return false;
    }
  }

  // Current user
  User? get currentUser => _auth.currentUser;

  // Authentication status
  bool get isAuthenticated => currentUser != null;

  // User info getters
  String? get currentUserEmail => currentUser?.email;
  String? get currentUserId => currentUser?.uid;
  String? get userName => currentUser?.displayName;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Authentication methods
  static Future<User?> signUp(String email, String password) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Skipping signUp.');
      return null;
    }
    try {
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      if (result.user != null) {
        await _createUserProfile(result.user!, null);
      }

      return result.user;
    } catch (e) {
      debugPrint('SignUp error: $e');
      throw e;
    }
  }

  static Future<User?> signIn(String email, String password) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Skipping signIn.');
      return null;
    }
    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint('SignIn error: $e');
      throw e;
    }
  }

  static Future<void> signOut() async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Skipping signOut.');
      return;
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
      throw e;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();

      // Update Firestore profile
      await _updateUserProfileInFirestore(user.uid, {
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Create user profile in Firestore
  static Future<void> _createUserProfile(User user, String? displayName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'accountType': 'registered', // guest, registered, premium, superadmin
        'status': 'active', // active, suspended, deleted
        'totalQuestions': 0,
        'dailyQuestions': 0,
        'lastQuestionAt': null,
        'premiumExpiresAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {},
      });
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
    }
  }

  // Update user profile in Firestore
  Future<void> _updateUserProfileInFirestore(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? currentUserId;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  // Get user profile stream
  Stream<DocumentSnapshot<Map<String, dynamic>>?> getUserProfileStream(
      [String? uid]) {
    final userId = uid ?? currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Update user question count
  Future<void> updateQuestionCount({
    required int totalQuestions,
    required int dailyQuestions,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'totalQuestions': totalQuestions,
        'dailyQuestions': dailyQuestions,
        'lastQuestionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update question count: $e');
    }
  }

  // Check if user is premium
  Future<bool> isPremiumUser([String? uid]) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) return false;

      final accountType = profile['accountType'] as String?;
      if (accountType == 'premium' || accountType == 'superadmin') {
        // Check if premium is still valid
        final premiumExpiresAt = profile['premiumExpiresAt'] as Timestamp?;
        if (premiumExpiresAt == null && accountType == 'premium') {
          return false; // Premium without expiry date is invalid
        }
        if (premiumExpiresAt != null) {
          return DateTime.now().isBefore(premiumExpiresAt.toDate());
        }
        return accountType == 'superadmin'; // Superadmin never expires
      }
      return false;
    } catch (e) {
      debugPrint('Failed to check premium status: $e');
      return false;
    }
  }

  // Check if user is superadmin
  Future<bool> isSuperadmin([String? uid]) async {
    try {
      final profile = await getUserProfile(uid);
      return profile?['accountType'] == 'superadmin';
    } catch (e) {
      debugPrint('Failed to check superadmin status: $e');
      return false;
    }
  }

  // Update user premium status
  Future<void> updatePremiumStatus({
    required bool isPremium,
    DateTime? expiresAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'accountType': isPremium ? 'premium' : 'registered',
        'premiumExpiresAt': isPremium && expiresAt != null
            ? Timestamp.fromDate(expiresAt)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update premium status: $e');
    }
  }

  // Save question to Firestore
  Future<void> saveQuestion({
    required String questionId,
    required String question,
    required String questionType,
    String? subject,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('questions')
          .doc(questionId)
          .set({
        'id': questionId,
        'question': question,
        'questionType': questionType,
        'subject': subject,
        'imageUrl': imageUrl,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save question: $e');
    }
  }

  // Save explanation to Firestore
  Future<void> saveExplanation({
    required String questionId,
    required String answer,
    List<Map<String, dynamic>>? steps,
    String? parentTip,
    String? realWorldExample,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('explanations')
          .doc(questionId)
          .set({
        'questionId': questionId,
        'answer': answer,
        'steps': steps ?? [],
        'parentFriendlyTip': parentTip,
        'realWorldExample': realWorldExample,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save explanation: $e');
    }
  }

  // Get user questions stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserQuestionsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get explanation for question
  Future<Map<String, dynamic>?> getExplanationForQuestion(
    String questionId,
  ) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('explanations')
          .doc(questionId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Failed to get explanation: $e');
      return null;
    }
  }

  // Delete question and explanation
  Future<void> deleteQuestion(String questionId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      // Delete question
      batch.delete(_firestore
          .collection('users')
          .doc(userId)
          .collection('questions')
          .doc(questionId));

      // Delete explanation
      batch.delete(_firestore
          .collection('users')
          .doc(userId)
          .collection('explanations')
          .doc(questionId));

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to delete question: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
