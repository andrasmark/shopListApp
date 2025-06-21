import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();
  static final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _flutterLocalNotificationsPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      'Test notif',
      'This is a test notif.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleReminder({
    required String listId,
    required Timestamp reminderTime,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(listId)
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    final List<dynamic> sharedWith = data['sharedWith'] ?? [];

    if (!sharedWith.contains(currentUser.uid)) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime.toDate(), tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      listId.hashCode, // Unique ID
      'Grocery list notification',
      'Shopping is due to:',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grocery_channel',
          'Grocery Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   bool _isInitialized = false;
//
//   Future<void> initNotification() async {
//     if (_isInitialized) return;
//
//     tz.initializeTimeZones();
//
//     try {
//       // Try to get local timezone (may fail on some devices)
//       final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
//       tz.setLocalLocation(tz.getLocation(currentTimeZone));
//     } catch (e) {
//       print("Error getting timezone, using fallback: $e");
//       // Fallback to device's local timezone or UTC
//       //final location = _getFallbackTimezone();
//       //tz.setLocalLocation(location);
//     }
//
//     const AndroidInitializationSettings initSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings initSettingsIOS =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const InitializationSettings initSettings = InitializationSettings(
//       android: initSettingsAndroid,
//       iOS: initSettingsIOS,
//     );
//
//     await notificationsPlugin.initialize(initSettings);
//     _isInitialized = true;
//   }
//
//   NotificationDetails _notificationDetails() {
//     return const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'grocery_channel',
//         'Grocery Reminders',
//         channelDescription: 'Scheduled reminder',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//       ),
//       iOS: DarwinNotificationDetails(
//         sound: 'default',
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       ),
//     );
//   }
//
//   Future<void> showNotification({
//     int id = 0,
//     String? title,
//     String? body,
//     String? payload,
//   }) async {
//     await notificationsPlugin.show(
//       id,
//       title,
//       body,
//       _notificationDetails(),
//       payload: payload,
//     );
//   }
//
//   Future<void> scheduleNotification({
//     int id = 1,
//     required String title,
//     required String body,
//     required int hour,
//     required int minute,
//   }) async {
//     if (!_isInitialized) await initNotification();
//
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     );
//
//     // If the scheduled time is already passed, schedule for next day
//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }
//
//     await notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       scheduledDate,
//       _notificationDetails(), // Use the same notification details
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
//       //matchDateTimeComponents: DateTimeComponents.time,
//     );
//
//     print(
//         "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
//   }
//
//   Future<void> cancelAllNotifications() async {
//     await notificationsPlugin.cancelAll();
//   }
// }
