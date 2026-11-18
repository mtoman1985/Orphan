class City {
  final int? id;
  final int countryId;
  final String nameAr;
  final String nameEn;
  final String nameTr;
  final DateTime updatedAt;
  final bool isSynced;

  City({
    this.id,
    required this.countryId,
    required this.nameAr,
    required this.nameEn,
    required this.nameTr,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// الحصول على اسم المدينة حسب اللغة
  String getName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      case 'tr':
        return nameTr;
      default:
        return nameAr;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'country_id': countryId,
    'name_ar': nameAr,
    'name_en': nameEn,
    'name_tr': nameTr,
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City &&
        other.id == id &&
        other.countryId == countryId &&
        other.nameAr == nameAr;
  }

  @override
  int get hashCode => Object.hash(id, countryId, nameAr);

  factory City.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value?.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return City(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      countryId: (json['country_id'] as num).toInt(),
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameTr: json['name_tr']?.toString() ?? '',
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }
}
