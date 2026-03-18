import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream theo dõi trạng thái mạng real-time
  Stream<bool> get connectionStream =>
      _connectivity.onConnectivityChanged.map((results) =>
          results.any((r) => r != ConnectivityResult.none));

  /// Kiểm tra kết nối hiện tại
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
