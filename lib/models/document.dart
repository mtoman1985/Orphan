import 'dart:convert';

class Document {
  String id;
  String fileName;
  String filePath; // stored path in app data
  String type; // e.g., photo, birth_certificate, id_photo, medical_report
  DateTime uploadedAt;
  DateTime updatedAt;

  Document({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.type = '',
    DateTime? uploadedAt,
    DateTime? updatedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? uploadedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'filePath': filePath,
    'type': type,
    'uploadedAt': uploadedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Document.fromJson(Map<String, dynamic> j) => Document(
    id: j['id'] ?? '',
    fileName: j['fileName'] ?? '',
    filePath: j['filePath'] ?? '',
    type: j['type'] ?? '',
    uploadedAt:
        j['uploadedAt'] != null
            ? DateTime.parse(j['uploadedAt'] as String)
            : DateTime.now(),
    updatedAt:
        j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : (j['uploadedAt'] != null
                ? DateTime.parse(j['uploadedAt'] as String)
                : DateTime.now()),
  );

  String toRawJson() => json.encode(toJson());
  factory Document.fromRawJson(String s) => Document.fromJson(json.decode(s));
}
