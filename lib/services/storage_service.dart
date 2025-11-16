import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/child.dart';
import '../models/document.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _baseDir;

  Future<Directory> getBaseDir() async {
    if (_baseDir != null) return _baseDir!;
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/orphan_data');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    _baseDir = appDir;
    return _baseDir!;
  }

  Future<File> _childFile(String id) async {
    final base = await getBaseDir();
    final file = File('${base.path}/children/$id.json');
    final parent = file.parent;
    if (!await parent.exists()) await parent.create(recursive: true);
    return file;
  }

  Future<List<Child>> listChildren() async {
    final base = await getBaseDir();
    final childrenDir = Directory('${base.path}/children');
    if (!await childrenDir.exists()) return [];
    final files = childrenDir.listSync().whereType<File>();
    final out = <Child>[];
    for (final f in files) {
      try {
        final s = await f.readAsString();
        out.add(Child.fromRawJson(s));
      } catch (e) {
        // ignore
      }
    }
    return out;
  }

  Future<void> saveChild(Child child) async {
    final f = await _childFile(child.id);
    await f.writeAsString(child.toRawJson());
  }

  Future<Document> saveFile(File src, {required String type}) async {
    final base = await getBaseDir();
    final filesDir = Directory('${base.path}/files');
    if (!await filesDir.exists()) await filesDir.create(recursive: true);
    final id = Uuid().v4();
    final fileName = '${id}_${src.uri.pathSegments.last}';
    final dest = File('${filesDir.path}/$fileName');
    await src.copy(dest.path);
    final doc = Document(
      id: id,
      fileName: src.uri.pathSegments.last,
      filePath: dest.path,
      type: type,
    );
    return doc;
  }

  Future<File> generateMonthlyReportPdf(
    String childId,
    String sponsorName,
    DateTime month,
    Map<String, dynamic> data,
  ) async {
    // Minimal stub that writes a JSON summary as .pdf placeholder.
    // A real implementation would use the `pdf` package to create a proper PDF.
    final base = await getBaseDir();
    final reportsDir = Directory('${base.path}/reports');
    if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
    final file = File(
      '${reportsDir.path}/report_${childId}_${month.year}_${month.month}.pdf',
    );
    final content =
        'Monthly report for $sponsorName\nChild: $childId\nMonth: ${month.year}-${month.month}\n\nData:\n${json.encode(data)}';
    await file.writeAsBytes(content.codeUnits);
    return file;
  }
}
