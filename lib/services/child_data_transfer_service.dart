import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/child.dart';
import 'child_database_reader.dart';

class ChildDataTransferService {
  static const _sheetName = 'Children';

  static const Map<String, Map<String, String>> _fieldLabels = {
    'id': {'ar': 'معرّف السجل', 'en': 'Record ID', 'tr': 'Kayıt Kimliği'},
    'first_name': {'ar': 'الاسم الأول', 'en': 'First name', 'tr': 'Adı'},
    'grand_father_name': {
      'ar': 'اسم الجد',
      'en': 'Grandfather name',
      'tr': 'Dede adı',
    },
    'birth_country': {
      'ar': 'دولة الميلاد',
      'en': 'Birth country',
      'tr': 'Doğum ülkesi',
    },
    'birth_city': {
      'ar': 'مدينة الميلاد',
      'en': 'Birth city',
      'tr': 'Doğum şehri',
    },
    'last_name': {'ar': 'اسم العائلة', 'en': 'Last name', 'tr': 'Soyadı'},
    'national_id': {
      'ar': 'رقم الهوية',
      'en': 'National ID',
      'tr': 'Kimlik numarası',
    },
    'date_of_birth': {
      'ar': 'تاريخ الميلاد',
      'en': 'Date of birth',
      'tr': 'Doğum tarihi',
    },
    'child_id_number': {
      'ar': 'رقم اليتيم',
      'en': 'Child ID number',
      'tr': 'Yetim numarası',
    },
    'country': {'ar': 'الدولة', 'en': 'Country', 'tr': 'Ülke'},
    'city': {'ar': 'المدينة', 'en': 'City', 'tr': 'Şehir'},
    'street': {'ar': 'الشارع', 'en': 'Street', 'tr': 'Cadde'},
    'guardian_name': {
      'ar': 'اسم الوصي',
      'en': 'Guardian name',
      'tr': 'Vasi adı',
    },
    'guardian_address': {
      'ar': 'عنوان الوصي',
      'en': 'Guardian address',
      'tr': 'Vasi adresi',
    },
    'guardian_relationship': {
      'ar': 'صلة الوصي',
      'en': 'Guardian relationship',
      'tr': 'Vasi yakınlığı',
    },
    'guardian_phone': {
      'ar': 'هاتف الوصي',
      'en': 'Guardian phone',
      'tr': 'Vasi telefonu',
    },
    'education_level': {
      'ar': 'المستوى التعليمي',
      'en': 'Education level',
      'tr': 'Eğitim seviyesi',
    },
    'grade': {'ar': 'الصف الدراسي', 'en': 'Grade', 'tr': 'Sınıf'},
    'university_year': {
      'ar': 'السنة الجامعية',
      'en': 'University year',
      'tr': 'Üniversite yılı',
    },
    'university_name': {
      'ar': 'اسم الجامعة',
      'en': 'University name',
      'tr': 'Üniversite adı',
    },
    'university_college_name': {
      'ar': 'الكلية الجامعية',
      'en': 'University college',
      'tr': 'Üniversite fakültesi',
    },
    'college_specialization': {
      'ar': 'التخصص الجامعي',
      'en': 'College specialization',
      'tr': 'Üniversite bölümü',
    },
    'sponsor_linked_at': {
      'ar': 'تاريخ ربط الكفيل',
      'en': 'Sponsor linked at',
      'tr': 'Sponsor bağlantı tarihi',
    },
    'father_name': {'ar': 'اسم الأب', 'en': 'Father name', 'tr': 'Baba adı'},
    'father_id_number': {
      'ar': 'رقم هوية الأب',
      'en': 'Father ID number',
      'tr': 'Baba kimlik numarası',
    },
    'father_status': {
      'ar': 'حالة الأب',
      'en': 'Father status',
      'tr': 'Baba durumu',
    },
    'father_death_date': {
      'ar': 'تاريخ وفاة الأب',
      'en': 'Father death date',
      'tr': 'Baba ölüm tarihi',
    },
    'father_death_cause': {
      'ar': 'سبب وفاة الأب',
      'en': 'Father death cause',
      'tr': 'Baba ölüm nedeni',
    },
    'father_death_certificate_path': {
      'ar': 'مسار شهادة وفاة الأب',
      'en': 'Father death certificate path',
      'tr': 'Baba ölüm belgesi yolu',
    },
    'father_death_certificate_file_name': {
      'ar': 'اسم ملف شهادة وفاة الأب',
      'en': 'Father death certificate file name',
      'tr': 'Baba ölüm belgesi dosya adı',
    },
    'mother_name': {'ar': 'اسم الأم', 'en': 'Mother name', 'tr': 'Anne adı'},
    'mother_id_number': {
      'ar': 'رقم هوية الأم',
      'en': 'Mother ID number',
      'tr': 'Anne kimlik numarası',
    },
    'mother_status': {
      'ar': 'حالة الأم',
      'en': 'Mother status',
      'tr': 'Anne durumu',
    },
    'mother_death_date': {
      'ar': 'تاريخ وفاة الأم',
      'en': 'Mother death date',
      'tr': 'Anne ölüm tarihi',
    },
    'mother_death_cause': {
      'ar': 'سبب وفاة الأم',
      'en': 'Mother death cause',
      'tr': 'Anne ölüm nedeni',
    },
    'mother_death_certificate_path': {
      'ar': 'مسار شهادة وفاة الأم',
      'en': 'Mother death certificate path',
      'tr': 'Anne ölüm belgesi yolu',
    },
    'mother_death_certificate_file_name': {
      'ar': 'اسم ملف شهادة وفاة الأم',
      'en': 'Mother death certificate file name',
      'tr': 'Anne ölüm belgesi dosya adı',
    },
    'child_photo_path': {
      'ar': 'مسار صورة اليتيم',
      'en': 'Child photo path',
      'tr': 'Yetim fotoğraf yolu',
    },
    'child_photo_file_name': {
      'ar': 'اسم ملف صورة اليتيم',
      'en': 'Child photo file name',
      'tr': 'Yetim fotoğraf dosya adı',
    },
    'mother_id_photo_path': {
      'ar': 'مسار صورة هوية الأم',
      'en': 'Mother ID photo path',
      'tr': 'Anne kimlik fotoğrafı yolu',
    },
    'mother_id_photo_file_name': {
      'ar': 'اسم ملف صورة هوية الأم',
      'en': 'Mother ID photo file name',
      'tr': 'Anne kimlik fotoğrafı dosya adı',
    },
    'guardian_id_photo_path': {
      'ar': 'مسار صورة هوية الوصي',
      'en': 'Guardian ID photo path',
      'tr': 'Vasi kimlik fotoğrafı yolu',
    },
    'guardian_id_photo_file_name': {
      'ar': 'اسم ملف صورة هوية الوصي',
      'en': 'Guardian ID photo file name',
      'tr': 'Vasi kimlik fotoğrafı dosya adı',
    },
    'gender': {'ar': 'الجنس', 'en': 'Gender', 'tr': 'Cinsiyet'},
    'health_status': {
      'ar': 'الحالة الصحية',
      'en': 'Health status',
      'tr': 'Sağlık durumu',
    },
    'disability_type': {
      'ar': 'نوع الإعاقة',
      'en': 'Disability type',
      'tr': 'Engel türü',
    },
    'special_needs': {
      'ar': 'الاحتياجات الخاصة',
      'en': 'Special needs',
      'tr': 'Özel ihtiyaçlar',
    },
    'siblings': {'ar': 'الإخوة', 'en': 'Siblings', 'tr': 'Kardeşler'},
    'documents': {'ar': 'الوثائق', 'en': 'Documents', 'tr': 'Belgeler'},
    'sponsor': {'ar': 'الكفيل', 'en': 'Sponsor', 'tr': 'Sponsor'},
    'created_at': {
      'ar': 'تاريخ الإنشاء',
      'en': 'Created at',
      'tr': 'Oluşturulma tarihi',
    },
    'updated_at': {
      'ar': 'تاريخ التحديث',
      'en': 'Updated at',
      'tr': 'Güncellenme tarihi',
    },
    'created_by': {'ar': 'أنشئ بواسطة', 'en': 'Created by', 'tr': 'Oluşturan'},
    'updated_by': {
      'ar': 'حُدّث بواسطة',
      'en': 'Updated by',
      'tr': 'Güncelleyen',
    },
    'payment_method': {
      'ar': 'طريقة الدفع',
      'en': 'Payment method',
      'tr': 'Ödeme yöntemi',
    },
    'bank_name': {'ar': 'اسم البنك', 'en': 'Bank name', 'tr': 'Banka adı'},
    'bank_account_number': {
      'ar': 'رقم الحساب البنكي',
      'en': 'Bank account number',
      'tr': 'Banka hesap numarası',
    },
    'bank_iban': {'ar': 'رقم الآيبان', 'en': 'Bank IBAN', 'tr': 'Banka IBAN'},
    'bank_account_holder_name': {
      'ar': 'اسم صاحب الحساب البنكي',
      'en': 'Bank account holder name',
      'tr': 'Banka hesap sahibi',
    },
    'wallet_name': {
      'ar': 'اسم المحفظة',
      'en': 'Wallet name',
      'tr': 'Cüzdan adı',
    },
    'wallet_number': {
      'ar': 'رقم المحفظة',
      'en': 'Wallet number',
      'tr': 'Cüzdan numarası',
    },
    'wallet_holder_name': {
      'ar': 'اسم صاحب المحفظة',
      'en': 'Wallet holder name',
      'tr': 'Cüzdan sahibi',
    },
    'school_name': {'ar': 'اسم المدرسة', 'en': 'School name', 'tr': 'Okul adı'},
    'is_synced': {'ar': 'تمت المزامنة', 'en': 'Is synced', 'tr': 'Eşitlendi'},
  };

