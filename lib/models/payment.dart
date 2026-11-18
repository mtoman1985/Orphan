import 'dart:convert';

class Payment {
  String id;
  String childId;
  String? sponsorId;
  double amount;
  String? currency;
  DateTime paidAt;
  String? note;
  DateTime updatedAt;
  String? createdBy;
  String? updatedBy;
  bool isSynced;

  Payment({
    required this.id,
    required this.childId,
    this.sponsorId,
    required this.amount,
    this.currency = 'شيكل',
    required this.paidAt,
    this.note,
    DateTime? updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    if (sponsorId != null) 'sponsor_id': sponsorId,
    'amount': amount,
    if (currency != null) 'currency': currency,
    'paid_at': paidAt.toIso8601String(),
    if (note != null) 'note': note,
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Payment.fromJson(Map<String, dynamic> j) {
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

    return Payment(
      id: j['id']?.toString() ?? '',
      childId: j['child_id']?.toString() ?? j['childId']?.toString() ?? '',
      sponsorId: j['sponsor_id']?.toString() ?? j['sponsorId']?.toString(),
      amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0.0,
      currency: j['currency']?.toString() ?? 'شيكل',
      paidAt: parseDate(j['paid_at'] ?? j['paidAt']),
      note: j['note']?.toString(),
      updatedAt: parseDate(
        j['updatedAt'] ?? j['updated_at'] ?? j['paid_at'] ?? j['paidAt'],
        fallback: DateTime.now(),
      ),
      createdBy: j['createdBy']?.toString() ?? j['created_by']?.toString(),
      updatedBy: j['updatedBy']?.toString() ?? j['updated_by']?.toString(),
      isSynced:
          (j['is_synced'] == 1 ||
              j['is_synced'] == true ||
              j['isSynced'] == true),
    );
  }

  String toRawJson() => json.encode(toJson());
  factory Payment.fromRawJson(String s) =>
      Payment.fromJson(json.decode(s) as Map<String, dynamic>);
}
