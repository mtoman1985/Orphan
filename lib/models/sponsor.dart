import 'dart:convert';

class Sponsor {
  String id;
  String name;
  double amount;
  DateTime startDate;
  String relationship;
  String? email;
  String? phone;
  String? address;

  Sponsor({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    this.relationship = '',
    this.email,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'relationship': relationship,
    'email': email,
    'phone': phone,
    'address': address,
  };

  factory Sponsor.fromJson(Map<String, dynamic> j) => Sponsor(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0.0,
    startDate:
        j['startDate'] != null
            ? DateTime.parse(j['startDate'] as String)
            : DateTime.now(),
    relationship: j['relationship'] ?? '',
    email: j['email'],
    phone: j['phone'],
    address: j['address'],
  );

  String toRawJson() => json.encode(toJson());
  factory Sponsor.fromRawJson(String s) => Sponsor.fromJson(json.decode(s));
}
