class ServiceTemplate {
  final int? id;
  final String name;
  final int? intervalDays;
  final int? intervalKm;

  ServiceTemplate({
    this.id,
    required this.name,
    this.intervalDays,
    this.intervalKm,
  });

  factory ServiceTemplate.fromMap(Map<String, dynamic> map) {
    return ServiceTemplate(
      id: map['id'] ?? map['_id'],
      name: map['name'] ?? '',
      intervalDays: map['interval_days'] ?? map['intervalDays'],
      intervalKm: map['interval_km'] ?? map['intervalKm'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'interval_days': intervalDays,
      'interval_km': intervalKm,
    };
  }
}
