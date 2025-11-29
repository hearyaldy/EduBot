import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool _hasShownWarning = false;
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase Auth instance
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Firestore instance
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Public getter for Firestore access
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

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
      if (!_hasShownWarning) {
        debugPrint(
            '⚠️ Firebase not initialized. User registration will work with local storage only.');
        _hasShownWarning = true;
      }
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
      rethrow;
    }
  }

  static Future<User?> signIn(String email, String password) async {
    if (!_isInitialized) {
      if (!_hasShownWarning) {
        debugPrint(
            '⚠️ Firebase not initialized. User authentication will work with local storage only.');
        _hasShownWarning = true;
      }
      return null;
    }
    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint('SignIn error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    if (!_isInitialized) {
      // No warning needed for signOut - just skip silently
      return;
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
      rethrow;
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
    String? childProfileId,
    String? answer,
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
        'childProfileId': childProfileId,
        'answer': answer,
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

  // Get questions stream for a specific child profile
  Stream<QuerySnapshot<Map<String, dynamic>>> getChildQuestionsStream(
    String childProfileId,
  ) {
    final userId = currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('questions')
        .where('childProfileId', isEqualTo: childProfileId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all questions for a child profile (one-time fetch)
  Future<List<Map<String, dynamic>>> getChildQuestions(
    String childProfileId,
  ) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questions')
          .where('childProfileId', isEqualTo: childProfileId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Failed to get child questions: $e');
      return [];
    }
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

  // ===== CHILD PROFILE MANAGEMENT =====

  // Save child profile to Firestore
  Future<void> saveChildProfile(Map<String, dynamic> profileData) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot save child profile: No user logged in');
      return;
    }

    try {
      debugPrint(
          '💾 Saving child profile to Firestore: ${profileData['name']} (${profileData['id']})');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('childProfiles')
          .doc(profileData['id'])
          .set({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Child profile saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save child profile: $e');
    }
  }

  // Get child profiles from Firestore
  Future<List<Map<String, dynamic>>> getChildProfiles() async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot get child profiles: No user logged in');
      return [];
    }

    try {
      debugPrint('📥 Fetching child profiles from Firestore for user: $userId');
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('childProfiles')
          .get();

      debugPrint(
          '✅ Retrieved ${snapshot.docs.length} child profiles from Firestore');
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Failed to get child profiles: $e');
      return [];
    }
  }

  // Delete child profile from Firestore
  Future<void> deleteChildProfile(String profileId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Delete the profile
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('childProfiles')
          .doc(profileId)
          .delete();

      // Optionally, you might want to keep the questions but mark them as orphaned
      // Or delete all questions associated with this profile
      // For now, we'll keep the questions in history
    } catch (e) {
      debugPrint('Failed to delete child profile: $e');
    }
  }

  // Update child profile metrics
  Future<void> updateChildProfileMetrics({
    required String profileId,
    int? questionCount,
    int? currentStreak,
    int? longestStreak,
    Set<String>? subjectsUsed,
    List<String>? unlockedBadgeIds,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (questionCount != null) updates['questionCount'] = questionCount;
      if (currentStreak != null) updates['currentStreak'] = currentStreak;
      if (longestStreak != null) updates['longestStreak'] = longestStreak;
      if (subjectsUsed != null) updates['subjectsUsed'] = subjectsUsed.toList();
      if (unlockedBadgeIds != null) {
        updates['unlockedBadgeIds'] = unlockedBadgeIds;
      }
      updates['lastUsedAt'] = FieldValue.serverTimestamp();
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('childProfiles')
          .doc(profileId)
          .update(updates);
    } catch (e) {
      debugPrint('Failed to update child profile metrics: $e');
    }
  }

  // Get child profile metrics
  Future<Map<String, dynamic>?> getChildProfileMetrics(
    String profileId,
  ) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('childProfiles')
          .doc(profileId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Failed to get child profile metrics: $e');
      return null;
    }
  }

  // ===== STREAK DATA SYNC =====

  /// Save streak data to Firestore
  Future<void> saveStreakData(Map<String, dynamic> streakData) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot save streak data: No user logged in');
      return;
    }

    try {
      debugPrint('💾 Saving streak data to Firestore...');
      await _firestore.collection('users').doc(userId).set({
        'streakData': {
          ...streakData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      debugPrint('✅ Streak data saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save streak data: $e');
    }
  }

  /// Get streak data from Firestore
  Future<Map<String, dynamic>?> getStreakData() async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot get streak data: No user logged in');
      return null;
    }

    try {
      debugPrint('📥 Fetching streak data from Firestore for user: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data()?['streakData'] != null) {
        debugPrint('✅ Retrieved streak data from Firestore');
        return doc.data()!['streakData'] as Map<String, dynamic>;
      }
      debugPrint('ℹ️ No streak data found in Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get streak data: $e');
      return null;
    }
  }

  // ===== BADGE DATA SYNC =====

  /// Save badge data to Firestore
  Future<void> saveBadgeData({
    required List<Map<String, dynamic>> badges,
    required List<String> subjectsUsed,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot save badge data: No user logged in');
      return;
    }

    try {
      debugPrint('💾 Saving badge data to Firestore...');
      await _firestore.collection('users').doc(userId).set({
        'badgeData': {
          'badges': badges,
          'subjectsUsed': subjectsUsed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      debugPrint('✅ Badge data saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save badge data: $e');
    }
  }

  /// Get badge data from Firestore
  Future<Map<String, dynamic>?> getBadgeData() async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ Cannot get badge data: No user logged in');
      return null;
    }

    try {
      debugPrint('📥 Fetching badge data from Firestore for user: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data()?['badgeData'] != null) {
        debugPrint('✅ Retrieved badge data from Firestore');
        return doc.data()!['badgeData'] as Map<String, dynamic>;
      }
      debugPrint('ℹ️ No badge data found in Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get badge data: $e');
      return null;
    }
  }

  // ===== SHARED QUESTION BANK (GLOBAL FOR ALL USERS) =====

  /// Save a question to the global question bank in Firestore
  /// All users can access and contribute to this shared question bank
  Future<void> saveQuestionToBank(Map<String, dynamic> questionData) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Cannot save question to bank.');
      return;
    }

    try {
      await _firestore.collection('questionBank').doc(questionData['id']).set({
        ...questionData,
        'createdAt': questionData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId ?? 'anonymous',
      }, SetOptions(merge: true));

      debugPrint('Question saved to Firestore: ${questionData['id']}');
    } catch (e) {
      debugPrint('Failed to save question to Firestore: $e');
      rethrow;
    }
  }

  /// Get all questions from the shared question bank
  Future<List<Map<String, dynamic>>> getQuestionsFromBank({
    int? limit,
  }) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Cannot get questions from bank.');
      return [];
    }

    try {
      Query query = _firestore.collection('questionBank');

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to get questions from Firestore: $e');
      return [];
    }
  }

  /// Get filtered questions from the shared question bank
  Future<List<Map<String, dynamic>>> getQuestionsFromBankFiltered({
    String? subject,
    int? gradeLevel,
    int? difficulty,
    int? limit,
  }) async {
    if (!_isInitialized) {
      debugPrint(
          'Firebase not initialized. Cannot get filtered questions from bank.');
      return [];
    }

    try {
      Query query = _firestore.collection('questionBank');

      if (subject != null && subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
      }

      if (gradeLevel != null) {
        query = query.where('grade_level', isEqualTo: gradeLevel);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to get filtered questions from Firestore: $e');
      return [];
    }
  }

  /// Delete a question from the shared question bank
  Future<void> deleteQuestionFromBank(String questionId) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Cannot delete question from bank.');
      return;
    }

    try {
      await _firestore.collection('questionBank').doc(questionId).delete();
      debugPrint('Question deleted from Firestore: $questionId');
    } catch (e) {
      debugPrint('Failed to delete question from Firestore: $e');
      rethrow;
    }
  }

  /// Delete all questions for a specific lesson (by subject, grade, and topic)
  Future<void> deleteQuestionsForLesson(
      String subject, int gradeLevel, String topic) async {
    if (!_isInitialized) {
      debugPrint(
          'Firebase not initialized. Cannot delete questions for lesson.');
      return;
    }

    try {
      // Query questions matching the lesson criteria
      final snapshot = await _firestore
          .collection('questionBank')
          .where('subject', isEqualTo: subject)
          .where('grade_level', isEqualTo: gradeLevel)
          .where('topic', isEqualTo: topic)
          .get();

      // Delete each matching question
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint(
          'Deleted ${snapshot.docs.length} questions for lesson: $subject, Grade $gradeLevel, $topic');
    } catch (e) {
      debugPrint('Failed to delete questions for lesson from Firestore: $e');
      rethrow;
    }
  }

  /// Get a real-time stream of questions from the shared question bank
  Stream<QuerySnapshot<Map<String, dynamic>>> getQuestionBankStream({
    String? subject,
    int? gradeLevel,
  }) {
    if (!_isInitialized) {
      return const Stream.empty();
    }

    Query<Map<String, dynamic>> query = _firestore.collection('questionBank');

    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }

    if (gradeLevel != null) {
      query = query.where('grade_level', isEqualTo: gradeLevel);
    }

    return query.snapshots();
  }

  /// Get question count from the shared question bank
  Future<int> getQuestionBankCount() async {
    if (!_isInitialized) {
      return 0;
    }

    try {
      final snapshot =
          await _firestore.collection('questionBank').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Failed to get question bank count: $e');
      return 0;
    }
  }

  /// Sync questions from local database to Firestore
  Future<void> syncQuestionsToFirestore(
      List<Map<String, dynamic>> questions) async {
    if (!_isInitialized) {
      debugPrint(
          'Firebase not initialized. Cannot sync questions to Firestore.');
      return;
    }

    try {
      final batch = _firestore.batch();
      int count = 0;

      for (final questionData in questions) {
        final docRef =
            _firestore.collection('questionBank').doc(questionData['id']);

        batch.set(
            docRef,
            {
              ...questionData,
              'createdAt':
                  questionData['createdAt'] ?? FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'createdBy': currentUserId ?? 'anonymous',
            },
            SetOptions(merge: true));

        count++;

        // Firestore batch has a limit of 500 operations
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }

      // Commit remaining operations
      if (count > 0) {
        await batch.commit();
      }

      debugPrint('Synced ${questions.length} questions to Firestore');
    } catch (e) {
      debugPrint('Failed to sync questions to Firestore: $e');
      rethrow;
    }
  }

  /// Find and remove duplicate questions from Firestore
  /// Returns detailed statistics about the cleanup
  Future<Map<String, dynamic>> removeFirestoreDuplicates() async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized. Cannot remove duplicates.');
      return {
        'total': 0,
        'duplicates_found': 0,
        'duplicates_removed': 0,
        'unique_remaining': 0,
        'errors': ['Firebase not initialized']
      };
    }

    try {
      debugPrint(
          '🔍 Fetching all questions from Firestore for deduplication...');
      final snapshot = await _firestore.collection('questionBank').get();
      final allDocs = snapshot.docs;
      final total = allDocs.length;
      debugPrint('📊 Found $total total questions in Firestore');

      // Create a map to track unique questions by content hash
      final Map<String, String> contentHashToDocId = {};
      final List<String> duplicateDocIds = [];

      for (final doc in allDocs) {
        final data = doc.data();

        // Generate content hash based on question content
        final questionText =
            (data['question_text'] ?? '').toString().toLowerCase().trim();
        final answerKey =
            (data['answer_key'] ?? '').toString().toLowerCase().trim();
        final subject = (data['subject'] ?? '').toString().toLowerCase().trim();
        final topic = (data['topic'] ?? '').toString().toLowerCase().trim();

        final contentHash = '$questionText|$subject|$topic|$answerKey';

        if (contentHashToDocId.containsKey(contentHash)) {
          // This is a duplicate - mark for deletion
          duplicateDocIds.add(doc.id);
        } else {
          // First occurrence - keep it
          contentHashToDocId[contentHash] = doc.id;
        }
      }

      final duplicatesFound = duplicateDocIds.length;
      debugPrint('🔄 Found $duplicatesFound duplicate questions to remove');

      if (duplicateDocIds.isEmpty) {
        return {
          'total': total,
          'duplicates_found': 0,
          'duplicates_removed': 0,
          'unique_remaining': total,
          'errors': <String>[]
        };
      }

      // Delete duplicates in batches
      int deleted = 0;
      final List<String> errors = [];
      const batchSize = 500;

      for (int i = 0; i < duplicateDocIds.length; i += batchSize) {
        try {
          final batch = _firestore.batch();
          final end = (i + batchSize < duplicateDocIds.length)
              ? i + batchSize
              : duplicateDocIds.length;

          for (int j = i; j < end; j++) {
            final docRef =
                _firestore.collection('questionBank').doc(duplicateDocIds[j]);
            batch.delete(docRef);
          }

          await batch.commit();
          deleted += (end - i);
          debugPrint('🗑️ Deleted batch: $deleted/$duplicatesFound');
        } catch (e) {
          errors.add('Batch delete error: $e');
          debugPrint('❌ Batch delete error: $e');
        }
      }

      final uniqueRemaining = total - deleted;
      debugPrint(
          '✅ Removed $deleted duplicates. $uniqueRemaining unique questions remaining.');

      return {
        'total': total,
        'duplicates_found': duplicatesFound,
        'duplicates_removed': deleted,
        'unique_remaining': uniqueRemaining,
        'errors': errors
      };
    } catch (e) {
      debugPrint('❌ Failed to remove duplicates from Firestore: $e');
      return {
        'total': 0,
        'duplicates_found': 0,
        'duplicates_removed': 0,
        'unique_remaining': 0,
        'errors': [e.toString()]
      };
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
