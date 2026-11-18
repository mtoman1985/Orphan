import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:orphan/services/sqlite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'removes legacy unique child identity constraints during migration',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'orphan-child-identity-migration-',
      );
      final databasePath = p.join(temporaryDirectory.path, 'orphan_data');
      final databaseFilePath = p.join(databasePath, 'orphan.db');
      final service = SqliteService();

      try {
        SharedPreferences.setMockInitialValues({'data_location': databasePath});
        await service.init();
        await service.close();

        final legacyDatabase = await databaseFactory.openDatabase(
          databaseFilePath,
        );
        await legacyDatabase.execute(
          'CREATE UNIQUE INDEX legacy_child_id_number '
          'ON children(child_id_number)',
        );
        await legacyDatabase.execute(
          'CREATE UNIQUE INDEX legacy_national_id ON children(national_id)',
        );
        await legacyDatabase.execute('PRAGMA user_version = 25');
        await legacyDatabase.close();

        await service.init();
        final migratedDatabase = await databaseFactory.openDatabase(
          databaseFilePath,
        );
        try {
          await migratedDatabase.insert('children', {
            'id': 'cloud-child-1',
            'first_name': 'Child',
            'last_name': 'One',
            'child_id_number': 'duplicate-child-number',
            'national_id': 'duplicate-national-id',
          });
          await migratedDatabase.insert('children', {
            'id': 'cloud-child-2',
            'first_name': 'Child',
            'last_name': 'Two',
            'child_id_number': 'duplicate-child-number',
            'national_id': 'duplicate-national-id',
          });

          final count = Sqflite.firstIntValue(
            await migratedDatabase.rawQuery(
              "SELECT COUNT(*) FROM children "
              "WHERE child_id_number = 'duplicate-child-number'",
            ),
          );
          expect(count, 2);
        } finally {
          await migratedDatabase.close();
        }
      } finally {
        await service.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
