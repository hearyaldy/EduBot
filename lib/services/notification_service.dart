import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap here
    // You can navigate to specific screens based on payload
  }

  /// Schedule daily homework reminder
  Future<void> scheduleDailyReminder({
    int hour = 16, // 4 PM default
    int minute = 0,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Homework Time! 📚',
        'Ready to help your child with homework today?',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Homework Reminder',
            channelDescription: 'Daily reminder to help with homework',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Daily reminder scheduled for $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
    debugPrint('Daily reminder cancelled');
  }

  /// Show immediate notification for badge unlock
  Future<void> showBadgeUnlockedNotification({
    required String badgeTitle,
    required String badgeEmoji,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      await _notifications.show(
        badgeTitle.hashCode, // Use title hash as unique ID
        'Badge Unlocked! $badgeEmoji',
        'Congratulations! You earned: $badgeTitle',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'badge_unlocks',
            'Badge Unlocks',
            channelDescription: 'Notifications for unlocking achievements',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing badge notification: $e');
    }
  }

  /// Show streak milestone notification
  Future<void> showStreakMilestoneNotification({
    required int streak,
    required String message,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      await _notifications.show(
        1000 + streak, // Unique ID for streak notifications
        'Streak Milestone! 🔥',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_milestones',
            'Streak Milestones',
            channelDescription: 'Notifications for streak achievements',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing streak notification: $e');
    }
  }

  /// Calculate next instance of specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;

    if (!enabled) {
      await cancelDailyReminder();
    } else {
      await scheduleDailyReminder();
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
}
