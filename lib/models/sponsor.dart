import 'dart:convert';

class Sponsor {
  String name;
  double amount;
  DateTime startDate;
  String relationship;

  Sponsor({
    required this.name,
    required this.amount,
    required this.startDate,
    this.relationship = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'relationship': relationship,
  };

  factory Sponsor.fromJson(Map<String, dynamic> j) => Sponsor(
    name: j['name'] ?? '',
    amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : 0.0,
    startDate:
        j['startDate'] != null
            ? DateTime.parse(j['startDate'] as String)
            : DateTime.now(),
    relationship: j['relationship'] ?? '',
  );

  String toRawJson() => json.encode(toJson());
  factory Sponsor.fromRawJson(String s) => Sponsor.fromJson(json.decode(s));
}
