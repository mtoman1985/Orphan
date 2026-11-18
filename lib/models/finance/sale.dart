class Sale {
  final int? saleId;
  final int invoiceId;
  final int customerId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Sale({
    this.saleId,
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
      'sale_id': saleId,
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

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['sale_id'] as int?,
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

  Sale copyWith({
    int? saleId,
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
    return Sale(
      saleId: saleId ?? this.saleId,
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
