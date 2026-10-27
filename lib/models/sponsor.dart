import 'dart:convert';
import '../services/multilang_transliterator.dart';

class Sponsor {
  String? id;
  String name;
  double amount;
  DateTime startDate;
  DateTime? endDate;
  String? endReason;
  int? organizationId;
  String? organizationName;
  String? linkedSponsorId;
  String currency;
  bool isOngoing;
  DateTime createdAt;
  DateTime updatedAt;
  String? createdBy;
  String? updatedBy;
  bool isSynced;

  Sponsor({
    this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    this.endDate,
    this.endReason,
    this.organizationId,
    this.organizationName,
    this.linkedSponsorId,
    this.currency = 'شيكل',
    this.isOngoing = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  String getNameByLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(name);
      case 'tr':
        return MultiLangTransliterator.toTurkish(name);
      default:
        return name;
    }
  }

  String getCurrencyByLanguage(String languageCode) {
    final Map<String, Map<String, String>> currencyTranslations = {
      'شيكل': {'ar': 'شيكل', 'en': 'Shekel', 'tr': 'Şekel'},
      'ILS': {'ar': 'شيكل', 'en': 'Shekel', 'tr': 'Şekel'},
      'دولار': {'ar': 'دولار', 'en': 'Dollar', 'tr': 'Dolar'},
      'USD': {'ar': 'دولار', 'en': 'Dollar', 'tr': 'Dolar'},
      '\$': {'ar': 'دولار', 'en': 'Dollar', 'tr': 'Dolar'},
      'يورو': {'ar': 'يورو', 'en': 'Euro', 'tr': 'Euro'},
      'EUR': {'ar': 'يورو', 'en': 'Euro', 'tr': 'Euro'},
      '€': {'ar': 'يورو', 'en': 'Euro', 'tr': 'Euro'},
      'دينار': {'ar': 'دينار', 'en': 'Dinar', 'tr': 'Dinar'},
      'JOD': {'ar': 'دينار', 'en': 'Dinar', 'tr': 'Dinar'},
      'ريال': {'ar': 'ريال', 'en': 'Riyal', 'tr': 'Riyal'},
      'SAR': {'ar': 'ريال', 'en': 'Riyal', 'tr': 'Riyal'},
      'ليرة': {'ar': 'ليرة تركية', 'en': 'Turkish Lira', 'tr': 'Türk Lirası'},
      'TRY': {'ar': 'ليرة تركية', 'en': 'Turkish Lira', 'tr': 'Türk Lirası'},
      'TL': {'ar': 'ليرة تركية', 'en': 'Turkish Lira', 'tr': 'Türk Lirası'},
    };
    final translation = currencyTranslations[currency];
    if (translation != null) {
      return translation[languageCode] ?? currency;
    }
    return currency;
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'amount': amount,
    'start_date': startDate.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
    if (endReason != null) 'end_reason': endReason,
    if (organizationId != null) 'organization_id': organizationId,
    if (organizationName != null) 'organization_name': organizationName,
    if (linkedSponsorId != null) 'linked_sponsor_id': linkedSponsorId,
    'currency': currency,
    'is_ongoing': isOngoing ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'created_by': createdBy,
    'updated_by': updatedBy,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Sponsor.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value == null) return fallback ?? DateTime.now();
      if (value is String)
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      if (value is DateTime) return value;
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
      return fallback ?? DateTime.now();
    }

    return Sponsor(
      id: j['id']?.toString() ?? j['sponsor_id']?.toString(),
      name: j['name']?.toString() ?? '',
      amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0.0,
      startDate: parseDate(j['startDate'] ?? j['start_date']),
      endDate:
          (j['endDate'] != null || j['end_date'] != null)
              ? parseDate(j['endDate'] ?? j['end_date'])
              : null,
      endReason: j['endReason']?.toString() ?? j['end_reason']?.toString(),
      organizationId: j['organizationId'] as int?,
      organizationName: j['organizationName']?.toString(),
      linkedSponsorId: j['linkedSponsorId']?.toString(),
      currency: j['currency']?.toString() ?? 'شيكل',
      isOngoing:
          (j['isOngoing'] is bool)
              ? (j['isOngoing'] as bool)
              : (j['isOngoing'] is int)
              ? (j['isOngoing'] as int) != 0
              : true,
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: parseDate(
        j['updatedAt'] ?? j['updated_at'] ?? j['createdAt'] ?? j['created_at'],
        fallback: DateTime.now(),
      ),
      createdBy: j['createdBy']?.toString() ?? j['created_by']?.toString(),
      updatedBy: j['updatedBy']?.toString() ?? j['updated_by']?.toString(),
      isSynced:
          j['is_synced'] == 1 ||
          j['is_synced'] == true ||
          j['isSynced'] == true,
    );
  }

  String toRawJson() => json.encode(toJson());
  factory Sponsor.fromRawJson(String s) => Sponsor.fromJson(json.decode(s));
}
