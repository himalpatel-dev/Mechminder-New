import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AuthService {
  static String? _uid;
  static String? _deviceId;
  static Future<void>? _initFuture;

  static String? get uid => _uid;
  static String? get deviceId => _deviceId;

  static Future<void> initialize() {
    _initFuture ??= _realInitialize();
    return _initFuture!;
  }

  static Future<void> _realInitialize() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Anonymous Sign-in
      final userCredential = await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 10));
      _uid = userCredential.user?.uid;

      // New: Capture Device identity for account restoration
      if (_deviceId == null) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        try {
          if (Platform.isAndroid) {
            final androidInfo = await deviceInfo.androidInfo;
            // First try 'id', then fallback to serial/physical markers if possible
            _deviceId = androidInfo.id;
            if (_deviceId == null || _deviceId!.isEmpty || _deviceId == 'unknown') {
              _deviceId = androidInfo.hardware + androidInfo.model + androidInfo.board;
            }
          } else if (Platform.isIOS) {
            final iosInfo = await deviceInfo.iosInfo;
            _deviceId = iosInfo.identifierForVendor;
          }
        } catch (e) {
          // Device ID capture is best-effort
        }
      }
    } catch (e) {
      _initFuture = null; // Clear future to allow retry on error
    }
  }

  // Force refresh or get current UID
  static Future<String?> getUid() async {
    if (_uid != null) return _uid;
    await initialize();
    return _uid;
  }

  static Future<String?> getDeviceId() async {
    if (_deviceId != null) return _deviceId;
    await initialize();
    return _deviceId;
  }

  static Future<String?> getFcmToken() async {
    try {
      // Import needed manually if not auto-added
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return null;
    }
  }
}
