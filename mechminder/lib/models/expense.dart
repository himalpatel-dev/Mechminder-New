class Expense {
  final int? id;
  final int vehicleId;
  final String date;
  final String category;
  final double amount;
  final String? notes;
  final int? odometer;

  Expense({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
    this.odometer,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['_id'],
      vehicleId: map['vehicle_id'],
      date: map['service_date'] ?? '',
      category: map['category'] ?? map['expense_type'] ?? '',
      amount: (map['total_cost'] ?? map['amount'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? map['description'],
      odometer: map['odometer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'vehicle_id': vehicleId,
      'service_date': date,
      'category': category,
      'total_cost': amount,
      'notes': notes,
      'odometer': odometer,
    };
  }
}
