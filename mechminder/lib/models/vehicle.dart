import '../core/api_constants.dart';

class Vehicle {
  final int? id;
  final String make;
  final String model;
  final String? variant;
  final String? purchaseDate;
  final String fuelType;
  final String? vehicleColor;
  final String? regNo;
  final String ownerName;
  final int? initialOdometer;
  final int? currentOdometer;
  final String? odometerUpdatedAt;
  final String? photoUri;
  final String? nextReminderDate;
  final int? nextReminderOdometer;
  final String? templateName;

  // Spending totals
  final double serviceTotal;
  final double expenseTotal;

  Vehicle({
    this.id,
    required this.make,
    required this.model,
    this.variant,
    this.purchaseDate,
    required this.fuelType,
    this.vehicleColor,
    this.regNo,
    required this.ownerName,
    this.initialOdometer,
    this.currentOdometer,
    this.odometerUpdatedAt,
    this.photoUri,
    this.nextReminderDate,
    this.nextReminderOdometer,
    this.templateName,
    this.serviceTotal = 0.0,
    this.expenseTotal = 0.0,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    // Handle nested Photos from API
    String? photoUri = map['photo_uri'];
    if (photoUri == null &&
        map['Photos'] != null &&
        (map['Photos'] as List).isNotEmpty) {
      photoUri = map['Photos'][0]['uri'];
    }

    // Prepend server URL if photoUri is a relative path
    if (photoUri != null &&
        !photoUri.startsWith('http') &&
        !photoUri.startsWith('assets/')) {
      photoUri = '${ApiConstants.serverUrl}$photoUri';
    }

    // Handle nested Reminders from API
    String? dueDate = map['due_date'];
    int? dueOdo = map['due_odometer'];
    String? tempName = map['template_name'];

    if (map['Reminders'] != null && (map['Reminders'] as List).isNotEmpty) {
      final r = map['Reminders'][0];
      dueDate = r['due_date'];
      dueOdo = r['due_odometer'];
      if (r['ServiceTemplate'] != null) {
        tempName = r['ServiceTemplate']['name'];
      }
    }

    return Vehicle(
      id: map['id'] ?? map['_id'],
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      variant: map['variant'],
      purchaseDate: map['purchase_date'],
      fuelType: map['fuel_type'] ?? '',
      vehicleColor: map['vehicle_color'],
      regNo: map['reg_no'],
      ownerName: map['owner_name'] ?? '',
      initialOdometer: map['initial_odometer'],
      currentOdometer: map['current_odometer'],
      odometerUpdatedAt: map['odometer_updated_at'],
      photoUri: photoUri,
      nextReminderDate: dueDate,
      nextReminderOdometer: dueOdo,
      templateName: tempName,
      serviceTotal: (map['service_total'] ?? 0.0).toDouble(),
      expenseTotal: (map['expense_total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'make': make,
      'model': model,
      'variant': variant,
      'purchase_date': purchaseDate,
      'fuel_type': fuelType,
      'vehicle_color': vehicleColor,
      'reg_no': regNo,
      'owner_name': ownerName,
      'initial_odometer': initialOdometer,
      'current_odometer': currentOdometer,
      'odometer_updated_at': odometerUpdatedAt,
    };
  }
}
