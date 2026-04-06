import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream for in-app notification alerts
  final _notificationStreamController =
      StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onNotificationReceived =>
      _notificationStreamController.stream;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request permissions
    if (!kIsWeb) {
      await requestPermissions();
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    if (!kIsWeb) {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification tap
          print('Notification tapped: ${details.payload}');
        },
      );
    }

    // 3. Initialize Timezone
    tz_data.initializeTimeZones();

    // 4. Handle FCM background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'FCM Message received in foreground: ${message.notification?.title}');
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'New Message',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    _isInitialized = true;
    print('Notification Service Initialized');
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // 1. Notify listeners (for in-app SnackBar)
    _notificationStreamController.add({'title': title, 'body': body});

    // 2. Persist notification to Firestore for the history center (all platforms)
    await _saveNotificationToFirestore(
        title: title, body: body, payload: payload);

    // 3. Show System Notification (Mobile/Desktop supported only)
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'skillswap_notifications',
      'SkillSwap Notifications',
      channelDescription: 'Notifications for skill updates and requests',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    String? payload,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notification = NotificationModel(
      id: '',
      userId: user.uid,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      payload: payload,
    );

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification.toMap());
      print('DEBUG: Notification saved to Firestore history');
    } catch (e) {
      print('ERROR: Failed to save notification to history: $e');
    }
  }

  // --- Matchmaking Logic (Practical Scenario) ---

  void startMatchmakingListener(String currentUserId) {
    print('DEBUG: Starting matchmaking listener for user: $currentUserId');

    // Listen for NEW offered skills
    FirebaseFirestore.instance
        .collection('offeredSkills')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final skillData = change.doc.data() as Map<String, dynamic>;
          final ownerId = skillData['userId'];
          final skillName = skillData['name'];

          if (ownerId == currentUserId)
            continue; // Don't notify about own skills

          // Check if this skill matches ANY of current user's wanted skills
          final wantedSnapshot = await FirebaseFirestore.instance
              .collection('wantedSkills')
              .where('userId', isEqualTo: currentUserId)
              .get();

          for (var wantedDoc in wantedSnapshot.docs) {
            final wantedName = wantedDoc.data()['name'] as String;

            // Simple case-insensitive match
            if (skillName.toLowerCase().contains(wantedName.toLowerCase()) ||
                wantedName.toLowerCase().contains(skillName.toLowerCase())) {
              print('MATCH FOUND: $skillName matches wanted $wantedName');

              showLocalNotification(
                title: 'Skill Match Found! 🎯',
                body:
                    'Someone just offered "$skillName", which matches your interest in "$wantedName".',
                payload: 'discover',
              );
              break;
            }
          }
        }
      }
    });
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skillswap_reminders',
          'SkillSwap Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    if (!kIsWeb) {
      await _localNotifications.cancelAll();
    }
  }

  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}

// Global function for background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
