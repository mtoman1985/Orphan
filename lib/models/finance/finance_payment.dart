class FinancePayment {
  final int? paymentId;
  final int customerId;
  final String currency;
  final double currencyTransfer;
  final double paymentAmount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final String paymentType; // 'صرف' (payment out) or 'قبض' (payment in)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  FinancePayment({
    this.paymentId,
    required this.customerId,
    required this.currency,
    required this.currencyTransfer,
    required this.paymentAmount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    required this.paymentType,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'customer_id': customerId,
      'currency': currency,
      'currency_transfer': currencyTransfer,
      'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'payment_type': paymentType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory FinancePayment.fromJson(Map<String, dynamic> json) {
    return FinancePayment(
      paymentId: json['payment_id'] as int?,
      customerId: json['customer_id'] as int,
      currency: json['currency'] as String,
      currencyTransfer: (json['currency_transfer'] as num).toDouble(),
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
      paymentType: json['payment_type'] as String,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }

  FinancePayment copyWith({
    int? paymentId,
    int? customerId,
    String? currency,
    double? currencyTransfer,
    double? paymentAmount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? notes,
    String? paymentType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return FinancePayment(
      paymentId: paymentId ?? this.paymentId,
      customerId: customerId ?? this.customerId,
      currency: currency ?? this.currency,
      currencyTransfer: currencyTransfer ?? this.currencyTransfer,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      paymentType: paymentType ?? this.paymentType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
