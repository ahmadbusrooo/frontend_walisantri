import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static SharedPreferences? _prefs;
  static const String _tokenKey = 'token'; // Token autentikasi
  static const String _fcmTokenKey = 'fcm_token'; // Token FCM
  static const String _loggedInKey = 'loggedIn';

  // Inisialisasi SharedPreferences saat aplikasi dimulai
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('[SharedPreferencesHelper] SharedPreferences diinisialisasi.');
  }

  // 🔹 Simpan token autentikasi
  static Future<void> saveToken(String token) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.setString(_tokenKey, token);
      print('[SharedPreferencesHelper] Token berhasil disimpan.');
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menyimpan token: $e');
    }
  }

  // 🔹 Ambil token autentikasi
  static Future<String?> getToken() async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getString(_tokenKey);
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal mengambil token: $e');
      return null;
    }
  }

  // 🔹 Simpan token FCM
  static Future<void> saveFCMToken(String token) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.setString(_fcmTokenKey, token);
      print('[SharedPreferencesHelper] Token FCM berhasil disimpan.');
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menyimpan token FCM: $e');
    }
  }

  // 🔹 Ambil token FCM
  static Future<String?> getFCMToken() async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getString(_fcmTokenKey);
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal mengambil token FCM: $e');
      return null;
    }
  }

  // 🔹 Hapus token FCM
  static Future<void> clearFCMToken() async {
    try {
      if (_prefs == null) await initialize();
      if (_prefs!.containsKey(_fcmTokenKey)) {
        await _prefs!.remove(_fcmTokenKey);
        print('[SharedPreferencesHelper] Token FCM berhasil dihapus.');
      }
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menghapus token FCM: $e');
    }
  }
static const String _keyIsFirstInstall = 'isFirstInstall';
static const String _keyIsTutorialShown = 'isTutorialShown';

static Future<bool> isFirstInstall() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyIsFirstInstall) ?? true;
}

static Future<void> setFirstInstall(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyIsFirstInstall, value);
}

static Future<bool> isTutorialShown() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyIsTutorialShown) ?? false;
}

static Future<void> setTutorialShown(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyIsTutorialShown, value);
}
  // 🔹 Simpan status login
  static Future<void> setLoggedIn(bool value) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.setBool(_loggedInKey, value);
      print('[SharedPreferencesHelper] Status login disimpan: $value');
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menyimpan status login: $e');
    }
  }

  // 🔹 Ambil status login
  static Future<bool> getLoggedIn() async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getBool(_loggedInKey) ?? false;
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal mengambil status login: $e');
      return false;
    }
  }

  // 🔹 Hapus token autentikasi
  static Future<void> clearToken() async {
    try {
      if (_prefs == null) await initialize();
      if (_prefs!.containsKey(_tokenKey)) {
        await _prefs!.remove(_tokenKey);
        print('[SharedPreferencesHelper] Token berhasil dihapus.');
      }
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menghapus token: $e');
    }
  }

  // 🔹 Hapus status login
  static Future<void> clearLoggedIn() async {
    try {
      if (_prefs == null) await initialize();
      if (_prefs!.containsKey(_loggedInKey)) {
        await _prefs!.remove(_loggedInKey);
        print('[SharedPreferencesHelper] Status login berhasil dihapus.');
      }
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menghapus status login: $e');
    }
  }

  // 🔹 Hapus semua data
  static Future<void> clear() async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.clear();
      print('[SharedPreferencesHelper] Semua data berhasil dihapus.');
    } catch (e) {
      print('[SharedPreferencesHelper] Gagal menghapus semua data: $e');
    }
  }
}
