class Invoice {
  final int? invoiceId;
  final String invoiceType; // 'purchase' or 'sale'
  final String currency; // e.g., 'شيكل', 'دولار'
  final double currencyTransfer; // Exchange rate
  final String paymentMethod; // e.g., 'نقدي', 'تطبيق'
  final DateTime invoiceDate;
  final String? notes;
  final int customerId;
  final double total; // Total in local currency
  final double totalDollar; // Total in dollars
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Invoice({
    this.invoiceId,
    required this.invoiceType,
    required this.currency,
    required this.currencyTransfer,
    required this.paymentMethod,
    required this.invoiceDate,
    this.notes,
    required this.customerId,
    required this.total,
    required this.totalDollar,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'invoice_type': invoiceType,
      'currency': currency,
      'currency_transfer': currencyTransfer,
      'payment_method': paymentMethod,
      'invoice_date': invoiceDate.toIso8601String(),
      'notes': notes,
      'customer_id': customerId,
      'total': total,
      'total_dollar': totalDollar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoice_id'] as int?,
      invoiceType: json['invoice_type'] as String,
      currency: json['currency'] as String,
      currencyTransfer: (json['currency_transfer'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      notes: json['notes'] as String?,
      customerId: json['customer_id'] as int,
      total: (json['total'] as num).toDouble(),
      totalDollar: (json['total_dollar'] as num).toDouble(),
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

  Invoice copyWith({
    int? invoiceId,
    String? invoiceType,
    String? currency,
    double? currencyTransfer,
    String? paymentMethod,
    DateTime? invoiceDate,
    String? notes,
    int? customerId,
    double? total,
    double? totalDollar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Invoice(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceType: invoiceType ?? this.invoiceType,
      currency: currency ?? this.currency,
      currencyTransfer: currencyTransfer ?? this.currencyTransfer,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      notes: notes ?? this.notes,
      customerId: customerId ?? this.customerId,
      total: total ?? this.total,
      totalDollar: totalDollar ?? this.totalDollar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
