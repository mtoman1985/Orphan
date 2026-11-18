import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/models/sponsor.dart';
import 'package:orphan/services/sqlite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists sponsor category and contact details in SQLite', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'orphan-sponsor-db-test-',
    );
    final database = SqliteService();

    try {
      SharedPreferences.setMockInitialValues({
        'data_location': temporaryDirectory.path,
      });

      await database.init();
      final sponsor = Sponsor(
        id: 'institution-sponsor',
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
      );

      await database.insertSponsor(sponsor);
      final restored = await database.getSponsorById(sponsor.id);

      expect(restored, isNotNull);
      expect(restored!.sponsorCategory, 'institution');
      expect(restored.organizationName, 'Example Association');
      expect(restored.address, 'Example address');
      expect(restored.phone, '+123456789');
      expect(restored.email, 'contact@example.org');
      expect(restored.endDate, DateTime(2025, 2, 1));
      expect(restored.endReason, 'Sponsorship completed');
      expect(restored.isOngoing, isFalse);
    } finally {
      await database.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
