class Country {
  final int? id;
  final String nameAr;
  final String nameEn;
  final String nameTr;
  final String code;
  final DateTime updatedAt;
  final bool isSynced;

  Country({
    this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameTr,
    required this.code,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// الحصول على اسم الدولة حسب اللغة
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
    'name_ar': nameAr,
    'name_en': nameEn,
    'name_tr': nameTr,
    'code': code,
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.id == id && other.code == code;
  }

  @override
  int get hashCode => Object.hash(id, code);

  bool matchesName(String value) {
    final normalizedValue = _normalizeName(value);
    if (normalizedValue.isEmpty) return false;

    final names = [nameAr, nameEn, nameTr];
    if (names.any((name) => _normalizeName(name) == normalizedValue)) {
      return true;
    }

    return _isPalestineName(value) && names.any(_isPalestineName);
  }

  static String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ـ', '')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ى', 'ي');
  }

  static bool _isPalestineName(String value) {
    final normalized = _normalizeName(value);
    return normalized.contains('فلسطين') ||
        normalized.contains('palestin') ||
        normalized.contains('filistin');
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value?.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return Country(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameTr: json['name_tr']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }
}
