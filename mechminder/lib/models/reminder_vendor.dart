class Reminder {
  final int? id;
  final int vehicleId;
  final int? templateId;
  final String? dueDate;
  final int? dueOdometer;
  final String status;
  final String? notes;
  final String? templateName;

  Reminder({
    this.id,
    required this.vehicleId,
    this.templateId,
    this.dueDate,
    this.dueOdometer,
    required this.status,
    this.notes,
    this.templateName,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? map['_id'],
      vehicleId: map['vehicle_id'],
      templateId: map['template_id'],
      dueDate: map['due_date'],
      dueOdometer: map['due_odometer'],
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      templateName: map['ServiceTemplate']?['name'] ?? map['template_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'id': id,
      'vehicle_id': vehicleId,
      'template_id': templateId,
      'due_date': dueDate,
      'due_odometer': dueOdometer,
      'status': status,
      'notes': notes,
    };
  }

  bool get isDueSoon => status == 'pending'; // Expand with date logic
}

class Vendor {
  final int? id;
  final String name;
  final String? phone;
  final String? address;

  Vendor({this.id, required this.name, this.phone, this.address});

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'] ?? map['_id'],
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
