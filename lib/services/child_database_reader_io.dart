import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<List<Map<String, dynamic>>> readChildrenFromDatabase({
  String? path,
  Uint8List? bytes,
}) async {
  if (path == null || path.isEmpty) {
    throw ArgumentError('A database file path is required.');
  }

  final temporaryDirectory = await Directory.systemTemp.createTemp(
    'orphan-db-import-',
  );
  final importPath = p.join(temporaryDirectory.path, 'import.db');

  try {
    await File(path).copy(importPath);
    final database = await openDatabase(importPath, readOnly: true);
    try {
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'children'",
      );
      if (tables.isEmpty) {
        throw const FormatException(
          'The selected database does not contain a children table.',
        );
      }

      final rows = await database.query('children');
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } finally {
      await database.close();
    }
  } finally {
    await temporaryDirectory.delete(recursive: true);
  }
}
