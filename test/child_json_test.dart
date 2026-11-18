import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/models/child.dart';
import 'package:orphan/models/sponsor.dart';

void main() {
  test('round-trips sponsor category and contact details', () {
    final sponsor = Sponsor(
      id: 'example-institution',
      name: 'Example Association',
      amount: 0,
      startDate: DateTime(2025, 1, 1),
      sponsorCategory: 'institution',
      organizationName: 'Example Association',
      address: 'Example address',
      phone: '+123456789',
      email: 'contact@example.org',
      endDate: DateTime(2025, 2, 1),
      endReason: 'Sponsorship completed',
      isOngoing: false,
      currency: 'Example currency',
    );

    final restored = Sponsor.fromJson(sponsor.toJson());

    expect(restored.sponsorCategory, 'institution');
    expect(restored.organizationName, 'Example Association');
    expect(restored.address, 'Example address');
    expect(restored.phone, '+123456789');
    expect(restored.email, 'contact@example.org');
    expect(restored.endDate, DateTime(2025, 2, 1));
    expect(restored.endReason, 'Sponsorship completed');
    expect(restored.isOngoing, isFalse);
    expect(restored.currency, 'Example currency');
  });

  test('parses JSON-encoded Firestore child relation fields', () {
    final child = Child.fromJson({
      'id': 'example-child',
      'firstName': 'Example',
      'childIdNumber': 'example-id',
      'siblings': jsonEncode([
        {'name': 'Sibling', 'id': 'sibling-id'},
      ]),
      'documents': jsonEncode([
        {
          'id': 'example-document',
          'fileName': 'certificate.pdf',
          'filePath': 'documents/certificate.pdf',
          'type': 'birth_certificate',
          'uploadedAt': '2025-01-01T00:00:00.000',
        },
      ]),
      'sponsor': jsonEncode({
        'id': 'example-sponsor',
        'name': 'Example sponsor',
        'amount': 10,
        'start_date': '2025-01-01T00:00:00.000',
      }),
    });

    expect(child.siblings, hasLength(1));
    expect(child.siblings.single['name'], 'Sibling');
    expect(child.documents, hasLength(1));
    expect(child.documents.single.fileName, 'certificate.pdf');
    expect(child.sponsor?.name, 'Example sponsor');
  });

  test('round-trips guardian details', () {
    final child = Child(
      id: 'example-child',
      firstName: 'Example',
      childIdNumber: 'example-id',
      guardianName: 'Guardian Name',
      guardianAddress: 'Guardian Address',
    );

    final restored = Child.fromJson(child.toJson());

    expect(restored.guardianName, 'Guardian Name');
    expect(restored.guardianAddress, 'Guardian Address');
  });

  test('round-trips university name, college, and specialization', () {
    final child = Child(
      id: 'university-child',
      firstName: 'University',
      childIdNumber: 'university-number',
      universityName: 'Example University',
      universityCollegeName: 'College of Science',
      collegeSpecialization: 'Computer Science',
    );

    final restored = Child.fromJson(child.toJson());

    expect(restored.universityName, 'Example University');
    expect(restored.universityCollegeName, 'College of Science');
    expect(restored.collegeSpecialization, 'Computer Science');
  });

  test('round-trips sibling details and registration links', () {
    final child = Child(
      id: 'parent-child',
      firstName: 'Parent',
      childIdNumber: 'parent-number',
      siblings: [
        {
          'name': 'Sibling Name',
          'id': '12345',
          'birthDate': '2015-03-10T00:00:00.000',
          'gender': 'F',
          'isSponsored': false,
          'sponsorshipStatus': 'candidate',
          'registerAsChild': true,
          'childProfileId': 'sibling-profile',
          'childIdNumber': 'sibling-number',
        },
      ],
    );

    final restored = Child.fromJson(child.toJson());
    final sibling = restored.siblings.single;

    expect(sibling['name'], 'Sibling Name');
    expect(sibling['id'], '12345');
    expect(sibling['birthDate'], '2015-03-10T00:00:00.000');
    expect(sibling['gender'], 'F');
    expect(sibling['isSponsored'], isFalse);
    expect(sibling['sponsorshipStatus'], 'candidate');
    expect(sibling['registerAsChild'], isTrue);
    expect(sibling['childProfileId'], 'sibling-profile');
    expect(sibling['childIdNumber'], 'sibling-number');
  });
}
