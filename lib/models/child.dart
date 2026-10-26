import 'dart:convert';
import 'document.dart';
import 'sponsor.dart';
import '../services/multilang_transliterator.dart';

class Child {
  String id;
  String firstName;
  String lastName;
  DateTime? dateOfBirth;
  String childIdNumber;
  String? nationalId;

  String fatherName;
  String fatherIdNumber;
  String fatherStatus; // Alive / Deceased
  DateTime? fatherDeathDate;
  String? fatherDeathCause;
  String? fatherDeathCertificatePath;
  String? fatherDeathCertificateFileName;
  String motherName;
  String motherIdNumber;
  String motherStatus; // Alive / Deceased
  DateTime? motherDeathDate;
  String? motherDeathCause;
  String? motherDeathCertificatePath;
  String? motherDeathCertificateFileName;

  // Child documents
  String? childPhotoPath;
  String? childPhotoFileName;
  String? motherIdPhotoPath;
  String? motherIdPhotoFileName;
  String? guardianIdPhotoPath;
  String? guardianIdPhotoFileName;

  // Gender: 'M' for Male, 'F' for Female
  String? gender;

  String healthStatus; // Healthy / Sick / Disabled
  String? disabilityType;
  String? specialNeeds;
  List<Map<String, dynamic>>
  siblings; // [{"name":"","id":"", "isSponsored": bool}, ...]

  // Address
  String? country;
  String? city;
  String? street;

  // Guardian details
  String? guardianRelationship;
  String? guardianPhone; // include country code prefix

  // Education
  String? educationLevel; // e.g., None, Primary, Middle, Secondary, University
  String?
  grade; // e.g., "1st Grade", "7th Grade" (mapped from school class keys)
  String?
  universityYear; // e.g., "First Year", "Second Year", etc. (for University)
  String?
  universityCollegeName; // e.g., "Faculty of Medicine", "School of Engineering"
  String? schoolName; // e.g., "Al-Aqsa School"

  // Bank Account Details
  String? bankName;
  String? bankAccountNumber;
  String? bankIban;
  String? bankAccountHolderName;

  // Sponsor link date
  DateTime? sponsorLinkedAt;

  List<Document> documents;

  Sponsor? sponsor;

  // Sponsorship details for reporting
  DateTime? sponsorshipStartDate;
  DateTime? sponsorshipEndDate;
  String? sponsorshipEndReason;

  DateTime createdAt;
  DateTime updatedAt;
  String? createdBy;
  String? updatedBy;
  bool isSynced;

  // Backwards compatibility: many UI call-sites still use `fullName`.
  String get fullName => '$firstName $fatherName $lastName';