  static Uint8List exportChildren(
    List<Child> children, {
    String? languageCode,
  }) {
    final workbook = Excel.createExcel();
    final sheet = workbook[_sheetName];
    final firstChild =
        children.isEmpty ? Child(id: '', childIdNumber: '') : children.first;
    final headers = firstChild.toJson().keys.toList();
    final localizedHeaders =
        headers.map((header) {
          if (languageCode == null) return header;
          return _fieldLabels[header]?[languageCode] ??
              _fieldLabels[header]?['en'] ??
              header;
        }).toList();

    sheet.appendRow(localizedHeaders.map(TextCellValue.new).toList());
    for (final child in children) {
      final values =
          languageCode == null
              ? child.toJson()
              : _localizedValues(child, languageCode);
      sheet.appendRow(
        headers.map((header) {
          final value = values[header];
          return TextCellValue(value?.toString() ?? '');
        }).toList(),
      );
    }

    if (workbook.tables.containsKey('Sheet1')) workbook.delete('Sheet1');
    final bytes = workbook.encode();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to encode the children spreadsheet.');
    }
    return Uint8List.fromList(bytes);
  }

  static Map<String, dynamic> _localizedValues(
    Child child,
    String languageCode,
  ) {
    final values = child.toJson();
    values['country'] = _translateLocation(child.country, languageCode);
    values['city'] = _translateLocation(child.city, languageCode);
    values['birth_country'] = _translateLocation(
      child.birthCountry,
      languageCode,
      isCity: false,
    );
    values['birth_city'] = _translateLocation(
      child.birthCity,
      languageCode,
      isCity: true,
    );
    values['guardian_relationship'] = child.getGuardianRelationshipByLanguage(
      languageCode,
    );
    values['education_level'] = child.getEducationLevelByLanguage(languageCode);
    values['grade'] = child.getGradeByLanguage(languageCode);
    values['university_year'] = child.getUniversityYearByLanguage(languageCode);
    values['father_status'] = child.getFatherStatusByLanguage(languageCode);
    values['mother_status'] = child.getMotherStatusByLanguage(languageCode);
    values['health_status'] = child.getHealthStatusByLanguage(languageCode);
    values['gender'] = _localizedGender(child.gender, languageCode);
    return values;
  }

  static String? _translateLocation(
    String? value,
    String languageCode, {
    bool isCity = false,
  }) {
    if (value == null || value.isEmpty) return value;
    final candidates =
        isCity
            ? const [
              'غزة',
              'القدس',
              'رام الله',
              'الخليل',
              'نابلس',
              'جنين',
              'طولكرم',
              'قلقيلية',
              'بيت لحم',
              'أريحا',
              'رفح',
              'خان يونس',
              'دمشق',
              'حلب',
              'حمص',
              'إدلب',
              'اسطنبول',
              'أنقرة',
              'إزمير',
              'غازي عنتاب',
              'أورفة',
            ]
            : const [
              'فلسطين',
              'سوريا',
              'تركيا',
              'السعودية',
              'مصر',
              'الأردن',
              'لبنان',
              'العراق',
              'اليمن',
              'الإمارات',
              'السودان',
              'الكويت',
              'قطر',
              'البحرين',
              'عمان',
              'المغرب',
              'الجزائر',
              'تونس',
              'ليبيا',
            ];
    final normalized = _normalizeHeader(value);
    for (final candidate in candidates) {
      final child =
          isCity
              ? Child(id: '', childIdNumber: '', city: candidate)
              : Child(id: '', childIdNumber: '', country: candidate);
      final labels =
          isCity
              ? {
                'ar': child.getCityByLanguage('ar'),
                'en': child.getCityByLanguage('en'),
                'tr': child.getCityByLanguage('tr'),
              }
              : {
                'ar': child.getCountryByLanguage('ar'),
                'en': child.getCountryByLanguage('en'),
                'tr': child.getCountryByLanguage('tr'),
              };
      if (labels.values.any(
        (label) => label != null && _normalizeHeader(label) == normalized,
      )) {
        return labels[languageCode] ?? value;
      }
    }
    return value;
  }

  static String? _localizedGender(String? gender, String languageCode) {
    final normalized = _normalizeHeader(gender ?? '');
    if (['m', 'male', 'man', 'ذكر', 'erkek'].contains(normalized)) {
      return switch (languageCode) {
        'en' => 'Male',
        'tr' => 'Erkek',
        _ => 'ذكر',
      };
    }
    if ([
      'f',
      'female',
      'woman',
      'انثى',
      'kadın',
      'kadin',
    ].contains(normalized)) {
      return switch (languageCode) {
        'en' => 'Female',
        'tr' => 'Kadın',
        _ => 'أنثى',
      };
    }
    return gender;
  }

  static List<Map<String, dynamic>> importExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables.values.firstWhere(
      (sheet) => sheet.rows.isNotEmpty,
      orElse:
          () =>
              throw const FormatException(
                'The Excel file does not contain a non-empty worksheet.',
              ),
    );
    final rows = sheet.rows;
    final headerIndex = rows.indexWhere(
      (row) => row.any((cell) => _cellValue(cell) != null),
    );
    if (headerIndex < 0) {
      throw const FormatException('The Excel worksheet is empty.');
    }

    final headers =
        rows[headerIndex]
            .map((cell) => _mapHeader(_cellValue(cell)?.toString() ?? ''))
            .toList();
    if (!headers.contains('national_id') &&
        !headers.contains('first_name') &&
        !headers.contains('full_name')) {
      throw const FormatException(
        'The worksheet must include a child name or national ID column.',
      );
    }

    final imported = <Map<String, dynamic>>[];
    for (final row in rows.skip(headerIndex + 1)) {
      final values = <String, dynamic>{};
      for (
        var index = 0;
        index < headers.length && index < row.length;
        index++
      ) {
        final header = headers[index];
        final value = _cellValue(row[index]);
        if (header != null &&
            value != null &&
            value.toString().trim().isNotEmpty) {
          values[header] = value;
        }
      }
      if (values.isNotEmpty) imported.add(values);
    }

    if (imported.isEmpty) {
      throw const FormatException(
        'The Excel worksheet contains no child rows.',
      );
    }
    return imported;
  }

  static Future<List<Map<String, dynamic>>> importDatabase({
    String? path,
    Uint8List? bytes,
  }) {
    return readChildrenFromDatabase(path: path, bytes: bytes);
  }

  static dynamic _cellValue(Data? cell) {
    final value = cell?.value;
    if (value is TextCellValue) return value.value.text;
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is BoolCellValue) return value.value;
    if (value is FormulaCellValue) return value.formula;
    return value?.toString();
  }

  static String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]'), '');
  }

  static String? _mapHeader(String header) {
    final normalized = _normalizeHeader(header);
    for (final entry in _fieldLabels.entries) {
      if (_normalizeHeader(entry.key) == normalized ||
          _normalizeHeader(entry.key.replaceAll('_', '')) == normalized ||
          entry.value.values.any(
            (label) => _normalizeHeader(label) == normalized,
          )) {
        return entry.key;
      }
    }

    const aliases = {
      'رقمالهوية': 'national_id',
      'رقمالهويةالشخصية': 'national_id',
      'رقمالهويةالوطنية': 'national_id',
      'الهوية': 'national_id',
      'اسماليتيم': 'full_name',
      'اسماليتيمالكامل': 'full_name',
      'اسمالطفل': 'full_name',
      'الاسم': 'full_name',
      'الاسمالكامل': 'full_name',
      'cocugunadisoyadi': 'full_name',
      'cocugunadsoyadi': 'full_name',
      'cocukadsoyad': 'full_name',
      'adsoyad': 'full_name',
      'nameofchild': 'full_name',
      'fullname': 'full_name',
      'childname': 'full_name',
      'orphanname': 'full_name',
      'الاسمالاول': 'first_name',
      'الاسماءول': 'first_name',
      'cocukadi': 'first_name',
      'ad': 'first_name',
      'اسمالعائلة': 'last_name',
      'الكنية': 'last_name',
      'soyadi': 'last_name',
      'رمزاليتم': 'child_id_number',
      'رقماليتيم': 'child_id_number',
      'الدولة': 'country',
      'البلد': 'country',
      'ulke': 'country',
      'المدينة': 'city',
      'sehir': 'city',
      'الجنس': 'gender',
      'cinsiyet': 'gender',
      'تاريخالميلاد': 'date_of_birth',
      'dogumtarihi': 'date_of_birth',
      'اسمالاب': 'father_name',
      'babaadi': 'father_name',
      'اسمالام': 'mother_name',
      'anneadi': 'mother_name',
      'kimliknumarasi': 'national_id',
      'tckimlikno': 'national_id',
      'yetimnumarasi': 'child_id_number',
    };
    final alias = aliases[normalized];
    if (alias != null) return alias;

    return null;
  }

  static Child decodeChild(Map<String, dynamic> data) {
    final decoded = Map<String, dynamic>.from(data);
    final fullName = decoded.remove('full_name')?.toString().trim();
    if (fullName != null &&
        fullName.isNotEmpty &&
        (decoded['first_name'] == null || decoded['last_name'] == null)) {
      final names = fullName.split(RegExp(r'\s+'));
      decoded.putIfAbsent('first_name', () => names.first);
      if (names.length > 1) {
        decoded.putIfAbsent('last_name', () => names.last);
        if (names.length >= 3) {
          decoded.putIfAbsent('father_name', () => names[1]);
        }
        if (names.length >= 4) {
          decoded.putIfAbsent('grand_father_name', () => names[2]);
        }
      }
    }
    for (final key in ['siblings', 'documents', 'sponsor']) {
      final value = decoded[key];
      if (value is String && value.isNotEmpty) {
        decoded[key] = json.decode(value);
      }
    }
    _normalizeLocalizedValues(decoded);
    return Child.fromJson(decoded);
  }

  static void _normalizeLocalizedValues(Map<String, dynamic> values) {
    const localizedValues = <String, String>{
      'ذكر': 'M',
      'male': 'M',
      'erkek': 'M',
      'انثى': 'F',
      'female': 'F',
      'kadin': 'F',
      'kadın': 'F',
      'حي': 'Alive',
      'حية': 'Alive',
      'alive': 'Alive',
      'yasiyor': 'Alive',
      'yaşıyor': 'Alive',
      'متوفى': 'Deceased',
      'متوفية': 'Deceased',
      'deceased': 'Deceased',
      'vefatetti': 'Deceased',
      'صحي': 'Healthy',
      'healthy': 'Healthy',
      'saglikli': 'Healthy',
      'sağlıklı': 'Healthy',
      'مريض': 'Sick',
      'sick': 'Sick',
      'hasta': 'Sick',
      'معاق': 'Disabled',
      'ذوي احتياجات خاصة': 'Disabled',
      'disabled': 'Disabled',
      'engelli': 'Disabled',
      'الأم': 'Mother',
      'anne': 'Mother',
      'الجد': 'Grandfather',
      'buyukbaba': 'Grandfather',
      'büyükbaba': 'Grandfather',
      'الجدة': 'Grandmother',
      'buyukanne': 'Grandmother',
      'büyükanne': 'Grandmother',
      'العم': 'Uncle',
      'amca': 'Uncle',
      'العمة': 'Aunt',
      'hala': 'Aunt',
      'الخال': 'Maternal Uncle',
      'dayi': 'Maternal Uncle',
      'dayı': 'Maternal Uncle',
      'الخالة': 'Maternal Aunt',
      'teyze': 'Maternal Aunt',
      'الأخ': 'Brother',
      'erkek kardeş': 'Brother',
      'الأخت': 'Sister',
      'kız kardeş': 'Sister',
      'آخر': 'Other',
      'diger': 'Other',
      'diğer': 'Other',
      'ابتدائي': 'Primary',
      'ilkokul': 'Primary',
      'إعدادي': 'Middle',
      'ortaokul': 'Middle',
      'ثانوي': 'Secondary',
      'lise': 'Secondary',
      'جامعي': 'University',
      'üniversite': 'University',
      'universite': 'University',
      'كلية': 'College',
      'fakülte': 'College',
      'fakulte': 'College',
      'لا يدرس': 'Not studying',
      'okumuyor': 'Not studying',
      'ما دون عمر الدراسة': 'None',
      'مرحلة ما قبل الدراسة': 'None',
      'okul öncesi yaş': 'None',
      'okuloncesiyas': 'None',
      '1. Sınıf': '1st Grade',
      '2. Sınıf': '2nd Grade',
      '3. Sınıf': '3rd Grade',
      '4. Sınıf': '4th Grade',
      '5. Sınıf': '5th Grade',
      '6. Sınıf': '6th Grade',
      '7. Sınıf': '7th Grade',
      '8. Sınıf': '8th Grade',
      '9. Sınıf': '9th Grade',
      '10. Sınıf': '10th Grade',
      '11. Sınıf': '11th Grade',
      '12. Sınıf': '12th Grade',
      'الأول': '1st Grade',
      'الثاني': '2nd Grade',
      'الثالث': '3rd Grade',
      'الرابع': '4th Grade',
      'الخامس': '5th Grade',
      'السادس': '6th Grade',
      'السابع': '7th Grade',
      'الثامن': '8th Grade',
      'التاسع': '9th Grade',
      'العاشر': '10th Grade',
      'الحادي عشر': '11th Grade',
      'الثاني عشر': '12th Grade',
      'Birinci Yıl': 'First Year',
      'İkinci Yıl': 'Second Year',
      'Üçüncü Yıl': 'Third Year',
      'Dördüncü Yıl': 'Fourth Year',
      'Beşinci Yıl': 'Fifth Year',
      'Altıncı Yıl': 'Sixth Year',
      'السنة الأولى': 'First Year',
      'السنة الثانية': 'Second Year',
      'السنة الثالثة': 'Third Year',
      'السنة الرابعة': 'Fourth Year',
      'السنة الخامسة': 'Fifth Year',
      'السنة السادسة': 'Sixth Year',
      'خريج': 'Graduate',
      'Mezun': 'Graduate',
    };

    for (final key in [
      'gender',
      'father_status',
      'mother_status',
      'health_status',
      'guardian_relationship',
      'education_level',
      'grade',
      'university_year',
    ]) {
      final value = values[key];
      if (value is String) {
        final normalized = _normalizeHeader(value);
        String? translatedValue;
        for (final entry in localizedValues.entries) {
          if (_normalizeHeader(entry.key) == normalized) {
            translatedValue = entry.value;
            break;
          }
        }
        values[key] = translatedValue ?? value;
      }
    }
    for (final key in ['country', 'birth_country']) {
      final value = values[key];
      if (value is String) values[key] = _translateLocation(value, 'en');
    }
    for (final key in ['city', 'birth_city']) {
      final value = values[key];
      if (value is String) {
        values[key] = _translateLocation(value, 'en', isCity: true);
      }
    }
  }
}
