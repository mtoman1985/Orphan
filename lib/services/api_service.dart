import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<List<Child>> fetchChildren() async {
    final resp = await http.get(Uri.parse('$baseUrl/children'));
    if (resp.statusCode != 200) throw Exception('Failed to fetch children');
    final List<dynamic> arr = json.decode(resp.body) as List<dynamic>;
    return arr
        .map((e) => Child.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Child> createChild(Child c) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/children'),
      headers: {'Content-Type': 'application/json'},
      body: c.toRawJson(),
    );
    if (resp.statusCode != 201) throw Exception('Failed to create child');
    return Child.fromJson(json.decode(resp.body));
  }

  Future<Child> updateChild(Child c) async {
    final resp = await http.put(
      Uri.parse('$baseUrl/children/${c.id}'),
      headers: {'Content-Type': 'application/json'},
      body: c.toRawJson(),
    );
    if (resp.statusCode != 200) throw Exception('Failed to update child');
    return Child.fromJson(json.decode(resp.body));
  }

  Future<void> deleteChild(String id) async {
    final resp = await http.delete(Uri.parse('$baseUrl/children/$id'));
    if (resp.statusCode != 204) throw Exception('Failed to delete child');
  }

  Future<void> postDocumentMetadata(
    String childId,
    Map<String, dynamic> doc,
  ) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/children/$childId/documents'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(doc),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to save document metadata');
    }
  }
}
