import 'dart:typed_data';

import 'child_database_reader_stub.dart'
    if (dart.library.io) 'child_database_reader_io.dart'
    if (dart.library.js_interop) 'child_database_reader_web.dart'
    as reader;

Future<List<Map<String, dynamic>>> readChildrenFromDatabase({
  String? path,
  Uint8List? bytes,
}) {
  return reader.readChildrenFromDatabase(path: path, bytes: bytes);
}
