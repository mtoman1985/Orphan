import 'dart:typed_data';

Future<List<Map<String, dynamic>>> readChildrenFromDatabase({
  String? path,
  Uint8List? bytes,
}) {
  throw UnsupportedError(
    'Database-file import is unavailable on this platform.',
  );
}
