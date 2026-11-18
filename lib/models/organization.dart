class Organization {
  final int? id;
  final String nameAr;
  final String nameEn;
  final String nameTr;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Organization({
    this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameTr,
    required this.createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'name_tr': nameTr,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  factory Organization.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      if (value?.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate() as DateTime;
      }
      return fallback ?? DateTime.now();
    }

    final createdAt = parseDate(json['created_at'] ?? json['createdAt']);
    return Organization(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameTr: json['name_tr']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: parseDate(
        json['updated_at'] ?? json['updatedAt'],
        fallback: createdAt,
      ),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }
}
