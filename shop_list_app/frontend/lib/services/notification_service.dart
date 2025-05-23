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
      'Teszt értesítés',
      'Ez egy azonnali értesítés.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Teszt csatorna',
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

    // Csak akkor ütemezzük az értesítést, ha ez a felhasználó benne van
    if (!sharedWith.contains(currentUser.uid)) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime.toDate(), tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      listId.hashCode, // Unique ID
      'Bevásárlólista emlékeztető',
      'Ekkor lesz a bevasarlas',
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
