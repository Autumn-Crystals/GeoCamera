import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'health_calculator.dart';
import '../models/map_models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to specific tree
    // This would need navigation context
    print('Notification tapped: ${response.payload}');
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ngo_tree_tracker_channel',
      'Tree Tracker Notifications',
      channelDescription: 'Tree plantation tracking notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Schedule daily reminder
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      0, // Notification ID
      'Tree Update Reminder',
      'Don\'t forget to check on your trees today!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily tree check reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', true);
    await prefs.setInt('daily_reminder_hour', hour);
    await prefs.setInt('daily_reminder_minute', minute);
  }

  // Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', false);
  }

  // Check for overdue trees and send notifications
  static Future<void> checkOverdueTrees() async {
    final trees = await DatabaseService.getTrees();
    int criticalCount = 0;
    int needsAttentionCount = 0;

    for (var tree in trees) {
      final health = HealthCalculator.calculateHealth(tree);
      if (health.status == HealthStatus.critical) {
        criticalCount++;
      } else if (health.status == HealthStatus.needsAttention) {
        needsAttentionCount++;
      }
    }

    if (criticalCount > 0) {
      await showNotification(
        id: 1,
        title: '⚠️ Critical Trees Alert',
        body: '$criticalCount ${criticalCount == 1 ? 'tree needs' : 'trees need'} immediate attention!',
        payload: 'critical_trees',
      );
    }

    if (needsAttentionCount > 0) {
      await showNotification(
        id: 2,
        title: '🌳 Trees Need Update',
        body: '$needsAttentionCount ${needsAttentionCount == 1 ? 'tree needs' : 'trees need'} an update soon',
        payload: 'needs_attention_trees',
      );
    }
  }

  // Send weekly summary
  static Future<void> sendWeeklySummary() async {
    final trees = await DatabaseService.getTrees();
    final stats = await DatabaseService.getStats();

    await showNotification(
      id: 3,
      title: '📊 Weekly Summary',
      body: 'Total: ${stats['totalTrees']} trees, ${stats['totalUpdates']} updates this week',
      payload: 'weekly_summary',
    );
  }

  // Helper to calculate next instance of time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Get notification settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'daily_reminder_enabled': prefs.getBool('daily_reminder_enabled') ?? false,
      'daily_reminder_hour': prefs.getInt('daily_reminder_hour') ?? 9,
      'daily_reminder_minute': prefs.getInt('daily_reminder_minute') ?? 0,
      'overdue_alerts_enabled': prefs.getBool('overdue_alerts_enabled') ?? true,
      'weekly_summary_enabled': prefs.getBool('weekly_summary_enabled') ?? true,
    };
  }

  // Update notification settings
  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (settings.containsKey('daily_reminder_enabled')) {
      await prefs.setBool('daily_reminder_enabled', settings['daily_reminder_enabled']);
    }
    if (settings.containsKey('overdue_alerts_enabled')) {
      await prefs.setBool('overdue_alerts_enabled', settings['overdue_alerts_enabled']);
    }
    if (settings.containsKey('weekly_summary_enabled')) {
      await prefs.setBool('weekly_summary_enabled', settings['weekly_summary_enabled']);
    }
  }
}
