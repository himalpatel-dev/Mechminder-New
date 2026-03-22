import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  StreamSubscription<String>? _tokenSubscription;
  Future<void>? _syncFuture;
  String? _lastPurchaseId; // Debounce duplicate purchase events

  UserModel? get user => _user;

  UserProvider() {
    // Listen for FCM token refreshes
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Use the same sync logic for consistency
      syncUser();
    });
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    super.dispose();
  }

  Future<void> syncUser() {
    // If a sync is already in progress, return the existing future
    _syncFuture ??= _performSync();
    return _syncFuture!;
  }

  Future<void> _performSync() async {
    try {
      final uid = await AuthService.getUid();
      if (uid == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      final userData = {
        'firebase_uid': uid,
        'fcm_token': fcmToken,
      };

      final savedUser = await ApiService.syncUserAndFCM(userData);
      
      if (savedUser != null && savedUser['user'] != null) {
        _user = UserModel.fromJson(savedUser['user']);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("UserProvider syncUser Error: $e");
    } finally {
      // Clear after a small delay to allow immediate duplicate hits to be blocked
      Future.delayed(const Duration(seconds: 2), () => _syncFuture = null);
    }
  }

  Future<void> updateFCMToken() async {
    // Simply call syncUser() which handles the guard and token update properly
    await syncUser();
  }

  Future<void> updatePurchase(String purchaseId) async {
    // 1. Debounce duplicate purchase ID events from the stream
    if (_lastPurchaseId == purchaseId) return;
    _lastPurchaseId = purchaseId;

    try {
      final uid = await AuthService.getUid();
      if (uid == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      await ApiService.updatePurchaseId(uid, purchaseId, fcmToken: fcmToken);
      
      // Update local state if user is loaded
      if (_user != null) {
        _user = UserModel(
          firebaseUid: _user!.firebaseUid,
          fcmToken: fcmToken ?? _user!.fcmToken,
          purchaseId: purchaseId,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _lastPurchaseId = null; // Reset on error
      if (kDebugMode) print("UserProvider updatePurchase Error: $e");
    }
  }
}
