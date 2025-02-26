import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../utils/shared_preferences_helper.dart';

class MyFirebaseMessagingService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Konfigurasi notifikasi lokal untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notifikasi diklik: ${response.payload}");
      },
    );

    // Konfigurasi Firebase Cloud Messaging
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("Notifikasi diterima saat app tertutup: ${message.notification?.title}");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notifikasi diterima saat app terbuka: ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notifikasi diklik dari background: ${message.notification?.title}");
    });
  }

  // Fungsi untuk menampilkan notifikasi lokal
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel',
      'Notifikasi Umum',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "Notifikasi Baru",
      message.notification?.body ?? "Anda memiliki pesan baru",
      platformChannelSpecifics,
      payload: "Payload data",
    );
  }

  // Fungsi untuk mendapatkan dan menyimpan token FCM
  static Future<void> fetchAndSaveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await SharedPreferencesHelper.saveToken(token);
      print("Token FCM berhasil disimpan: $token");
    }
  }
}
