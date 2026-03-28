import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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

  Future<void> syncUser({String? purchaseId}) {
    // If a sync is already in progress, return the existing future
    _syncFuture ??= _performSync(purchaseId);
    return _syncFuture!;
  }

  Future<void> _performSync(String? purchaseId) async {
    try {
      final uid = await AuthService.getUid();
      if (uid == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      // Multi-Level Identity Payload: 
      // 1. Purchase ID (Strongest link for restore)
      // 2. UID (Direct link)
      // 3. FCM Token (Device link fallback)
      
      final prefs = await SharedPreferences.getInstance();
      final String? trialDate = prefs.getString('trial_start_date_v1');

      // NEW: Capture physical device ID as a test/dev restore fallback
      String? deviceId;
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id; // Stable on Android
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor; // Stable on iOS
        }
      } catch (e) {
        // Silently fail device ID capture
      }

      final userData = {
        'firebase_uid': uid,
        'fcm_token': fcmToken,
        if (purchaseId != null) 'purchase_id': purchaseId,
        if (deviceId != null) 'device_id': deviceId,
        if (trialDate != null) 'trial_start_date': trialDate,
      };

      // We use the same endpoint as it handles the logic of correlating these three factors
      final savedUser = await ApiService.syncUserAndFCM(userData);
      
      if (savedUser != null && savedUser['user'] != null) {
        _user = UserModel.fromJson(savedUser['user']);
        notifyListeners();
      }
    } catch (e) {
      // Error handling is managed by the caller observing the sync state
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

      // Get Device ID
      String? deviceId;
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        }
      } catch (e) {}

      await ApiService.updatePurchaseId(
        uid,
        purchaseId,
        fcmToken: fcmToken,
        deviceId: deviceId, // Pass the device link too
      );
      
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
    }
  }
}
