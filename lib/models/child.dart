import 'dart:convert';

import 'document.dart';
import 'sponsor.dart';

class Child {
  String id;
  String fullName;
  DateTime? dateOfBirth;
  String childIdNumber;

  String fatherName;
  String fatherIdNumber;
  String motherName;
  String motherIdNumber;
  String motherStatus; // Alive / Deceased

  String healthStatus; // Healthy / Sick / Disabled
  String? disabilityType;
  List<Map<String, String>> siblings; // [{"name":"","id":""}, ...]

  List<Document> documents;

  Sponsor? sponsor;

  DateTime createdAt;

  Child({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    required this.childIdNumber,
    this.fatherName = '',
    this.fatherIdNumber = '',
    this.motherName = '',
    this.motherIdNumber = '',
    this.motherStatus = 'Alive',
    this.healthStatus = 'Healthy',
    this.disabilityType,
    List<Map<String, String>>? siblings,
    List<Document>? documents,
    this.sponsor,
    DateTime? createdAt,
  }) : siblings = siblings ?? [],
       documents = documents ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'childIdNumber': childIdNumber,
    'fatherName': fatherName,
    'fatherIdNumber': fatherIdNumber,
    'motherName': motherName,
    'motherIdNumber': motherIdNumber,
    'motherStatus': motherStatus,
    'healthStatus': healthStatus,
    'disabilityType': disabilityType,
    'siblings': siblings,
    'documents': documents.map((d) => d.toJson()).toList(),
    'sponsor': sponsor?.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Child.fromJson(Map<String, dynamic> j) => Child(
    id: j['id'] as String,
    fullName: j['fullName'] ?? '',
    dateOfBirth:
        j['dateOfBirth'] != null
            ? DateTime.parse(j['dateOfBirth'] as String)
            : null,
    childIdNumber: j['childIdNumber'] ?? '',
    fatherName: j['fatherName'] ?? '',
    fatherIdNumber: j['fatherIdNumber'] ?? '',
    motherName: j['motherName'] ?? '',
    motherIdNumber: j['motherIdNumber'] ?? '',
    motherStatus: j['motherStatus'] ?? 'Alive',
    healthStatus: j['healthStatus'] ?? 'Healthy',
    disabilityType: j['disabilityType'],
    siblings:
        (j['siblings'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        [],
    documents:
        (j['documents'] as List<dynamic>?)
            ?.map((e) => Document.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
    sponsor:
        j['sponsor'] != null
            ? Sponsor.fromJson(Map<String, dynamic>.from(j['sponsor']))
            : null,
    createdAt:
        j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
  );

  String toRawJson() => json.encode(toJson());
  factory Child.fromRawJson(String s) => Child.fromJson(json.decode(s));
}
