// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   static Future<void> initialize() async {
//     // Request permissions
//     await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Initialize local notifications
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _localNotifications.initialize(initSettings);
//
//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//   }
//
//   static Future<String?> getToken() async {
//     return await _messaging.getToken();
//   }
//
//   static Future<void> subscribeToTopic(String topic) async {
//     await _messaging.subscribeToTopic(topic);
//   }
//
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     await _messaging.unsubscribeFromTopic(topic);
//   }
//
//   static Future<void> showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'pms_channel',
//       'Property Management System',
//       channelDescription: 'Notifications for Property Management System',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const iosDetails = DarwinNotificationDetails();
//
//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     await _localNotifications.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000),
//       title,
//       body,
//       notificationDetails,
//       payload: payload,
//     );
//   }
//
//   static void _handleForegroundMessage(RemoteMessage message) {
//     showLocalNotification(
//       title: message.notification?.title ?? 'PMS Notification',
//       body: message.notification?.body ?? 'You have a new notification',
//       payload: message.data['payload'],
//     );
//   }
// }
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Handle background message
// }