  bool get isSponsored =>
      sponsor != null && sponsor!.name.trim().isNotEmpty && sponsor!.isOngoing;
  bool get isUnsponsored => !isSponsored;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nationalId,
    this.dateOfBirth,
    required this.childIdNumber,
    this.country,
    this.city,
    this.street,
    this.guardianRelationship,
    this.guardianPhone,
    this.educationLevel,
    this.grade,
    this.universityYear,
    this.universityCollegeName,
    this.sponsorLinkedAt,
    this.fatherName = '',
    this.fatherIdNumber = '',
    this.fatherStatus = 'Alive',
    this.fatherDeathDate,
    this.fatherDeathCause,
    this.fatherDeathCertificatePath,
    this.fatherDeathCertificateFileName,
    this.motherName = '',
    this.motherIdNumber = '',
    this.motherStatus = 'Alive',
    this.motherDeathDate,
    this.motherDeathCause,
    this.motherDeathCertificatePath,
    this.motherDeathCertificateFileName,
    this.childPhotoPath,
    this.childPhotoFileName,
    this.motherIdPhotoPath,
    this.motherIdPhotoFileName,
    this.guardianIdPhotoPath,
    this.guardianIdPhotoFileName,
    this.gender,
    this.healthStatus = 'Healthy',
    this.disabilityType,
    this.specialNeeds,
    List<Map<String, dynamic>>? siblings,
    List<Document>? documents,
    this.sponsor,
    this.sponsorshipStartDate,
    this.sponsorshipEndDate,
    this.sponsorshipEndReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.updatedBy,
    this.bankName,
    this.bankAccountNumber,
    this.bankIban,
    this.bankAccountHolderName,
    this.schoolName,
    this.isSynced = false,
  }) : siblings = siblings ?? [],
       documents = documents ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// ✅ الحصول على الاسم الكامل حسب اللغة (يتم حسابه عند الطلب فقط)
  String getFullNameByLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '${MultiLangTransliterator.toEnglish(firstName)} '
            '${MultiLangTransliterator.toEnglish(fatherName)} '
            '${MultiLangTransliterator.toEnglish(lastName)}';
      case 'tr':
        return '${MultiLangTransliterator.toTurkish(firstName)} '
            '${MultiLangTransliterator.toTurkish(fatherName)} '
            '${MultiLangTransliterator.toTurkish(lastName)}';
      default:
        return fullName; // العربي
    }
  }

  /// ✅ الحصول على اسم الأب حسب اللغة
  String getFatherNameByLanguage(String languageCode) {
    if (fatherName.isEmpty) return fatherName;
    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(fatherName);
      case 'tr':
        return MultiLangTransliterator.toTurkish(fatherName);
      default:
        return fatherName;
    }
  }

  /// ✅ الحصول على اسم الأم حسب اللغة
  String getMotherNameByLanguage(String languageCode) {
    if (motherName.isEmpty) return motherName;
    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(motherName);
      case 'tr':
        return MultiLangTransliterator.toTurkish(motherName);
      default:
        return motherName;
    }
  }

  /// ✅ الحصول على الاسم الأول حسب اللغة
  String getFirstNameByLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(firstName);
      case 'tr':
        return MultiLangTransliterator.toTurkish(firstName);
      default:
        return firstName;
    }
  }

  /// ✅ الحصول على اسم العائلة حسب اللغة
  String getLastNameByLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(lastName);
      case 'tr':
        return MultiLangTransliterator.toTurkish(lastName);
      default:
        return lastName;
    }
  }

  /// ✅ الحصول على الحالة الصحية حسب اللغة
  String getHealthStatusByLanguage(String languageCode) {
    // healthStatus يمكن أن يكون: Healthy, Sick, Disabled أو صحي، مريض، معاق
    final Map<String, Map<String, String>> healthTranslations = {
      'Healthy': {'ar': 'صحي', 'en': 'Healthy', 'tr': 'Sağlıklı'},
      'صحي': {'ar': 'صحي', 'en': 'Healthy', 'tr': 'Sağlıklı'},
      'Sick': {'ar': 'مريض', 'en': 'Sick', 'tr': 'Hasta'},
      'مريض': {'ar': 'مريض', 'en': 'Sick', 'tr': 'Hasta'},
      'Disabled': {
        'ar': 'ذوي احتياجات خاصة',
        'en': 'Disabled',
        'tr': 'Engelli',
      },
      'معاق': {'ar': 'ذوي احتياجات خاصة', 'en': 'Disabled', 'tr': 'Engelli'},
      'ذوي احتياجات خاصة': {
        'ar': 'ذوي احتياجات خاصة',
        'en': 'Disabled',
        'tr': 'Engelli',
      },
    };

    final translation = healthTranslations[healthStatus];
    if (translation != null) {
      return translation[languageCode] ?? healthStatus;
    }
    return healthStatus;
  }

  /// ✅ الحصول على الدولة حسب اللغة
  String? getCountryByLanguage(String languageCode) {
    if (country == null || country!.isEmpty) return country;

    // خريطة الدول بالعربية والإنجليزية والتركية
    final Map<String, Map<String, String>> countryTranslations = {
      'فلسطين': {'ar': 'فلسطين', 'en': 'Palestine', 'tr': 'Filistin'},
      'Palestine': {'ar': 'فلسطين', 'en': 'Palestine', 'tr': 'Filistin'},
      'سوريا': {'ar': 'سوريا', 'en': 'Syria', 'tr': 'Suriye'},
      'Syria': {'ar': 'سوريا', 'en': 'Syria', 'tr': 'Suriye'},
      'تركيا': {'ar': 'تركيا', 'en': 'Turkey', 'tr': 'Türkiye'},
      'Turkey': {'ar': 'تركيا', 'en': 'Turkey', 'tr': 'Türkiye'},
      'السعودية': {
        'ar': 'السعودية',
        'en': 'Saudi Arabia',
        'tr': 'Suudi Arabistan',
      },
      'Saudi Arabia': {
        'ar': 'السعودية',
        'en': 'Saudi Arabia',
        'tr': 'Suudi Arabistan',
      },
      'مصر': {'ar': 'مصر', 'en': 'Egypt', 'tr': 'Mısır'},
      'Egypt': {'ar': 'مصر', 'en': 'Egypt', 'tr': 'Mısır'},
      'الأردن': {'ar': 'الأردن', 'en': 'Jordan', 'tr': 'Ürdün'},
      'Jordan': {'ar': 'الأردن', 'en': 'Jordan', 'tr': 'Ürdün'},
      'لبنان': {'ar': 'لبنان', 'en': 'Lebanon', 'tr': 'Lübnan'},
      'Lebanon': {'ar': 'لبنان', 'en': 'Lebanon', 'tr': 'Lübnan'},
      'العراق': {'ar': 'العراق', 'en': 'Iraq', 'tr': 'Irak'},
      'Iraq': {'ar': 'العراق', 'en': 'Iraq', 'tr': 'Irak'},
      'اليمن': {'ar': 'اليمن', 'en': 'Yemen', 'tr': 'Yemen'},
      'Yemen': {'ar': 'اليمن', 'en': 'Yemen', 'tr': 'Yemen'},
      'الإمارات': {'ar': 'الإمارات', 'en': 'UAE', 'tr': 'BAE'},
      'UAE': {'ar': 'الإمارات', 'en': 'UAE', 'tr': 'BAE'},
      'السودان': {'ar': 'السودان', 'en': 'Sudan', 'tr': 'Sudan'},
      'Sudan': {'ar': 'السودان', 'en': 'Sudan', 'tr': 'Sudan'},
      'الكويت': {'ar': 'الكويت', 'en': 'Kuwait', 'tr': 'Kuveyt'},
      'Kuwait': {'ar': 'الكويت', 'en': 'Kuwait', 'tr': 'Kuveyt'},
      'قطر': {'ar': 'قطر', 'en': 'Qatar', 'tr': 'Katar'},
      'Qatar': {'ar': 'قطر', 'en': 'Qatar', 'tr': 'Katar'},
      'البحرين': {'ar': 'البحرين', 'en': 'Bahrain', 'tr': 'Bahreyn'},
      'Bahrain': {'ar': 'البحرين', 'en': 'Bahrain', 'tr': 'Bahreyn'},
      'عمان': {'ar': 'عمان', 'en': 'Oman', 'tr': 'Umman'},
      'Oman': {'ar': 'عمان', 'en': 'Oman', 'tr': 'Umman'},
      'المغرب': {'ar': 'المغرب', 'en': 'Morocco', 'tr': 'Fas'},
      'Morocco': {'ar': 'المغرب', 'en': 'Morocco', 'tr': 'Fas'},
      'الجزائر': {'ar': 'الجزائر', 'en': 'Algeria', 'tr': 'Cezayir'},
      'Algeria': {'ar': 'الجزائر', 'en': 'Algeria', 'tr': 'Cezayir'},
      'تونس': {'ar': 'تونس', 'en': 'Tunisia', 'tr': 'Tunus'},
      'Tunisia': {'ar': 'تونس', 'en': 'Tunisia', 'tr': 'Tunus'},
      'ليبيا': {'ar': 'ليبيا', 'en': 'Libya', 'tr': 'Libya'},
      'Libya': {'ar': 'ليبيا', 'en': 'Libya', 'tr': 'Libya'},
    };

    final translation = countryTranslations[country];
    if (translation != null) {
      return translation[languageCode] ?? country;
    }
    return country;
  }

  /// ✅ الحصول على الصف الدراسي حسب اللغة
  String? getGradeByLanguage(String languageCode) {
    if (grade == null || grade!.isEmpty) return grade;

    final Map<String, Map<String, String>> gradeTranslations = {
      // Primary
      'الأول': {'ar': 'الأول', 'en': '1st Grade', 'tr': '1. Sınıf'},
      '1st Grade': {'ar': 'الأول', 'en': '1st Grade', 'tr': '1. Sınıf'},
      'الثاني': {'ar': 'الثاني', 'en': '2nd Grade', 'tr': '2. Sınıf'},
      '2nd Grade': {'ar': 'الثاني', 'en': '2nd Grade', 'tr': '2. Sınıf'},
      'الثالث': {'ar': 'الثالث', 'en': '3rd Grade', 'tr': '3. Sınıf'},
      '3rd Grade': {'ar': 'الثالث', 'en': '3rd Grade', 'tr': '3. Sınıf'},
      'الرابع': {'ar': 'الرابع', 'en': '4th Grade', 'tr': '4. Sınıf'},
      '4th Grade': {'ar': 'الرابع', 'en': '4th Grade', 'tr': '4. Sınıf'},
      'الخامس': {'ar': 'الخامس', 'en': '5th Grade', 'tr': '5. Sınıf'},
      '5th Grade': {'ar': 'الخامس', 'en': '5th Grade', 'tr': '5. Sınıf'},
      'السادس': {'ar': 'السادس', 'en': '6th Grade', 'tr': '6. Sınıf'},
      '6th Grade': {'ar': 'السادس', 'en': '6th Grade', 'tr': '6. Sınıf'},
      // Middle
      'السابع': {'ar': 'السابع', 'en': '7th Grade', 'tr': '7. Sınıf'},
      '7th Grade': {'ar': 'السابع', 'en': '7th Grade', 'tr': '7. Sınıf'},
      'الثامن': {'ar': 'الثامن', 'en': '8th Grade', 'tr': '8. Sınıf'},
      '8th Grade': {'ar': 'الثامن', 'en': '8th Grade', 'tr': '8. Sınıf'},
      'التاسع': {'ar': 'التاسع', 'en': '9th Grade', 'tr': '9. Sınıf'},
      '9th Grade': {'ar': 'التاسع', 'en': '9th Grade', 'tr': '9. Sınıf'},
      // Secondary
      'العاشر': {'ar': 'العاشر', 'en': '10th Grade', 'tr': '10. Sınıf'},
      '10th Grade': {'ar': 'العاشر', 'en': '10th Grade', 'tr': '10. Sınıf'},
      'الحادي عشر': {'ar': 'الحادي عشر', 'en': '11th Grade', 'tr': '11. Sınıf'},
      '11th Grade': {'ar': 'الحادي عشر', 'en': '11th Grade', 'tr': '11. Sınıf'},
      'الثاني عشر': {'ar': 'الثاني عشر', 'en': '12th Grade', 'tr': '12. Sınıf'},
      '12th Grade': {'ar': 'الثاني عشر', 'en': '12th Grade', 'tr': '12. Sınıf'},
    };

    final translation = gradeTranslations[grade];
    if (translation != null) {
      return translation[languageCode] ?? grade;
    }
    return grade;
  }

  /// ✅ الحصول على السنة الجامعية حسب اللغة
  String? getUniversityYearByLanguage(String languageCode) {
    if (universityYear == null || universityYear!.isEmpty)
      return universityYear;

    final Map<String, Map<String, String>> yearTranslations = {
      'السنة الأولى': {
        'ar': 'السنة الأولى',
        'en': 'First Year',
        'tr': 'Birinci Yıl',
      },
      'First Year': {
        'ar': 'السنة الأولى',
        'en': 'First Year',
        'tr': 'Birinci Yıl',
      },
      'السنة الثانية': {
        'ar': 'السنة الثانية',
        'en': 'Second Year',
        'tr': 'İkinci Yıl',
      },
      'Second Year': {
        'ar': 'السنة الثانية',
        'en': 'Second Year',
        'tr': 'İkinci Yıl',
      },
      'السنة الثالثة': {
        'ar': 'السنة الثالثة',
        'en': 'Third Year',
        'tr': 'Üçüncü Yıl',
      },
      'Third Year': {
        'ar': 'السنة الثالثة',
        'en': 'Third Year',
        'tr': 'Üçüncü Yıl',
      },
      'السنة الرابعة': {
        'ar': 'السنة الرابعة',
        'en': 'Fourth Year',
        'tr': 'Dördüncü Yıl',
      },
      'Fourth Year': {
        'ar': 'السنة الرابعة',
        'en': 'Fourth Year',
        'tr': 'Dördüncü Yıl',
      },
      'السنة الخامسة': {
        'ar': 'السنة الخامسة',
        'en': 'Fifth Year',
        'tr': 'Beşinci Yıl',
      },
      'Fifth Year': {
        'ar': 'السنة الخامسة',
        'en': 'Fifth Year',
        'tr': 'Beşinci Yıl',
      },
      'السنة السادسة': {
        'ar': 'السنة السادسة',
        'en': 'Sixth Year',
        'tr': 'Altıncı Yıl',
      },
      'Sixth Year': {
        'ar': 'السنة السادسة',
        'en': 'Sixth Year',
        'tr': 'Altıncı Yıl',
      },
      'خريج': {'ar': 'خريج', 'en': 'Graduate', 'tr': 'Mezun'},
      'Graduate': {'ar': 'خريج', 'en': 'Graduate', 'tr': 'Mezun'},
    };

    final translation = yearTranslations[universityYear];
    if (translation != null) {
      return translation[languageCode] ?? universityYear;
    }
    return universityYear;
  }

  /// ✅ الحصول على مستوى التعليم حسب اللغة
  String? getEducationLevelByLanguage(String languageCode) {
    if (educationLevel == null || educationLevel!.isEmpty)
      return educationLevel;

    final Map<String, Map<String, String>> educationTranslations = {
      // None / Pre-school age
      'None': {
        'ar': 'ما دون عمر الدراسة',
        'en': 'Pre-school age',
        'tr': 'Okul öncesi yaş',
      },
      'بدون': {
        'ar': 'ما دون عمر الدراسة',
        'en': 'Pre-school age',
        'tr': 'Okul öncesi yaş',
      },
      'ما دون عمر الدراسة': {
        'ar': 'ما دون عمر الدراسة',
        'en': 'Pre-school age',
        'tr': 'Okul öncesi yaş',
      },
      // Not studying
      'لا يدرس': {'ar': 'لا يدرس', 'en': 'Not studying', 'tr': 'Okumuyor'},
      'Not studying': {'ar': 'لا يدرس', 'en': 'Not studying', 'tr': 'Okumuyor'},
      // Primary
      'Primary': {'ar': 'ابتدائي', 'en': 'Primary', 'tr': 'İlkokul'},
      'ابتدائي': {'ar': 'ابتدائي', 'en': 'Primary', 'tr': 'İlkokul'},
      // Middle
      'Middle': {'ar': 'إعدادي', 'en': 'Middle school', 'tr': 'Ortaokul'},
      'إعدادي': {'ar': 'إعدادي', 'en': 'Middle school', 'tr': 'Ortaokul'},
      // Secondary
      'Secondary': {'ar': 'ثانوي', 'en': 'High school', 'tr': 'Lise'},
      'ثانوي': {'ar': 'ثانوي', 'en': 'High school', 'tr': 'Lise'},
      // University
      'University': {'ar': 'جامعي', 'en': 'University', 'tr': 'Üniversite'},
      'جامعي': {'ar': 'جامعي', 'en': 'University', 'tr': 'Üniversite'},
    };

    final translation = educationTranslations[educationLevel];
    if (translation != null) {
      return translation[languageCode] ?? educationLevel;
    }
    return educationLevel;
  }

  /// ✅ الحصول على علاقة الوصي حسب اللغة
  String? getGuardianRelationshipByLanguage(String languageCode) {
    if (guardianRelationship == null || guardianRelationship!.isEmpty)
      return guardianRelationship;

    final Map<String, Map<String, String>> relationshipTranslations = {
      'Mother': {'ar': 'الأم', 'en': 'Mother', 'tr': 'Anne'},
      'الأم': {'ar': 'الأم', 'en': 'Mother', 'tr': 'Anne'},
      'أم': {'ar': 'الأم', 'en': 'Mother', 'tr': 'Anne'},
      'Grandfather': {'ar': 'الجد', 'en': 'Grandfather', 'tr': 'Büyükbaba'},
      'الجد': {'ar': 'الجد', 'en': 'Grandfather', 'tr': 'Büyükbaba'},
      'جد': {'ar': 'الجد', 'en': 'Grandfather', 'tr': 'Büyükbaba'},
      'Grandmother': {'ar': 'الجدة', 'en': 'Grandmother', 'tr': 'Büyükanne'},
      'الجدة': {'ar': 'الجدة', 'en': 'Grandmother', 'tr': 'Büyükanne'},
      'جدة': {'ar': 'الجدة', 'en': 'Grandmother', 'tr': 'Büyükanne'},
      'Uncle': {'ar': 'العم', 'en': 'Uncle', 'tr': 'Amca'},
      'العم': {'ar': 'العم', 'en': 'Uncle', 'tr': 'Amca'},
      'عم': {'ar': 'العم', 'en': 'Uncle', 'tr': 'Amca'},
      'Aunt': {'ar': 'العمة', 'en': 'Aunt', 'tr': 'Hala'},
      'العمة': {'ar': 'العمة', 'en': 'Aunt', 'tr': 'Hala'},
      'عمة': {'ar': 'العمة', 'en': 'Aunt', 'tr': 'Hala'},
      'Maternal Uncle': {'ar': 'الخال', 'en': 'Maternal Uncle', 'tr': 'Dayı'},
      'الخال': {'ar': 'الخال', 'en': 'Maternal Uncle', 'tr': 'Dayı'},
      'خال': {'ar': 'الخال', 'en': 'Maternal Uncle', 'tr': 'Dayı'},
      'Maternal Aunt': {'ar': 'الخالة', 'en': 'Maternal Aunt', 'tr': 'Teyze'},
      'الخالة': {'ar': 'الخالة', 'en': 'Maternal Aunt', 'tr': 'Teyze'},
      'خالة': {'ar': 'الخالة', 'en': 'Maternal Aunt', 'tr': 'Teyze'},
      'Brother': {'ar': 'الأخ', 'en': 'Brother', 'tr': 'Erkek Kardeş'},
      'الأخ': {'ar': 'الأخ', 'en': 'Brother', 'tr': 'Erkek Kardeş'},
      'أخ': {'ar': 'الأخ', 'en': 'Brother', 'tr': 'Erkek Kardeş'},
      'Sister': {'ar': 'الأخت', 'en': 'Sister', 'tr': 'Kız Kardeş'},
      'الأخت': {'ar': 'الأخت', 'en': 'Sister', 'tr': 'Kız Kardeş'},
      'أخت': {'ar': 'الأخت', 'en': 'Sister', 'tr': 'Kız Kardeş'},
      'Other': {'ar': 'آخر', 'en': 'Other', 'tr': 'Diğer'},
      'آخر': {'ar': 'آخر', 'en': 'Other', 'tr': 'Diğer'},
    };

    final translation = relationshipTranslations[guardianRelationship];
    if (translation != null) {
      return translation[languageCode] ?? guardianRelationship;
    }
    return guardianRelationship;
  }

  /// ✅ الحصول على المدينة حسب اللغة
  String? getCityByLanguage(String languageCode) {
    if (city == null || city!.isEmpty) return city;

    final Map<String, Map<String, String>> cityTranslations = {
      // فلسطين
      'غزة': {'ar': 'غزة', 'en': 'Gaza', 'tr': 'Gazze'},
      'Gaza': {'ar': 'غزة', 'en': 'Gaza', 'tr': 'Gazze'},
      'القدس': {'ar': 'القدس', 'en': 'Jerusalem', 'tr': 'Kudüs'},
      'Jerusalem': {'ar': 'القدس', 'en': 'Jerusalem', 'tr': 'Kudüs'},
      'رام الله': {'ar': 'رام الله', 'en': 'Ramallah', 'tr': 'Ramallah'},
      'Ramallah': {'ar': 'رام الله', 'en': 'Ramallah', 'tr': 'Ramallah'},
      'الخليل': {'ar': 'الخليل', 'en': 'Hebron', 'tr': 'El Halil'},
      'Hebron': {'ar': 'الخليل', 'en': 'Hebron', 'tr': 'El Halil'},
      'نابلس': {'ar': 'نابلس', 'en': 'Nablus', 'tr': 'Nablus'},
      'Nablus': {'ar': 'نابلس', 'en': 'Nablus', 'tr': 'Nablus'},
      'جنين': {'ar': 'جنين', 'en': 'Jenin', 'tr': 'Cenin'},
      'Jenin': {'ar': 'جنين', 'en': 'Jenin', 'tr': 'Cenin'},
      'طولكرم': {'ar': 'طولكرم', 'en': 'Tulkarm', 'tr': 'Tulkarm'},
      'Tulkarm': {'ar': 'طولكرم', 'en': 'Tulkarm', 'tr': 'Tulkarm'},
      'قلقيلية': {'ar': 'قلقيلية', 'en': 'Qalqilya', 'tr': 'Kalkilya'},
      'Qalqilya': {'ar': 'قلقيلية', 'en': 'Qalqilya', 'tr': 'Kalkilya'},
      'بيت لحم': {'ar': 'بيت لحم', 'en': 'Bethlehem', 'tr': 'Beytüllahim'},
      'Bethlehem': {'ar': 'بيت لحم', 'en': 'Bethlehem', 'tr': 'Beytüllahim'},
      'أريحا': {'ar': 'أريحا', 'en': 'Jericho', 'tr': 'Eriha'},
      'Jericho': {'ar': 'أريحا', 'en': 'Jericho', 'tr': 'Eriha'},
      'رفح': {'ar': 'رفح', 'en': 'Rafah', 'tr': 'Refah'},
      'Rafah': {'ar': 'رفح', 'en': 'Rafah', 'tr': 'Refah'},
      'خان يونس': {'ar': 'خان يونس', 'en': 'Khan Younis', 'tr': 'Han Yunus'},
      'Khan Younis': {'ar': 'خان يونس', 'en': 'Khan Younis', 'tr': 'Han Yunus'},
      // سوريا
      'دمشق': {'ar': 'دمشق', 'en': 'Damascus', 'tr': 'Şam'},
      'Damascus': {'ar': 'دمشق', 'en': 'Damascus', 'tr': 'Şam'},
      'حلب': {'ar': 'حلب', 'en': 'Aleppo', 'tr': 'Halep'},
      'Aleppo': {'ar': 'حلب', 'en': 'Aleppo', 'tr': 'Halep'},
      'حمص': {'ar': 'حمص', 'en': 'Homs', 'tr': 'Humus'},
      'Homs': {'ar': 'حمص', 'en': 'Homs', 'tr': 'Humus'},
      'إدلب': {'ar': 'إدلب', 'en': 'Idlib', 'tr': 'İdlib'},
      'Idlib': {'ar': 'إدلب', 'en': 'Idlib', 'tr': 'İdlib'},
      // تركيا
      'اسطنبول': {'ar': 'اسطنبول', 'en': 'Istanbul', 'tr': 'İstanbul'},
      'Istanbul': {'ar': 'اسطنبول', 'en': 'Istanbul', 'tr': 'İstanbul'},
      'أنقرة': {'ar': 'أنقرة', 'en': 'Ankara', 'tr': 'Ankara'},
      'Ankara': {'ar': 'أنقرة', 'en': 'Ankara', 'tr': 'Ankara'},
      'إزمير': {'ar': 'إزمير', 'en': 'Izmir', 'tr': 'İzmir'},
      'Izmir': {'ar': 'إزمير', 'en': 'Izmir', 'tr': 'İzmir'},
      'غازي عنتاب': {'ar': 'غازي عنتاب', 'en': 'Gaziantep', 'tr': 'Gaziantep'},
      'Gaziantep': {'ar': 'غازي عنتاب', 'en': 'Gaziantep', 'tr': 'Gaziantep'},
      'أورفة': {'ar': 'أورفة', 'en': 'Urfa', 'tr': 'Şanlıurfa'},
      'Urfa': {'ar': 'أورفة', 'en': 'Urfa', 'tr': 'Şanlıurfa'},
      'Şanlıurfa': {'ar': 'أورفة', 'en': 'Urfa', 'tr': 'Şanlıurfa'},
    };

    final translation = cityTranslations[city];
    if (translation != null) {
      return translation[languageCode] ?? city;
    }
    return city;
  }

  /// ✅ الحصول على حالة الأب حسب اللغة
  String getFatherStatusByLanguage(String languageCode) {
    final Map<String, Map<String, String>> statusTranslations = {
      'Alive': {'ar': 'حي', 'en': 'Alive', 'tr': 'Yaşıyor'},
      'حي': {'ar': 'حي', 'en': 'Alive', 'tr': 'Yaşıyor'},
      'Deceased': {'ar': 'متوفى', 'en': 'Deceased', 'tr': 'Vefat etti'},
      'متوفى': {'ar': 'متوفى', 'en': 'Deceased', 'tr': 'Vefat etti'},
    };

    final translation = statusTranslations[fatherStatus];
    if (translation != null) {
      return translation[languageCode] ?? fatherStatus;
    }
    return fatherStatus;
  }

  /// ✅ الحصول على حالة الأم حسب اللغة
  String getMotherStatusByLanguage(String languageCode) {
    final Map<String, Map<String, String>> statusTranslations = {
      'Alive': {'ar': 'حية', 'en': 'Alive', 'tr': 'Yaşıyor'},
      'حية': {'ar': 'حية', 'en': 'Alive', 'tr': 'Yaşıyor'},
      'Deceased': {'ar': 'متوفية', 'en': 'Deceased', 'tr': 'Vefat etti'},
      'متوفية': {'ar': 'متوفية', 'en': 'Deceased', 'tr': 'Vefat etti'},
    };

    final translation = statusTranslations[motherStatus];
    if (translation != null) {
      return translation[languageCode] ?? motherStatus;
    }
    return motherStatus;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'national_id': nationalId,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'child_id_number': childIdNumber,
    'country': country,
    'city': city,
    'street': street,
    'guardian_relationship': guardianRelationship,
    'guardian_phone': guardianPhone,
    'education_level': educationLevel,
    'grade': grade,
    'university_year': universityYear,
    'university_college_name': universityCollegeName,
    'sponsor_linked_at': sponsorLinkedAt?.toIso8601String(),
    'father_name': fatherName,
    'father_id_number': fatherIdNumber,
    'father_status': fatherStatus,
    'father_death_date': fatherDeathDate?.toIso8601String(),
    'father_death_cause': fatherDeathCause,
    'father_death_certificate_path': fatherDeathCertificatePath,
    'father_death_certificate_file_name': fatherDeathCertificateFileName,
    'mother_name': motherName,
    'mother_id_number': motherIdNumber,
    'mother_status': motherStatus,
    'mother_death_date': motherDeathDate?.toIso8601String(),
    'mother_death_cause': motherDeathCause,
    'mother_death_certificate_path': motherDeathCertificatePath,
    'mother_death_certificate_file_name': motherDeathCertificateFileName,
    'child_photo_path': childPhotoPath,
    'child_photo_file_name': childPhotoFileName,
    'mother_id_photo_path': motherIdPhotoPath,
    'mother_id_photo_file_name': motherIdPhotoFileName,
    'guardian_id_photo_path': guardianIdPhotoPath,
    'guardian_id_photo_file_name': guardianIdPhotoFileName,
    'gender': gender,
    'health_status': healthStatus,
    'disability_type': disabilityType,
    'special_needs': specialNeeds,
    'siblings': json.encode(siblings),
    'documents': json.encode(documents.map((d) => d.toJson()).toList()),
    'sponsor': sponsor != null ? json.encode(sponsor!.toJson()) : null,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'created_by': createdBy,
    'updated_by': updatedBy,
    'bank_name': bankName,
    'bank_account_number': bankAccountNumber,
    'bank_iban': bankIban,
    'bank_account_holder_name': bankAccountHolderName,
    'school_name': schoolName,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Child.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value == null) return fallback ?? DateTime.now();
      if (value is String)
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      if (value is DateTime) return value;
      // Handle Firestore Timestamp if needed
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
      return fallback ?? DateTime.now();
    }

    return Child(
      id: j['id']?.toString() ?? '',
      firstName:
          j['firstName']?.toString() ?? j['first_name']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? j['last_name']?.toString() ?? '',
      nationalId: j['nationalId']?.toString() ?? j['national_id']?.toString(),
      dateOfBirth: parseDate(j['dateOfBirth'] ?? j['date_of_birth']),
      childIdNumber:
          j['childIdNumber']?.toString() ??
          j['child_id_number']?.toString() ??
          '',
      country: j['country']?.toString(),
      city: j['city']?.toString(),
      street: j['street']?.toString(),
      guardianRelationship:
          j['guardianRelationship']?.toString() ??
          j['guardian_relationship']?.toString(),
      guardianPhone:
          j['guardianPhone']?.toString() ?? j['guardian_phone']?.toString(),
      educationLevel:
          j['educationLevel']?.toString() ?? j['education_level']?.toString(),
      grade: j['grade']?.toString(),
      universityYear:
          j['universityYear']?.toString() ?? j['university_year']?.toString(),
      universityCollegeName:
          j['universityCollegeName']?.toString() ??
          j['university_college_name']?.toString(),
      sponsorLinkedAt:
          (j['sponsorLinkedAt'] != null || j['sponsor_linked_at'] != null)
              ? parseDate(j['sponsorLinkedAt'] ?? j['sponsor_linked_at'])
              : null,
      fatherName:
          j['fatherName']?.toString() ?? j['father_name']?.toString() ?? '',
      fatherIdNumber:
          j['fatherIdNumber']?.toString() ??
          j['father_id_number']?.toString() ??
          '',
      fatherStatus:
          j['fatherStatus']?.toString() ??
          j['father_status']?.toString() ??
          'Alive',
      fatherDeathDate:
          (j['fatherDeathDate'] != null || j['father_death_date'] != null)
              ? parseDate(j['fatherDeathDate'] ?? j['father_death_date'])
              : null,
      fatherDeathCause:
          j['fatherDeathCause']?.toString() ??
          j['father_death_cause']?.toString(),
      fatherDeathCertificatePath:
          j['fatherDeathCertificatePath']?.toString() ??
          j['father_death_certificate_path']?.toString(),
      fatherDeathCertificateFileName:
          j['fatherDeathCertificateFileName']?.toString() ??
          j['father_death_certificate_file_name']?.toString(),
      motherName:
          j['motherName']?.toString() ?? j['mother_name']?.toString() ?? '',
      motherIdNumber:
          j['motherIdNumber']?.toString() ??
          j['mother_id_number']?.toString() ??
          '',
      motherStatus:
          j['motherStatus']?.toString() ??
          j['mother_status']?.toString() ??
          'Alive',
      motherDeathDate:
          (j['motherDeathDate'] != null || j['mother_death_date'] != null)
              ? parseDate(j['motherDeathDate'] ?? j['mother_death_date'])
              : null,
      motherDeathCause:
          j['motherDeathCause']?.toString() ??
          j['mother_death_cause']?.toString(),
      motherDeathCertificatePath:
          j['motherDeathCertificatePath']?.toString() ??
          j['mother_death_certificate_path']?.toString(),
      motherDeathCertificateFileName:
          j['motherDeathCertificateFileName']?.toString() ??
          j['mother_death_certificate_file_name']?.toString(),
      childPhotoPath:
          j['childPhotoPath']?.toString() ?? j['child_photo_path']?.toString(),
      childPhotoFileName:
          j['childPhotoFileName']?.toString() ??
          j['child_photo_file_name']?.toString(),
      motherIdPhotoPath:
          j['motherIdPhotoPath']?.toString() ??
          j['mother_id_photo_path']?.toString(),
      motherIdPhotoFileName:
          j['motherIdPhotoFileName']?.toString() ??
          j['mother_id_photo_file_name']?.toString(),
      guardianIdPhotoPath:
          j['guardianIdPhotoPath']?.toString() ??
          j['guardian_id_photo_path']?.toString(),
      guardianIdPhotoFileName:
          j['guardianIdPhotoFileName']?.toString() ??
          j['guardian_id_photo_file_name']?.toString(),
      gender: j['gender']?.toString(),
      healthStatus:
          j['healthStatus']?.toString() ??
          j['health_status']?.toString() ??
          'Healthy',
      disabilityType:
          j['disabilityType']?.toString() ?? j['disability_type']?.toString(),
      specialNeeds:
          j['specialNeeds']?.toString() ?? j['special_needs']?.toString(),
      siblings:
          (j['siblings'] is List)
              ? (j['siblings'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : <Map<String, dynamic>>[],
      documents:
          (j['documents'] is List)
              ? (j['documents'] as List)
                  .map((e) => Document.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : <Document>[],
      sponsor:
          j['sponsor'] != null
              ? Sponsor.fromJson(Map<String, dynamic>.from(j['sponsor']))
              : null,
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: parseDate(
        j['updatedAt'] ?? j['updated_at'] ?? j['createdAt'] ?? j['created_at'],
        fallback: DateTime.now(),
      ),
      createdBy: j['createdBy']?.toString() ?? j['created_by']?.toString(),
      updatedBy: j['updatedBy']?.toString() ?? j['updated_by']?.toString(),
      bankName: j['bankName']?.toString() ?? j['bank_name']?.toString(),
      bankAccountNumber:
          j['bankAccountNumber']?.toString() ??
          j['bank_account_number']?.toString(),
      bankIban: j['bankIban']?.toString() ?? j['bank_iban']?.toString(),
      bankAccountHolderName:
          j['bankAccountHolderName']?.toString() ??
          j['bank_account_holder_name']?.toString(),
      schoolName: j['schoolName']?.toString() ?? j['school_name']?.toString(),
      isSynced:
          j['is_synced'] == 1 ||
          j['is_synced'] == true ||
          j['isSynced'] == true,
    );
  }

  String toRawJson() => json.encode(toJson());
  factory Child.fromRawJson(String s) => Child.fromJson(json.decode(s));
}
