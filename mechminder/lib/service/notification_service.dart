import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';


// --- THIS IS THE NEW CHANNEL WE WILL CREATE ---
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'vehicle_reminders_channel', // Updated ID to force refresh
  'Vehicle Reminders',
  description: 'Notifications for vehicle maintenance and paper expiry',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      // Silent init fail
    }
  }

  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    // Handle notification click if needed
  }

  Future<void> showImmediateReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/launcher_icon', // Use project's specific icon name
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'reminder_id_$id',
    );
  }

  /// Centralized method to check all pending reminders for a vehicle
  /// and trigger notifications if they are due based on the given odometer.
  Future<void> checkAndShowOdometerReminders({
    required List<dynamic> reminders,
    required int currentOdometer,
    required String unitType,
  }) async {
    final String today = DateTime.now().toIso8601String().split('T')[0];

    for (var reminder in reminders) {
      final dynamic dueOdoRaw = reminder['due_odometer'];
      final String? dueDate = reminder['due_date'];
      final int? dueOdo = dueOdoRaw is int
          ? dueOdoRaw
          : int.tryParse(dueOdoRaw?.toString() ?? '');

      bool shouldNotify = false;
      String reason = "";

      // Odometer Check
      if (dueOdo != null && dueOdo > 0 && currentOdometer >= dueOdo) {
        shouldNotify = true;
        reason = "Reached $dueOdo $unitType";
      }

      // Date Check (Due Today)
      if (dueDate != null && dueDate == today) {
        shouldNotify = true;
        reason = "Due today ($dueDate)";
      }

      if (shouldNotify && reminder['status'] == 'pending') {
        final int reminderId = reminder['id'];
        final String templateName =
            reminder['template_name'] ??
            reminder['notes'] ??
            'Service';

        await showImmediateReminder(
          id: reminderId,
          title: 'Vehicle Maintenance Due',
          body: 'Your "$templateName" is due! ($reason)',
        );
      }
    }
  }
}

