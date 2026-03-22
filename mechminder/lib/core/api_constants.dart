class ApiConstants {
  static const String serverUrl = 'http://192.168.29.155:5000';
  static const String baseUrl = '$serverUrl/api';

  // Auth
  static const String tokenEndpoint = '/auth/token';

  // Vehicles
  static const String vehicles = '/vehicles';
  static const String vehicleDetails = '/vehicles/{id}';
  static const String vehicleOdometer = '/vehicles/{id}/odometer';

  // To-Do
  static const String todosPending = '/todos/pending';
  static const String todosCompleted = '/todos/completed';
  static const String todosAction = '/todos';
  static const String todoStatus = '/todos/{id}/status';
  static const String todoDelete = '/todos/{id}';

  // Vendors
  static const String vendors = '/vendors';

  // Services & Reminders
  static const String services = '/services';
  static const String vehicleServices = '/vehicles/{vehicleId}/services';
  static const String serviceDetails = '/services/{serviceId}';

  static const String reminders = '/reminders';
  static const String vehicleReminders = '/vehicles/{vehicleId}/reminders';

  static const String expenses = '/expenses';
  static const String vehicleExpenses = '/vehicles/{vehicleId}/expenses';

  static const String papers = '/papers';
  static const String vehiclePapers = '/vehicles/{vehicleId}/papers';

  // Templates
  static const String templates = '/templates';

  // Users
  static const String userUpdateFCM = '/users/fcm-token';
  static const String userUpdatePurchase = '/users/purchase-link';
}
