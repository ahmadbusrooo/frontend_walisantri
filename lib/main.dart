import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/NotificationDetailScreen.dart'; // Tambahkan layar detail notifikasi
import 'utils/shared_preferences_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/api_service.dart';

// Inisialisasi notifikasi lokal
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler untuk pesan yang diterima saat aplikasi berjalan di background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("📩 [Background] Notifikasi diterima: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding sudah diinisialisasi
  await initializeDateFormatting('id_ID', null); // Inisialisasi format tanggal
  await Firebase.initializeApp();
  await SharedPreferencesHelper.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  final savedUnit = await SharedPreferencesHelper.getSelectedUnit();
  if (savedUnit != null) {
    ApiService.setBaseUrl(savedUnit);
  }

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Jika pengguna menekan notifikasi saat aplikasi terbuka
      print("📩 Notifikasi diklik: ${response.payload}");
      if (response.payload != null) {
        navigatorKey.currentState?.pushNamed(
          response.payload!,
        );
      }
    },
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    setupFCM();

    // Tangani notifikasi jika aplikasi dibuka dari notifikasi (terminated)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Minta izin notifikasi
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Izin diberikan untuk menerima notifikasi");
      messaging.subscribeToTopic('all_users'); // Berlangganan topik semua pengguna
    } else {
      print("❌ Izin ditolak");
    }

    // Dapatkan token FCM dan simpan ke SharedPreferences
    String? fcmToken = await messaging.getToken();
    print("🔑 FCM Token: $fcmToken");

    if (fcmToken != null) {
      await SharedPreferencesHelper.saveFCMToken(fcmToken);
      print("💾 Token FCM disimpan ke SharedPreferences");
    }

    // Tangani notifikasi saat aplikasi berjalan di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 [Foreground] Notifikasi diterima: ${message.notification?.title}");
      showNotification(message);
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    print("🚀 Notifikasi diklik dari background: ${message.notification?.title}");
    print("📦 Payload Data: ${message.data}");

    if (message.data.containsKey("route") && message.data.containsKey("extra_data")) {
      String route = message.data["route"]!;
      String extraData = message.data["extra_data"]!;

      try {
        Map<String, dynamic> parsedData = json.decode(extraData);
        print("✅ JSON Decoded Data: $parsedData");

        navigatorKey.currentState?.pushNamed(
          route,
          arguments: parsedData,
        );
      } catch (e) {
        print("❌ Error parsing JSON: $e");
      }
    }
  }

  // 🔹 Fungsi untuk menampilkan notifikasi lokal di layar
  void showNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'high_importance_channel', // ID channel
      'High Importance Notifications', // Nama channel
      channelDescription: 'Notifikasi ini akan muncul di layar kunci.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      visibility: NotificationVisibility.public, // Notifikasi bisa muncul di lock screen
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      message.notification?.title ?? "Notifikasi Baru",
      message.notification?.body ?? "Anda memiliki pesan baru.",
      platformChannelSpecifics,
      payload: message.data['route'] ?? '/',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walisantri PPAM',
      navigatorKey: navigatorKey, // Gunakan navigator key untuk navigasi FCM
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/notification_detail': (context) => NotificationDetailScreen(), // Tambahkan layar notifikasi
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final isLoggedIn = await SharedPreferencesHelper.getLoggedIn();
        final token = await SharedPreferencesHelper.getToken();

        if (isLoggedIn && token != null) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/logoapss.png',
                width: MediaQuery.of(context).size.width * 0.5, // ✅ Responsif
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
