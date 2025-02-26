import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 Tambahkan Firebase Messaging
import 'dart:io';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_helper.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _deviceInfo = "Unknown Device"; // Default value
  String? _fcmToken; // 🔥 Token FCM

  @override
  void initState() {
    super.initState();
    _getDeviceInfo(); // Panggil fungsi untuk mendapatkan info perangkat saat pertama kali membuka login
    _getFcmToken(); // 🔥 Ambil FCM Token saat aplikasi dijalankan
  }

  // 🔥 Fungsi untuk mendapatkan FCM Token
  Future<void> _getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      String? token = await messaging.getToken();
      setState(() {
        _fcmToken = token;
      });

      print("FCM Token: $_fcmToken"); // Debugging
    } catch (e) {
      print("Gagal mendapatkan FCM Token: $e");
    }
  }

  // Fungsi untuk mendapatkan informasi perangkat
  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = "Unknown Device";

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = "Android - ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = "iOS - ${iosInfo.utsname.machine}";
      }
    } catch (e) {
      print("Gagal mendapatkan info perangkat: $e");
    }

    setState(() {
      _deviceInfo = deviceName;
    });

    print("Device Info: $_deviceInfo"); // Debugging
  }

  // Fungsi untuk validasi input sebelum login
  bool _validateInput() {
    if (_nisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NIS tidak boleh kosong')),
      );
      return false;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password tidak boleh kosong')),
      );
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("Mengirim data login ke API:");
      print("NIS: ${_nisController.text}");
      print("Password: ${_passwordController.text}");
      print("Device Info: $_deviceInfo");
      print("FCM Token: $_fcmToken"); // Debugging

      final response = await ApiService.login(
        _nisController.text,
        _passwordController.text,
        _deviceInfo, // Kirim device_info ke API
        _fcmToken,  // 🔥 Kirim FCM Token ke backend
      );

      if (response['status']) {
        final token = response['data']['token'];

        await SharedPreferencesHelper.saveToken(token);
        await SharedPreferencesHelper.setLoggedIn(true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade300, const Color.fromARGB(255, 12, 111, 95)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 130.0, left: 20.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assalamualaikum',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Selamat Datang Walisantri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 230,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    TextField(
                      controller: _nisController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'NIS',
                        labelStyle: TextStyle(color: Colors.teal),
                        prefixIcon: Icon(Icons.person, color: Colors.teal),
                      ),
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordFocusNode),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      focusNode: _passwordFocusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.teal),
                        prefixIcon: Icon(Icons.lock, color: Colors.teal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.teal,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            child: Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                    SizedBox(height: 240),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
