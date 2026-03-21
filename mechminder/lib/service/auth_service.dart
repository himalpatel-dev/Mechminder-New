import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static String? _uid;

  static String? get uid => _uid;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Anonymous Sign-in
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _uid = userCredential.user?.uid;

      if (kDebugMode) {
        print("MechMinder: Identified as Anonymous User: $_uid");
      }
    } catch (e) {
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
}
