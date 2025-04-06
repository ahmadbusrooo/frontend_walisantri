import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:async';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  String _deviceInfo = "Unknown Device";
  bool _isOffline = false;
  String? _fcmToken;
  Color _nisBorderColor = Colors.grey[300]!;
  Color _passwordBorderColor = Colors.grey[300]!;
  Color _nisBackgroundColor = Colors.transparent;
  Color _passwordBackgroundColor = Colors.transparent;
  StreamSubscription? _connectivitySubscription;

  // Tambahan untuk tutorial
  int _currentTutorialStep = 0;
  final LayerLink _nisLayerLink = LayerLink();
  final LayerLink _passwordLayerLink = LayerLink();
  OverlayEntry? _tutorialOverlay;
  final GlobalKey _nisFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  String? _selectedUnit; // 'putra' atau 'putri'

  bool _validateUnit() {
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih unit pondok terlebih dahulu')),
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedUnit();
    _getDeviceInfo();
    _getFcmToken();
    _checkFirstInstall();
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription =
        ConnectivityService.connectionStream.listen((isConnected) {
      setState(() => _isOffline = !isConnected);
    });
  }

  Future<void> _loadSavedUnit() async {
    final savedUnit = await SharedPreferencesHelper.getSelectedUnit();
    if (savedUnit != null) {
      setState(() {
        _selectedUnit = savedUnit;
      });
      ApiService.setBaseUrl(savedUnit); // Set base URL sesuai yang disimpan
    }
  }

  // TAMBAHKAN METHOD-METHOD BARU INI
  void _checkFirstInstall() async {
    bool firstInstall = await SharedPreferencesHelper.isFirstInstall();
    if (firstInstall) {
      await SharedPreferencesHelper.setFirstInstall(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotificationPermissionDialog();
      });
    } else {
      _checkTutorial();
    }
  }

  void _checkTutorial() async {
    bool tutorialShown = await SharedPreferencesHelper.isTutorialShown();
    if (!tutorialShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial();
      });
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active_rounded,
                  size: 48, color: Colors.teal),
              SizedBox(height: 16),
              Text(
                "Izin Notifikasi",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Dapatkan info terbaru tentang perkembangan putra/putri Anda",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _checkTutorial();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Nanti",
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _setupFCM();
                        _checkTutorial();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Izinkan",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = "6282235968001"; // Ganti dengan nomor admin
    final message = "Halo min, saya lupa password saya. Mohon bantuannya";

    final url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("WhatsApp tidak terinstall")),
      );
    }
  }

  Future<void> _setupFCM() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Izin notifikasi diberikan");
    }
  }

  void _showTutorial() {
    setState(() {
      _nisBorderColor = Colors.amber;
      _nisBackgroundColor = Colors.amber.withOpacity(0.1);
      _passwordBorderColor = Colors.grey[300]!;
      _passwordBackgroundColor = Colors.transparent;
    });
    _tutorialOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _nextTutorialStep,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: Colors.transparent,
          child: Stack(
            children: [
              if (_currentTutorialStep == 0)
                _buildTutorialStep(
                  context,
                  targetKey: _nisFieldKey,
                  text: "Masukkan NIS Anda di kolom ini",
                ),
              if (_currentTutorialStep == 1)
                _buildTutorialStep(
                  context,
                  targetKey: _passwordFieldKey,
                  text: "Masukkan password Anda di kolom ini",
                ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_tutorialOverlay!);
  }

  Widget _buildTutorialStep(BuildContext context,
      {required GlobalKey targetKey, required String text}) {
    final RenderBox renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      left: offset.dx + (size.width / 2) - (screenWidth - 40) / 2,
      top: offset.dy + size.height + 15,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            CustomPaint(
              size: Size(24, 12),
              painter: _ArrowPainter(),
            ),
            Container(
              width: screenWidth - 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_currentTutorialStep + 1}/2",
                          style: TextStyle(
                              color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _nextTutorialStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          _currentTutorialStep == 0
                              ? "Selanjutnya"
                              : "Mengerti",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextTutorialStep() {
    if (_currentTutorialStep < 1) {
      setState(() {
        _currentTutorialStep++;
        _passwordBorderColor = Colors.amber;
        _passwordBackgroundColor = Colors.amber.withOpacity(0.1);
        _nisBorderColor = Colors.grey[300]!;
        _nisBackgroundColor = Colors.transparent;
      });
      _tutorialOverlay?.markNeedsBuild();
    } else {
      setState(() {
        _nisBorderColor = Colors.grey[300]!;
        _passwordBorderColor = Colors.grey[300]!;
        _nisBackgroundColor = Colors.transparent;
        _passwordBackgroundColor = Colors.transparent;
      });
      _tutorialOverlay?.remove();
      SharedPreferencesHelper.setTutorialShown(true);
    }
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
    if (_selectedUnit == null) {
      // Pindahkan validasi unit ke sini
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih unit pondok terlebih dahulu')),
      );
      return false;
    }
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
    if (!_validateUnit() || !_validateInput()) return;

final isConnected = await ConnectivityService.isConnected();
  if (!isConnected) {
    setState(() => _isOffline = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tidak ada koneksi internet.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
    ApiService.setBaseUrl(_selectedUnit!);
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
        _fcmToken, // 🔥 Kirim FCM Token ke backend
      );

      if (response['status']) {
        final token = response['data']['token'];

        await SharedPreferencesHelper.saveToken(token);
        await SharedPreferencesHelper.setLoggedIn(true);
        await SharedPreferencesHelper.saveSelectedUnit(_selectedUnit!);

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
                  colors: [
                    Colors.teal.shade300,
                    const Color.fromARGB(255, 12, 111, 95)
                  ],
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
          top: 280,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isOffline ? 50 : 0,
            color: Colors.red,
            child: Center(
              child: Text(
                'Tidak ada koneksi internet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),

                    // TAMBAHKAN COMPOSITED TRANSFORM TARGET
                    CompositedTransformTarget(
                      link: _nisLayerLink,
                      child: TextField(
                        key: _nisFieldKey,
                        controller: _nisController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _nisBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: _nisBorderColor, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: _nisBorderColor, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: _nisBorderColor, width: 2),
                          ),
                          labelText: 'NIS',
                          labelStyle: TextStyle(color: Colors.teal),
                          prefixIcon: Icon(Icons.person, color: Colors.teal),
                        ),
                        onEditingComplete: () => FocusScope.of(context)
                            .requestFocus(_passwordFocusNode),
                      ),
                    ),
                    SizedBox(height: 20),
                    CompositedTransformTarget(
                      link: _passwordLayerLink,
                      child: TextField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _passwordBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _passwordBorderColor, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _passwordBorderColor, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _passwordBorderColor, width: 2),
                          ),
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.teal),
                          prefixIcon: Icon(Icons.lock, color: Colors.teal),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
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
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Unit Pondok',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('Putra'),
                                  value: 'putra',
                                  groupValue: _selectedUnit,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnit = value;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: Colors.teal,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('Putri'),
                                  value: 'putri',
                                  groupValue: _selectedUnit,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnit = value;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _launchWhatsApp,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
      child: Text('LOGIN',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
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



class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TutorialStep extends StatelessWidget {
  final String text;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;

  const _TutorialStep({
    required this.text,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${currentStep + 1}/$totalSteps"),
                ElevatedButton(
                  onPressed: onNext,
                  child:
                      Text(currentStep < totalSteps - 1 ? "Lanjut" : "Selesai"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
