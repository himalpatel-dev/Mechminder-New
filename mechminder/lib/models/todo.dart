class Todo {
  final int? id;
  final int? vehicleId;
  final String partName;
  final String? notes;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleRegNo;

  Todo({
    this.id,
    this.vehicleId,
    required this.partName,
    this.notes,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleRegNo,
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] ?? map['_id'],
      vehicleId: map['vehicle_id'],
      partName: map['part_name'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? map['created_at'],
      updatedAt: map['updatedAt'] ?? map['updated_at'],
      vehicleMake: map['Vehicle']?['make'] ?? map['make'],
      vehicleModel: map['Vehicle']?['model'] ?? map['model'],
      vehicleRegNo: map['Vehicle']?['reg_no'] ?? map['reg_no'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'vehicle_id': vehicleId,
      'part_name': partName,
      'notes': notes,
      'status': status,
    };
  }

  bool get isCompleted => status == 'completed';
}
