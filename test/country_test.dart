import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orphan/models/city.dart';
import 'package:orphan/models/country.dart';
import 'package:orphan/models/organization.dart';

void main() {
  const countryNames = {
    'name_ar': 'دولة فلسطين',
    'name_en': 'Palestine',
    'name_tr': 'Filistin',
    'code': 'PS',
  };

  test('matches country names across languages and Arabic variants', () {
    final country = Country.fromJson(countryNames);

    expect(country.matchesName('فلسطين'), isTrue);
    expect(country.matchesName(' دولة   فلسطين '), isTrue);
    expect(country.matchesName('Palestine'), isTrue);
    expect(country.matchesName('Filistin'), isTrue);
    expect(country.matchesName('مصر'), isFalse);
  });

  test('parses Firestore timestamps for synchronized reference records', () {
    final timestamp = Timestamp.fromDate(DateTime.utc(2026, 1, 2));
    final country = Country.fromJson({
      ...countryNames,
      'id': 1,
      'updated_at': timestamp,
    });
    final city = City.fromJson({
      'id': 2,
      'country_id': 1,
      'name_ar': 'القدس',
      'name_en': 'Jerusalem',
      'name_tr': 'Kudüs',
      'updated_at': timestamp,
    });
    final organization = Organization.fromJson({
      'id': 3,
      'name_ar': 'منظمة',
      'name_en': 'Organization',
      'name_tr': 'Organizasyon',
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    expect(country.updatedAt, timestamp.toDate());
    expect(city.updatedAt, timestamp.toDate());
    expect(organization.createdAt, timestamp.toDate());
    expect(organization.updatedAt, timestamp.toDate());
  });
}
