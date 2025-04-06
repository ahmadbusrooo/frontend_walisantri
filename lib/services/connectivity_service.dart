import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  // Cek status koneksi real-time
  static Stream<bool> get connectionStream => Connectivity()
      .onConnectivityChanged
      .asyncMap((result) => _isInternetAvailable(result));

  // Cek koneksi internet saat ini
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return _isInternetAvailable(connectivityResult);
  }

  // Cek apakah benar-benar terhubung ke internet
  static Future<bool> _isInternetAvailable(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) return false;
    return await InternetConnectionChecker().hasConnection;
  }
}