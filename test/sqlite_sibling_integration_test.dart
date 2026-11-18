import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/models/child.dart';
import 'package:orphan/services/sqlite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists sibling details and linked child profiles in SQLite',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'orphan-sibling-db-test-',
      );
      final database = SqliteService();

      try {
        SharedPreferences.setMockInitialValues({
          'data_location': temporaryDirectory.path,
        });

        await database.init();

        final parent = Child(
          id: 'integration-parent',
          firstName: 'Parent',
          fatherName: 'Father',
          grandfatherName: 'Grandfather',
          lastName: 'Family',
          childIdNumber: 'test-parent-number',
          country: 'Palestine',
          birthCity: 'Gaza',
          motherName: 'Mother',
          guardianName: 'Guardian',
          universityName: 'Test University',
          universityCollegeName: 'Test College',
          collegeSpecialization: 'Test Specialization',
          siblings: [
            {
              'name': 'Sibling',
              'id': 'test-national-id',
              'birthDate': '2015-03-10T00:00:00.000',
              'gender': 'F',
              'isSponsored': false,
              'sponsorshipStatus': 'candidate',
              'registerAsChild': true,
              'childProfileId': 'integration-sibling',
              'childIdNumber': 'test-sibling-number',
            },
          ],
        );
        final sibling = Child(
          id: 'integration-sibling',
          firstName: 'Sibling',
          fatherName: parent.fatherName,
          grandfatherName: parent.grandfatherName,
          lastName: parent.lastName,
          childIdNumber: 'test-sibling-number',
          country: parent.country,
          birthCity: parent.birthCity,
          motherName: parent.motherName,
          guardianName: parent.guardianName,
          nationalId: 'test-national-id',
          gender: 'F',
        );

        await database.insertChild(parent);
        await database.insertChild(sibling);

        final savedParent = await database.getChildById(parent.id);
        final savedSibling = await database.getChildById(sibling.id);

        expect(savedParent, isNotNull);
        expect(savedParent!.siblings, hasLength(1));
        expect(savedParent.siblings.single['name'], 'Sibling');
        expect(savedParent.siblings.single['id'], 'test-national-id');
        expect(savedParent.siblings.single['gender'], 'F');
        expect(savedParent.siblings.single['sponsorshipStatus'], 'candidate');
        expect(savedParent.universityName, 'Test University');
        expect(savedParent.universityCollegeName, 'Test College');
        expect(savedParent.collegeSpecialization, 'Test Specialization');
        expect(savedParent.siblings.single['registerAsChild'], isTrue);
        expect(
          savedParent.siblings.single['childProfileId'],
          'integration-sibling',
        );
        expect(
          savedParent.siblings.single['childIdNumber'],
          'test-sibling-number',
        );

        expect(savedSibling, isNotNull);
        expect(savedSibling!.nationalId, 'test-national-id');
        expect(savedSibling.fatherName, parent.fatherName);
        expect(savedSibling.grandfatherName, parent.grandfatherName);
        expect(savedSibling.lastName, parent.lastName);
        expect(savedSibling.country, parent.country);
        expect(savedSibling.birthCity, parent.birthCity);
        expect(savedSibling.motherName, parent.motherName);
        expect(savedSibling.guardianName, parent.guardianName);
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
