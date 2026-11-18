import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/models/child.dart';
import 'package:orphan/models/document.dart';
import 'package:orphan/services/sqlite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'verifies bidirectional sibling relationships and shared family certificates',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'orphan-sibling-enhancement-test-',
      );
      final database = SqliteService();

      try {
        SharedPreferences.setMockInitialValues({
          'data_location': temporaryDirectory.path,
        });

        await database.init();

        // 1. Create Parent Orphan (Muhammad)
        final parentMuhammad = Child(
          id: 'muhammad-id',
          firstName: 'محمد',
          fatherName: 'أحمد',
          grandfatherName: 'خالد',
          lastName: 'النحال',
          childIdNumber: 'PS-01-001',
          nationalId: '100100100',
          gender: 'M',
          dateOfBirth: DateTime(2012, 5, 10),
          country: 'فلسطين',
          city: 'غزة',
          street: 'شارع النصر',
          birthCountry: 'فلسطين',
          birthCity: 'غزة',
          fatherIdNumber: '900000001',
          fatherStatus: 'Deceased',
          fatherDeathDate: DateTime(2020, 1, 1),
          fatherDeathCause: 'طبيعية',
          fatherDeathCertificatePath: 'father_cert.pdf',
          fatherDeathCertificateFileName: 'father_cert.pdf',
          motherName: 'مريم محمود',
          motherIdNumber: '900000002',
          motherStatus: 'Alive',
          motherIdPhotoPath: 'mother_id.jpg',
          guardianName: 'محمود خالد النحال',
          guardianAddress: 'غزة',
          guardianRelationship: 'uncle',
          guardianPhone: '0599000000',
          guardianIdPhotoPath: 'guardian_id.jpg',
          paymentMethod: 'bank',
          bankName: 'بنك فلسطين',
          bankAccountNumber: '1234567',
          bankIban: 'PS12PALS1234567',
          bankAccountHolderName: 'مريم محمود',
          documents: [
            Document(
              id: 'doc-1',
              fileName: 'guardianship_deed.pdf',
              filePath: 'guardianship_deed.pdf',
              type: 'guardianship_deed',
            ),
          ],
          siblings: [
            {
              'name': 'خليل أحمد النحال',
              'id': '200200200',
              'birthDate': '2015-08-20T00:00:00.000',
              'gender': 'M',
              'isSponsored': false,
              'sponsorshipStatus': 'candidate',
              'registerAsChild': true,
              'childProfileId': 'khalil-id',
              'childIdNumber': 'PS-01-002',
            },
          ],
        );

        // 2. Create Sibling Child (Khalil)
        final siblingKhalil = Child(
          id: 'khalil-id',
          firstName: 'خليل',
          fatherName: parentMuhammad.fatherName,
          grandfatherName: parentMuhammad.grandfatherName,
          lastName: parentMuhammad.lastName,
          childIdNumber: 'PS-01-002',
          nationalId: '200200200',
          gender: 'M',
          dateOfBirth: DateTime(2015, 8, 20),
          country: parentMuhammad.country,
          city: parentMuhammad.city,
          street: parentMuhammad.street,
          birthCountry: parentMuhammad.birthCountry,
          birthCity: parentMuhammad.birthCity,
          fatherIdNumber: parentMuhammad.fatherIdNumber,
          fatherStatus: parentMuhammad.fatherStatus,
          fatherDeathDate: parentMuhammad.fatherDeathDate,
          fatherDeathCause: parentMuhammad.fatherDeathCause,
          fatherDeathCertificatePath: parentMuhammad.fatherDeathCertificatePath,
          fatherDeathCertificateFileName:
              parentMuhammad.fatherDeathCertificateFileName,
          motherName: parentMuhammad.motherName,
          motherIdNumber: parentMuhammad.motherIdNumber,
          motherStatus: parentMuhammad.motherStatus,
          motherIdPhotoPath: parentMuhammad.motherIdPhotoPath,
          guardianName: parentMuhammad.guardianName,
          guardianAddress: parentMuhammad.guardianAddress,
          guardianRelationship: parentMuhammad.guardianRelationship,
          guardianPhone: parentMuhammad.guardianPhone,
          guardianIdPhotoPath: parentMuhammad.guardianIdPhotoPath,
          paymentMethod: parentMuhammad.paymentMethod,
          bankName: parentMuhammad.bankName,
          bankAccountNumber: parentMuhammad.bankAccountNumber,
          bankIban: parentMuhammad.bankIban,
          bankAccountHolderName: parentMuhammad.bankAccountHolderName,
          documents: parentMuhammad.documents,
          siblings: [
            {
              'name': parentMuhammad.fullName,
              'id': parentMuhammad.nationalId,
              'childIdNumber': parentMuhammad.childIdNumber,
              'childProfileId': parentMuhammad.id,
              'birthDate': parentMuhammad.dateOfBirth?.toIso8601String() ?? '',
              'gender': parentMuhammad.gender,
              'isSponsored': parentMuhammad.isSponsored,
              'sponsorshipStatus': 'unsponsored',
              'registerAsChild': true,
            },
          ],
        );

        await database.insertChild(parentMuhammad);
        await database.insertChild(siblingKhalil);

        // Retrieve both from database
        final savedMuhammad = await database.getChildById(parentMuhammad.id);
        final savedKhalil = await database.getChildById(siblingKhalil.id);

        expect(savedMuhammad, isNotNull);
        expect(savedKhalil, isNotNull);

        // Verification 1: Muhammad's siblings list contains Khalil
        expect(savedMuhammad!.siblings, hasLength(1));
        expect(savedMuhammad.siblings.first['name'], 'خليل أحمد النحال');
        expect(savedMuhammad.siblings.first['id'], '200200200');
        expect(savedMuhammad.siblings.first['childProfileId'], 'khalil-id');
        expect(savedMuhammad.siblings.first['childIdNumber'], 'PS-01-002');

        // Verification 2: Khalil's siblings list contains Muhammad as brother!
        expect(savedKhalil!.siblings, hasLength(1));
        expect(savedKhalil.siblings.first['name'], 'محمد أحمد خالد النحال');
        expect(savedKhalil.siblings.first['id'], '100100100');
        expect(savedKhalil.siblings.first['childProfileId'], 'muhammad-id');
        expect(savedKhalil.siblings.first['childIdNumber'], 'PS-01-001');

        // Verification 3: Khalil is NOT in his own siblings list!
        expect(
          savedKhalil.siblings.any((s) => s['id'] == '200200200'),
          isFalse,
        );

        // Verification 4: Khalil inherited shared family documents and death certificates
        expect(
          savedKhalil.fatherDeathCertificatePath,
          contains('father_cert.pdf'),
        );
        expect(savedKhalil.motherIdPhotoPath, contains('mother_id.jpg'));
        expect(savedKhalil.guardianIdPhotoPath, contains('guardian_id.jpg'));
        expect(savedKhalil.documents, hasLength(1));
        expect(savedKhalil.documents.first.fileName, 'guardianship_deed.pdf');
        expect(savedKhalil.bankName, 'بنك فلسطين');
        expect(savedKhalil.bankIban, 'PS12PALS1234567');

        // Verification 5: getChildByNationalId finds both
        final foundByNidMuhammad =
            await database.getChildByNationalId('100100100');
        final foundByNidKhalil =
            await database.getChildByNationalId('200200200');

        expect(foundByNidMuhammad, isNotNull);
        expect(foundByNidMuhammad!.firstName, 'محمد');

        expect(foundByNidKhalil, isNotNull);
        expect(foundByNidKhalil!.firstName, 'خليل');
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}
