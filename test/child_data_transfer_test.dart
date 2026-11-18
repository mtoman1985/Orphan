import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:orphan/models/child.dart';
import 'package:orphan/services/child_data_transfer_service.dart';
import 'package:orphan/services/sqlite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('localized Excel exports re-import to canonical child values', () {
    final child = Child(
      id: 'localized-child',
      childIdNumber: 'IHSAN010001',
      firstName: 'ليلى',
      lastName: 'حسن',
      nationalId: '123456789',
      country: 'Filistin',
      city: 'Gazze',
      birthCountry: 'Filistin',
      birthCity: 'Gazze',
      gender: 'F',
      fatherStatus: 'Deceased',
      motherStatus: 'Alive',
      healthStatus: 'Healthy',
      guardianRelationship: 'Mother',
      educationLevel: 'University',
      grade: '4th Grade',
      universityYear: 'Second Year',
    );

    for (final language in ['ar', 'en', 'tr']) {
      final bytes = ChildDataTransferService.exportChildren([
        child,
      ], languageCode: language);
      final workbook = Excel.decodeBytes(bytes);
      final headers =
          workbook.tables['Children']!.rows.first
              .whereType<Data>()
              .map((cell) => (cell.value as TextCellValue).value.text)
              .toList();
      expect(
        headers,
        contains(switch (language) {
          'ar' => 'الدولة',
          'tr' => 'Ülke',
          _ => 'Country',
        }),
      );

      final row = ChildDataTransferService.importExcel(bytes).single;
      final restored = ChildDataTransferService.decodeChild(row);
      expect(restored.firstName, child.firstName);
      expect(restored.country, 'Palestine');
      expect(restored.city, 'Gaza');
      expect(restored.birthCountry, 'Palestine');
      expect(restored.birthCity, 'Gaza');
      expect(restored.gender, 'F');
      expect(restored.fatherStatus, 'Deceased');
      expect(restored.motherStatus, 'Alive');
      expect(restored.healthStatus, 'Healthy');
      expect(restored.guardianRelationship, 'Mother');
      expect(restored.educationLevel, 'University');
      expect(restored.grade, '4th Grade');
      expect(restored.universityYear, 'Second Year');
    }
  });

  test('Excel export and import preserve child profile data', () {
    final child = Child(
      id: 'child-1',
      childIdNumber: 'IHSAN010001',
      firstName: 'أحمد',
      fatherName: 'محمد',
      lastName: 'علي',
      nationalId: '012345678',
      country: 'فلسطين',
      city: 'غزة',
      gender: 'M',
      siblings: [
        {'name': 'سارة', 'gender': 'F'},
      ],
    );

    final bytes = ChildDataTransferService.exportChildren([child]);
    final row = ChildDataTransferService.importExcel(bytes).single;
    final restored = ChildDataTransferService.decodeChild(row);

    expect(restored.id, child.id);
    expect(restored.childIdNumber, child.childIdNumber);
    expect(restored.fullName, child.fullName);
    expect(restored.nationalId, child.nationalId);
    expect(restored.country, 'Palestine');
    expect(restored.city, 'Gaza');
    expect(restored.siblings, child.siblings);
  });

  test(
    'database import reads children without replacing the active database',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'orphan-database-import-test-',
      );
      final database = SqliteService();

      try {
        SharedPreferences.setMockInitialValues({
          'data_location': temporaryDirectory.path,
        });
        await database.init();
        await database.insertChild(
          Child(
            id: 'existing-child',
            childIdNumber: 'IHSAN010001',
            firstName: 'ليلى',
            lastName: 'حسن',
            nationalId: '123456789',
          ),
        );

        final rows = await ChildDataTransferService.importDatabase(
          path: p.join(temporaryDirectory.path, 'orphan.db'),
        );

        expect(rows, hasLength(1));
        expect(
          ChildDataTransferService.decodeChild(rows.single).nationalId,
          '123456789',
        );
        expect(await database.getChildById('existing-child'), isNotNull);
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
