class Customer {
  final int? customerId;
  final String customerName;
  final String? phoneNumber;
  final String customerType; // 'supplier' or 'client'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Customer({
    this.customerId,
    required this.customerName,
    this.phoneNumber,
    required this.customerType,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'customer_type': customerType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      customerType: json['customer_type'] as String,
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

  Customer copyWith({
    int? customerId,
    String? customerName,
    String? phoneNumber,
    String? customerType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      customerType: customerType ?? this.customerType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
