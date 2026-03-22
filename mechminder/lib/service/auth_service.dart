import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static String? _uid;
  static Future<void>? _initFuture;

  static String? get uid => _uid;

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

      if (kDebugMode) {
        print("MechMinder: Identified as Anonymous User: $_uid");
      }
    } catch (e) {
      _initFuture = null; // Clear future to allow retry on error
      if (kDebugMode) {
        print("MechMinder Auth Error: $e");
      }
    }
  }

  // Force refresh or get current UID
  static Future<String?> getUid() async {
    if (_uid != null) return _uid;
    await initialize();
    return _uid;
  }

  static Future<String?> getFcmToken() async {
    try {
      // Import needed manually if not auto-added
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("MechMinder FCM Error: $e");
      }
      return null;
    }
  }
}
