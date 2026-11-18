import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';

Future<List<Map<String, dynamic>>> readChildrenFromDatabase({
  String? path,
  Uint8List? bytes,
}) async {
  if (bytes == null || bytes.isEmpty) {
    throw ArgumentError('The selected database file has no readable bytes.');
  }

  final sqlite = await WasmSqlite3.loadFromUrl(
    Uri.base.resolve('sqlite3.wasm'),
  );
  final fileSystem = InMemoryFileSystem(name: 'child-db-import');
  sqlite.registerVirtualFileSystem(fileSystem);

  const fileName = '/imported-orphan.db';
  try {
    final temporaryDatabase = sqlite.open(fileName, vfs: fileSystem.name);
    temporaryDatabase.close();
    final databaseBytes = fileSystem.fileData[fileName];
    if (databaseBytes == null) {
      throw StateError('Could not prepare an in-memory database file.');
    }
    databaseBytes
      ..clear()
      ..addAll(bytes);

    final database = sqlite.open(
      fileName,
      mode: OpenMode.readOnly,
      vfs: fileSystem.name,
    );
    try {
      final tables = database.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'children'",
      );
      if (tables.isEmpty) {
        throw const FormatException(
          'The selected database does not contain a children table.',
        );
      }

      final rows = database.select('SELECT * FROM children');
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } finally {
      database.close();
    }
  } finally {
    sqlite.unregisterVirtualFileSystem(fileSystem);
  }
}
