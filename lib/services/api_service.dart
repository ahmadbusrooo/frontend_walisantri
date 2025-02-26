import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../utils/shared_preferences_helper.dart';

class ApiService {
  static const String baseUrl = "https://walisantri.ppalmaruf.com/api";

  // Build endpoint URL
  static String _buildUrl(String endpoint) {
    return "$baseUrl/$endpoint";
  }

  // General headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SharedPreferencesHelper.getToken();
    if (token == null || token.isEmpty) {
      print('Token kosong atau null. Pastikan Anda sudah login.'); // Debug log
      throw Exception('Token is missing or null. Please log in.');
    }
    print('Token yang dikirim ke API: $token'); // Debug log
    return {'Authorization': 'Bearer $token'};
  }

  // Fungsi untuk mendapatkan informasi perangkat
  static Future<String> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = "Unknown Device"; // Default value

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

    print("Device Info: $deviceName"); // Debugging
    return deviceName;
  }

  // 🔥 Login API dengan fcm_token
  static Future<Map<String, dynamic>> login(
      String nis, String password, String deviceInfo, String? fcmToken) async {
    try {
      print("Mengirim data login ke API:");
      print("NIS: $nis");
      print("Password: $password");
      print("Device Info: $deviceInfo");
      print("FCM Token: $fcmToken"); // 🔥 Debugging token

      final response = await http.post(
        Uri.parse(_buildUrl("login")),
        body: {
          'nis': nis,
          'password': password,
          'device_info': deviceInfo, // Menambahkan device_info ke request
          'fcm_token': fcmToken ?? "", // 🔥 Tambahkan FCM Token (default kosong jika null)
        },
      );

      print('Respons Login dari API: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Login: $e');
      throw Exception('Error during login: $e');
    }
  }

  // Logout API
  static Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_buildUrl("logout")),
        headers: headers,
      );

      print('Respons API [logout]: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Logout: $e');
      throw Exception('Error during logout: $e');
    }
  }

  // Edit Profile API
  static Future<Map<String, dynamic>> editProfile(
      String phone, String address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_buildUrl("profile/edit")),
        headers: headers,
        body: {
          'student_phone': phone,
          'student_address': address,
        },
      );

      print('Respons API [profile/edit]: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to edit profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Edit Profile: $e');
      throw Exception('Error during edit profile: $e');
    }
  }

  // Change Password API
  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_buildUrl("profile/change-password")),
        headers: headers,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      print('Respons API [profile/change-password]: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Change Password: $e');
      throw Exception('Error during change password: $e');
    }
  }

  // Fetch Student Data
  static Future<Map<String, dynamic>> fetchStudentData() async {
    return await _fetchWithRetry("profile");
  }

  // Fetch Dashboard Data
  static Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_buildUrl("dashboard")),
        headers: headers,
      );

      print('Respons API [dashboard]: ${response.body}'); // Debug log
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Fetching Dashboard Data: $e');
      throw Exception('Error Fetching Dashboard Data: $e');
    }
  }

  // Fetch Violation Data
  static Future<Map<String, dynamic>> fetchViolationData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_buildUrl("pelanggaran")),
        headers: headers,
      );

      print('Respons API [pelanggaran]: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch data [pelanggaran]: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Fetching Violation Data: $e');
      throw Exception('Error Fetching Violation Data: $e');
    }
  }

  // Fetch Health Data
  static Future<Map<String, dynamic>> fetchHealthData() async {
    return await _fetchWithRetry("health");
  }

  // Fetch Nadzhaman Data
  static Future<Map<String, dynamic>> fetchNadzhamanData() async {
    return await _fetchWithRetry("nadzhaman");
  }

  // Fetch Payment Data
 static Future<Map<String, dynamic>> fetchPaymentData({
  String? year,
  String? periodId,
}) async {
  final headers = await _getHeaders();
  final uri = Uri.parse(_buildUrl("payout"));
  final updatedUri = uri.replace(queryParameters: {
    if (year != null) 'year': year,
    if (periodId != null) 'period_id': periodId,
  });

  try {
    final response = await http.get(
      updatedUri,
      headers: headers,
    );

    print('Respons API [payout]: ${response.body}'); // Debug log
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch payment data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error Fetching Payment Data: $e');
    throw Exception('Error Fetching Payment Data: $e');
  }
}

  // Generalized function to fetch with retry
  static Future<Map<String, dynamic>> _fetchWithRetry(String endpoint) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await http.get(
          Uri.parse(_buildUrl(endpoint)),
          headers: headers,
        );

        print('Respons API [$endpoint]: ${response.body}'); // Debug log
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception(
              'Failed to fetch data [$endpoint]: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        print('Error Fetching Data [$endpoint] - Retry $retryCount: $e');
        if (retryCount == maxRetries) {
          throw Exception(
              'Failed to fetch data [$endpoint] after $maxRetries attempts: $e');
        }
      }
    }
    throw Exception('Unexpected error during fetch [$endpoint]');
  }
}






