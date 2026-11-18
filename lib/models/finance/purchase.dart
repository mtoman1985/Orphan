class Purchase {
  final int? purchaseId;
  final int invoiceId;
  final int customerId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Purchase({
    this.purchaseId,
    required this.invoiceId,
    required this.customerId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'purchase_id': purchaseId,
      'invoice_id': invoiceId,
      'customer_id': customerId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchase_id'] as int?,
      invoiceId: json['invoice_id'] as int,
      customerId: json['customer_id'] as int,
      itemId: json['item_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
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

  Purchase copyWith({
    int? purchaseId,
    int? invoiceId,
    int? customerId,
    int? itemId,
    double? quantity,
    double? unitPrice,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Purchase(
      purchaseId: purchaseId ?? this.purchaseId,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
