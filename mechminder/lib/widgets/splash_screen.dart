import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart'; // Import your main home screen
import '../screens/paywall_screen.dart';
import '../service/subscription_provider.dart';
import '../service/vehicle_provider.dart';
import 'package:provider/provider.dart';


import '../service/user_provider.dart';
import '../service/auth_service.dart';
import '../service/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for Firebase.initializeApp
import '../service/api_service.dart'; // Added for ApiService

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 1. Initialize Essential Services (No SQLite needed)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      // Sync User Identity / Refresh FCM Token daily in background
      final uid = await AuthService.getUid();
      if (uid != null) {
        final fcmToken = await AuthService.getFcmToken();
        if (fcmToken != null) {
          await ApiService.updateFCMToken(uid, fcmToken);
        }
      }

      await NotificationService().initialize();
    } catch (e) {
      if (kDebugMode) print("!!! Background Init Error: $e");
      return Future.value(false);
    }

    // 2. Fetch Data from Cloud (Bulk Sync)
    final appData = await ApiService.fetchFullAppState();
    if (appData == null) {
      if (kDebugMode) print("!!! Background Sync Failed: No data fetched");
      return Future.value(false);
    }

    final String today = DateTime.now().toIso8601String().split('T')[0];
    if (kDebugMode) {
      print("Background: Checking for reminders/papers due on: $today");
    }

    final List<dynamic> allReminders = appData['reminders'] ?? [];
    final List<dynamic> allVehicles = appData['vehicles'] ?? [];
    final List<dynamic> allPapers = appData['vehicle_papers'] ?? [];

    // --- 1. Check for Service Reminders ---
    for (final reminder in allReminders) {
      if (reminder['status'] != 'pending') continue;

      bool isDue = false;
      final String? dueDate = reminder['due_date'];
      if (dueDate != null && dueDate.compareTo(today) == 0) {
        isDue = true;
      }

      // Note: Odometer-based reminders check in the background
      // requires the *latest* odometer which we just fetched.
      final int? dueOdo = reminder['due_odometer'];
      final vehicle = allVehicles.firstWhere(
        (v) => v['id'] == reminder['vehicle_id'],
        orElse: () => null,
      );
      final int currentOdo = vehicle?['current_odometer'] ?? 0;

      if (dueOdo != null && dueOdo > 0 && currentOdo >= dueOdo) {
        isDue = true;
      }

      if (isDue) {
        final int reminderId = reminder['id'];
        final String appName = inputData?['appName'] ?? 'MechMinder';
        final serviceName =
            reminder['template_name'] ?? reminder['notes'] ?? 'Service';
        final body = 'Your "$serviceName" service is due!';
        
        await NotificationService().showImmediateReminder(
          id: reminderId,
          title: appName,
          body: body,
        );
      }
    }

    // --- 2. Check for Expiring Papers ---
    for (final paper in allPapers) {
      final String? expiryDate = paper['paper_expiry_date'];
      if (expiryDate != null && expiryDate == today) {
        final vehicle = allVehicles.firstWhere(
          (v) => v['id'] == paper['vehicle_id'],
          orElse: () => null,
        );
        final String vehicleName =
            vehicle != null
                ? '${vehicle['make']} ${vehicle['model']}'
                : 'Vehicle';
        final String paperType = paper['paper_type'] ?? 'Paper';
        final String body = 'Your $paperType for $vehicleName expires today!';

        int notificationId = 100000 + (paper['id'] as int);
        await NotificationService().showImmediateReminder(
          id: notificationId,
          title: 'Vehicle Paper Expiring',
          body: body,
        );
      }
    }

    if (kDebugMode) {
      print("--- Background Sync Task Complete ---");
    }
    return Future.value(true);
  });
}

// --- END OF BACKGROUND TASK ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static bool _setupTriggered = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  String _statusMessage = "";
  bool _hasError = false;

  void _initializeAndNavigate() async {
    // 1. Only run setup once to prevent double-calls on theme rebuilds
    if (_setupTriggered) return;
    _setupTriggered = true;

    setState(() {
      _hasError = false;
      _statusMessage = "Starting up...";
    });

    // 2. Setup Timer (minimum splash duration)
    Future<void> gifTimer = Future.delayed(const Duration(seconds: 4));

    // 3. Setup Logic
    bool success = false;
    Future<void> appSetup = () async {
      try {
        await NotificationService().initialize();

        // Permission request moved to a background-ish way to avoid blocking
        NotificationService().requestPermissions();

        // --- Sync User with Backend (Multi-Level Identity Check) ---
        if (mounted) {
          setState(() => _statusMessage = "Identifying your account...");
          
          await AuthService.initialize();
          
          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);

            // Wait for subscription provider to at least try loading purchases
            int subRetries = 0;
            while (subProvider.isLoading && subRetries < 30) {
              await Future.delayed(const Duration(milliseconds: 100));
              subRetries++;
            }

            // High Priority: If we have a premium purchase, use that ID to restore account data
            String? currentPurchaseId = subProvider.purchaseID;
            
            // Sync current identity (Purchase ID > UID > FCM Token)
            await userProvider.syncUser(purchaseId: currentPurchaseId);

            if (mounted) {
              setState(() => _statusMessage = "Restoring your data...");
              final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
              
              // Pull all cloud-synced data for the identified user
              await vehicleProvider.syncAllData();
            }
          }
        }

        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        await Workmanager().registerPeriodicTask(
          "1",
          "checkVehicleReminders",
          frequency: const Duration(days: 1),
          initialDelay: const Duration(minutes: 15),
        );
        success = true;
      } catch (e) {
        if (kDebugMode) print("!!! ERROR DURING APP INIT: $e");
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusMessage = "Connection failed. Please check your internet.";
          });
        }
      }
    }();

    // 3. Wait for BOTH the timer AND your setup to finish
    await Future.wait([gifTimer, appSetup]);

    if (!success) {
      _setupTriggered = false; // Allow retry
      return;
    }

    // 4. Check Subscription Status
    if (!mounted) return;
    final subProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );

    // Wait for provider to initialize just in case
    int retries = 0;
    while (subProvider.isLoading && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (!subProvider.canAccessApp) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(isBarrier: true),
          ),
        );
      }
      return;
    }

    // 5. Check Onboarding Status
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // 6. Now, navigate
    if (mounted) {
      if (hasSeenOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Lottie.asset(
              'assets/animations/car_animation.json',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          if (_statusMessage.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: _hasError ? Colors.redAccent : Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _initializeAndNavigate,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry Connection"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

