import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/child.dart';
import '../../models/document.dart';
import '../../models/sponsor.dart';
import '../../models/payment.dart';
import 'registration_form_i18n.dart';
import '../../models/country.dart';
import '../../models/organization.dart';
import '../../models/city.dart';
import '../../services/storage_service.dart';
import '../../services/sqlite_service.dart';
import '../../services/multilang_transliterator.dart';
import '../reports/pdf_report.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_extension.dart';
import '../../services/face_detection_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/github_storage_service.dart';
import '../../services/settings_service.dart';
import '../../services/web_cache_service.dart';
import 'package:path/path.dart' as p;

enum _SiblingSaveChoice {
  cancel,
  saveFamilyOnly,
  registerSelected,
  registerAll,
}

mixin RegistrationFormLogic {
  // ==================== Variables ====================

  // Saving status notifier
  final ValueNotifier<String> _savingStatus = ValueNotifier('جاري البدء...');

  // Country management
  List<Country> countries = [];
  Country? selectedCountry;
  List<Map<String, dynamic>> cities = [];
  String? selectedCity;
  // Cache for cities to avoid re-fetching
  final Map<int, List<Map<String, dynamic>>> _citiesCache = {};
  // Cache for next available child ID per country to make generation instant
  final Map<String, String> _childIdCache = {};

  // Place of Birth variables
  Country? selectedBirthCountry;
  List<Map<String, dynamic>> birthCities = [];
  String? selectedBirthCity;
  final birthCountryCtl = TextEditingController();
  final birthCityCtl = TextEditingController();
  final grandfatherNameFocus = FocusNode();

  // Controllers - Basic Info
  final firstNameCtl = TextEditingController();
  final lastNameCtl = TextEditingController();
  final fatherNameCtl = TextEditingController();
  final grandfatherNameCtl = TextEditingController();
  final familyNameCtl = TextEditingController();
  final childIdCtl = TextEditingController();
  final countryCtl = TextEditingController();
  final cityCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final streetCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final birthDateCtl = TextEditingController();
  final nationalIdCtl = TextEditingController();
  final ageCtl = TextEditingController();
  final notesCtl = TextEditingController();
  final familyMembersCtl = TextEditingController();

  // Controllers - Parents & Guardian Info
  final fatherFullNameCtl = TextEditingController();
  final fatherIdCtl = TextEditingController();
  final motherFullNameCtl = TextEditingController();
  final motherIdCtl = TextEditingController();
  final guardianNameCtl = TextEditingController();
  final guardianAddressCtl = TextEditingController();
  final guardianPhoneCtl = TextEditingController();
  final fatherDeathDateCtl = TextEditingController();
  final motherDeathDateCtl = TextEditingController();

  // Controllers - Health & Education
  final schoolLevelCtl = TextEditingController();
  final schoolStageCtl = TextEditingController();
  final schoolNameCtl = TextEditingController();
  final universityNameCtl = TextEditingController();
  final universityCollegeCtl = TextEditingController();
  final collegeSpecializationCtl = TextEditingController();
  final universityYearCtl = TextEditingController();
  final disabilityCtl = TextEditingController();
  final diseaseCtl = TextEditingController();

  // Financial / Payment Details
  String paymentMethod = 'bank'; // 'bank' or 'wallet'
  final TextEditingController bankNameCtl = TextEditingController();
  final TextEditingController bankAccountNumberCtl = TextEditingController();
  final TextEditingController bankIbanCtl = TextEditingController();
  final TextEditingController bankAccountHolderNameCtl =
      TextEditingController();
  final TextEditingController walletNumberCtl =
      TextEditingController(); // رقم الموبايل المرتبط (للبنك والمحفظة)
  final TextEditingController walletHolderNameCtl =
      TextEditingController(); // اسم صاحب المحفظة

  // Controllers - Sponsor
  final sponsorNameCtl = TextEditingController();
  final sponsorPhoneCtl = TextEditingController();
  final sponsorWhatsappCtl = TextEditingController();
  final sponsorAmountCtl = TextEditingController();
  final sponsorStartDateCtl = TextEditingController();
  final sponsorNotesCtl = TextEditingController();

  // ==================== Focus Nodes ====================
  // Focus Nodes - Basic Info
  final firstNameFocus = FocusNode();
  final familyNameFocus = FocusNode();
  final birthDateFocus = FocusNode();
  final nationalIdFocus = FocusNode();
  final streetFocus = FocusNode();

  // Focus Nodes - Parents & Guardian
  final fatherNameFocus = FocusNode();
  final fatherIdFocus = FocusNode();
  final motherNameFocus = FocusNode();
  final motherIdFocus = FocusNode();
  final guardianNameFocus = FocusNode();
  final guardianPhoneFocus = FocusNode();
  final guardianAddressFocus = FocusNode();
  final fatherDeathDateFocus = FocusNode();
  final motherDeathDateFocus = FocusNode();

  // Focus Nodes - Education & Health
  final disabilityFocus = FocusNode();

  // Focus Nodes - Sponsor
  final sponsorNameFocus = FocusNode();
  final sponsorPhoneFocus = FocusNode();
  final sponsorAmountFocus = FocusNode();

  // State variables
  String? gender = 'M';
  DateTime? dateOfBirth;
  String? fatherStatus = 'Alive';
  String? motherStatus = 'Alive';
  String? fatherDeathCause;
  String? motherDeathCause;
  String? guardianRelationship = 'Uncle';
  String healthStatus = 'Healthy';
  String? disabilityType;

  // Education fields
  String? educationLevel =
      'education_level_none'; // Pre-school, Primary, Middle, Secondary, University, No School
  String? schoolClass; // Grade/Class for Primary, Middle, Secondary
  String? universityYear; // Academic year for University level
  String sponsorType = 'Monthly';
  String orphanSponsorshipStatus = 'unsponsored';
  bool includeFinancialDataInReport = false;
  int currentStep = 0;
  bool showSidebar = true;

  // Transliteration Previews
  String transliteratedFirstNameEn = '';
  String transliteratedLastNameEn = '';
  String transliteratedFatherNameEn = '';
  String transliteratedGrandfatherNameEn = '';
  String transliteratedFirstNameTr = '';
  String transliteratedLastNameTr = '';
  String transliteratedFatherNameTr = '';
  String transliteratedGrandfatherNameTr = '';
  bool _transliterationUpdateScheduled = false;

  // Documents
  List<Document> documents = [];
  List<Document> certificates = [];
  List<Document> medicalReports = [];
  File? fatherDeathCertificateImage;
  File? motherDeathCertificateImage;

  // Siblings
  List<Map<String, dynamic>> siblingsList = [];

  // Sponsors
  List<Sponsor> sponsors = [];
  List<Sponsor> masterSponsors = []; // Full sponsor objects from database
  List<Map<String, dynamic>> organizations = [];

  // Payments
  List<Payment> payments = [];

  // Currencies
  final List<String> currencies = ['شيكل', 'دولار', 'دينار', 'يورو'];
  String? selectedCurrency = 'شيكل';

  // Services
  final _storage = StorageService();
  final _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  // ==================== Methods ====================

  /// Initialize form - called from initState
  Future<void> initializeForm() async {
    final childWidget = (this as dynamic).widget.child;

    // 1. Load basic required data first - optimized to use assets/local
    await loadCountries();

    if (childWidget != null) {
      // 2. Populate form immediately with widget data
      await _populateFormFromChild(childWidget);
      // Fresh data in background to not block UI
      unawaited(loadExistingChildData());
    } else {
      unawaited(generateNewChildId());
    }

    // 3. Load remaining data in background
    unawaited(loadOrganizations());
    unawaited(loadSponsors());

    // 4. Add listeners for auto-transliteration
    firstNameCtl.addListener(_updateTransliterations);
    familyNameCtl.addListener(_updateFatherAndTransliterations);
    fatherNameCtl.addListener(_updateFatherFullName);
    grandfatherNameCtl.addListener(_updateFatherAndTransliterations);
  }

  void _updateFatherFullName() {
    final parts =
        [
          fatherNameCtl.text.trim(),
          grandfatherNameCtl.text.trim(),
          familyNameCtl.text.trim(),
        ].where((part) => part.isNotEmpty).toList();
    final fullName = parts.join(' ');
    if (fatherFullNameCtl.text != fullName) {
      fatherFullNameCtl.text = fullName;
    }
  }

  void _updateFatherAndTransliterations() {
    _updateFatherFullName();
    _updateTransliterations();
  }

  void _updateTransliterations() {
    if (_transliterationUpdateScheduled) return;
    _transliterationUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transliterationUpdateScheduled = false;
      if (!(this as dynamic).mounted) return;

      final first = firstNameCtl.text.trim();
      final last = familyNameCtl.text.trim();
      final father = fatherNameCtl.text.trim();
      final grand = grandfatherNameCtl.text.trim();
      final nextFirstEn =
          first.isEmpty ? '' : MultiLangTransliterator.toEnglish(first);
      final nextLastEn =
          last.isEmpty ? '' : MultiLangTransliterator.toEnglish(last);
      final nextFatherEn =
          father.isEmpty ? '' : MultiLangTransliterator.toEnglish(father);
      final nextGrandfatherEn =
          grand.isEmpty ? '' : MultiLangTransliterator.toEnglish(grand);
      final nextFirstTr =
          first.isEmpty ? '' : MultiLangTransliterator.toTurkish(first);
      final nextLastTr =
          last.isEmpty ? '' : MultiLangTransliterator.toTurkish(last);
      final nextFatherTr =
          father.isEmpty ? '' : MultiLangTransliterator.toTurkish(father);
      final nextGrandfatherTr =
          grand.isEmpty ? '' : MultiLangTransliterator.toTurkish(grand);

      if (nextFirstEn == transliteratedFirstNameEn &&
          nextLastEn == transliteratedLastNameEn &&
          nextFatherEn == transliteratedFatherNameEn &&
          nextGrandfatherEn == transliteratedGrandfatherNameEn &&
          nextFirstTr == transliteratedFirstNameTr &&
          nextLastTr == transliteratedLastNameTr &&
          nextFatherTr == transliteratedFatherNameTr &&
          nextGrandfatherTr == transliteratedGrandfatherNameTr) {
        return;
      }

      (this as dynamic).setState(() {
        transliteratedFirstNameEn = nextFirstEn;
        transliteratedLastNameEn = nextLastEn;
        transliteratedFatherNameEn = nextFatherEn;
        transliteratedGrandfatherNameEn = nextGrandfatherEn;
        transliteratedFirstNameTr = nextFirstTr;
        transliteratedLastNameTr = nextLastTr;
        transliteratedFatherNameTr = nextFatherTr;
        transliteratedGrandfatherNameTr = nextGrandfatherTr;
      });
    });
  }

  /// Dispose controllers
  void disposeRegistrationFormLogic() {
    firstNameCtl.dispose();
    lastNameCtl.dispose();
    fatherNameCtl.dispose();
    grandfatherNameCtl.dispose();
    familyNameCtl.dispose();
    birthCountryCtl.dispose();
    birthCityCtl.dispose();
    grandfatherNameFocus.dispose();
    childIdCtl.dispose();
    countryCtl.dispose();
    cityCtl.dispose();
    addressCtl.dispose();
    streetCtl.dispose();
    phoneCtl.dispose();
    birthDateCtl.dispose();
    nationalIdCtl.dispose();
    ageCtl.dispose();
    notesCtl.dispose();
    familyMembersCtl.dispose();
    fatherFullNameCtl.dispose();
    fatherIdCtl.dispose();
    motherFullNameCtl.dispose();
    motherIdCtl.dispose();
    guardianNameCtl.dispose();
    guardianAddressCtl.dispose();
    guardianPhoneCtl.dispose();
    fatherDeathDateCtl.dispose();
    motherDeathDateCtl.dispose();
    schoolLevelCtl.dispose();
    schoolStageCtl.dispose();
    schoolNameCtl.dispose();
    universityNameCtl.dispose();
    universityCollegeCtl.dispose();
    collegeSpecializationCtl.dispose();
    universityYearCtl.dispose();
    disabilityCtl.dispose();
    diseaseCtl.dispose();
    sponsorNameCtl.dispose();
    sponsorPhoneCtl.dispose();
    sponsorWhatsappCtl.dispose();
    sponsorAmountCtl.dispose();
    sponsorStartDateCtl.dispose();
    sponsorNotesCtl.dispose();

    bankNameCtl.dispose();
    bankAccountNumberCtl.dispose();
    bankIbanCtl.dispose();
    bankAccountHolderNameCtl.dispose();
    walletNumberCtl.dispose();
    walletHolderNameCtl.dispose();

    firstNameFocus.dispose();
    familyNameFocus.dispose();
    birthDateFocus.dispose();
    nationalIdFocus.dispose();
    streetFocus.dispose();
    fatherNameFocus.dispose();
    fatherIdFocus.dispose();
    motherNameFocus.dispose();
    motherIdFocus.dispose();
    guardianNameFocus.dispose();
    guardianPhoneFocus.dispose();
    guardianAddressFocus.dispose();
    fatherDeathDateFocus.dispose();
    motherDeathDateFocus.dispose();
    disabilityFocus.dispose();
    sponsorNameFocus.dispose();
    sponsorPhoneFocus.dispose();
    sponsorAmountFocus.dispose();
    _savingStatus.dispose();
  }

  /// Helper method to get TextDirection based on locale
  TextDirection getTextDirection(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Helper method to get MainAxisAlignment based on text direction
  MainAxisAlignment getAlignment(BuildContext context, {bool reverse = false}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (reverse) {
      return isArabic ? MainAxisAlignment.start : MainAxisAlignment.end;
    }
    return isArabic ? MainAxisAlignment.end : MainAxisAlignment.start;
  }

  /// Focus navigation - move to next field
  /// Automatically skips readonly/disabled fields (birthDateCtl, childIdCtl)
  /// by not assigning them FocusNodes - this ensures they are not included
  /// in the focus navigation chain
  void focusNextField(BuildContext context, FocusNode? nextFocus) {
    if (nextFocus != null) {
      FocusScope.of(context).requestFocus(nextFocus);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  /// Safe SnackBar display method that avoids accessibility errors
  void showSafeSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Silently handle if Scaffold is not available
      debugPrint('SnackBar error: $e');
    }
  }

  /// Calculate education level from birth date based on age
  /// Uses keys defined in RegistrationFormI18n
  String? calculateEducationLevelFromAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    // Adjust if birthday hasn't occurred this year
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    if (age < 0) {
      return RegistrationFormI18n.educationLevelNone;
    } else if (age < 6) {
      return RegistrationFormI18n.educationLevelNone;
    } else if (age < 13) {
      return RegistrationFormI18n.educationLevelPrimary;
    } else if (age < 15) {
      return RegistrationFormI18n.educationLevelMiddle;
    } else if (age < 18) {
      return RegistrationFormI18n.educationLevelSecondary;
    } else {
      return RegistrationFormI18n.educationLevelUniversity;
    }
  }

  /// Convert education level key to Arabic text for database storage
  String _convertEducationLevelToArabic(String? key) {
    return RegistrationFormI18n.getEducationLevelArabic(key);
  }

  /// Convert university year key to Arabic text for database storage
  String _convertUniversityYearToArabic(String? key) {
    return RegistrationFormI18n.getUniversityYearArabic(key);
  }

  /// Convert Arabic text from database to education level key for display
  String _convertEducationLevelFromArabic(String? arabicText) {
    return RegistrationFormI18n.getEducationLevelKey(arabicText);
  }

  /// Convert Arabic text from database to university year key
  String _convertUniversityYearFromArabic(String? arabicText) {
    return RegistrationFormI18n.getUniversityYearKey(arabicText);
  }

  /// Convert school class key to Arabic text for database storage
  String _convertSchoolClassToArabic(String? key) {
    return RegistrationFormI18n.getSchoolClassArabic(key);
  }

  /// Convert Arabic text from database to school class key
  String _convertSchoolClassFromArabic(String? arabicText) {
    return RegistrationFormI18n.getSchoolClassKey(arabicText);
  }

  List<Country> _cleanAndSortCountries(List<Country> inputList) {
    final Map<String, Country> unique = {};
    for (var c in inputList) {
      final key =
          c.nameAr.trim().isNotEmpty ? c.nameAr.trim() : c.nameEn.trim();
      if (key.isEmpty) continue;

      if (!unique.containsKey(key)) {
        unique[key] = c;
      } else {
        final existing = unique[key]!;
        final existingHasRealId = existing.id != null && existing.id! < 1000;
        final newHasRealId = c.id != null && c.id! < 1000;
        if (!existingHasRealId && newHasRealId) {
          unique[key] = c;
        }
      }
    }

    final list = unique.values.toList();

    // فرز الدول: فلسطين دائما وأبدا الأولى، ثم باقي الدول أبجدياً
    list.sort((a, b) {
      final isPalestineA =
          a.nameAr.contains('فلسطين') || a.nameEn.toLowerCase() == 'palestine';
      final isPalestineB =
          b.nameAr.contains('فلسطين') || b.nameEn.toLowerCase() == 'palestine';
      if (isPalestineA && !isPalestineB) return -1;
      if (!isPalestineA && isPalestineB) return 1;
      return a.nameAr.compareTo(b.nameAr);
    });

    return list;
  }

  Country? _findCountryByName(String value) {
    for (final country in countries) {
      if (country.matchesName(value)) return country;
    }
    return null;
  }

  /// Load countries from database with caching
  Future<void> loadCountries() async {
    // 1. Load from assets first if empty to show UI immediately
    if (countries.isEmpty) {
      await _loadCountriesFromAssets();
    }

    // 2. Start updating from source in background - don't await if we already have data
    if (countries.isNotEmpty) {
      unawaited(_updateCountriesFromSource());
    } else {
      await _updateCountriesFromSource();
    }

    // 3. Load remaining data in background
    unawaited(loadOrganizations());
    unawaited(loadSponsors());
    unawaited(loadPayments());
  }

  Future<void> _updateCountriesFromSource() async {
    try {
      final isWeb = kIsWeb;
      print(
        '🔄 جاري تحديث الدول من المصدر... (${isWeb ? "Web 🌐" : "Windows 🖥️"})',
      );

      List<Country> result = [];
      if (isWeb) {
        result = await FirebaseSyncService()
            .getAllCountriesFromFirebase()
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } else {
        result = await SqliteService().listCountries();
        if (result.isEmpty) {
          result = await FirebaseSyncService()
              .getAllCountriesFromFirebase()
              .timeout(const Duration(seconds: 5), onTimeout: () => []);
        }
      }

      if (result.isEmpty) {
        print('⚠️ No countries from DB/Firebase, loading from assets...');
        await _loadCountriesFromAssets();
        return;
      }

      if (result.isNotEmpty) {
        final processed = _cleanAndSortCountries(result);

        (this as dynamic).setState(() {
          countries = processed;
          // تعيين أول دولة كقيمة افتراضية إذا لم يكن هناك دولة محددة
          if (selectedCountry == null && countries.isNotEmpty) {
            selectedCountry = countries.first;
            countryCtl.text = selectedCountry!.nameAr;
            // تحميل المدن وتوليد رمز اليتيم للدولة الافتراضية
            loadCities(selectedCountry!.id!);
            generateNewChildId();
          }

          // TECHNICAL OPTIMIZATION: Prefetch everything in background
          // This makes country switching instant for BOTH cities and IDs
          _prefetchAllCountryData();
        });
      }
    } catch (e) {
      print('❌ خطأ في تحديث الدول من المصدر: $e');
      await _loadCountriesFromAssets();
    }
  }

  /// Fallback method to load countries from JSON assets
  Future<void> _loadCountriesFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/countries.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<Country> loadedCountries = [];

      for (int i = 0; i < jsonList.length; i++) {
        final Map<String, dynamic> item = Map.from(jsonList[i]);
        // Assign temporary ID if missing (starting from 1000 to avoid DB collisions)
        item['id'] = item['id'] ?? (i + 1000);
        loadedCountries.add(Country.fromJson(item));
      }

      if (loadedCountries.isNotEmpty) {
        final processed = _cleanAndSortCountries(loadedCountries);

        (this as dynamic).setState(() {
          countries = processed;
          // تعيين أول دولة كقيمة افتراضية إذا لم يكن هناك دولة محددة
          if (selectedCountry == null && countries.isNotEmpty) {
            selectedCountry = countries.first;
            countryCtl.text = selectedCountry!.nameAr;
            loadCities(selectedCountry!.id ?? 0);
            generateNewChildId();
          }

          // Prefetch everything in background
          _prefetchAllCountryData();
        });
        print('✅ تم تحميل ${loadedCountries.length} دولة من assets (fallback)');
      }
    } catch (e) {
      print('❌ Fallback failed to load countries from assets: $e');
    }
  }

  /// Prefetch Cities and IDs for all countries
  Future<void> _prefetchAllCountryData() async {
    print('🚀 البدء في التحميل المسبق لبيانات جميع الدول...');
    for (var country in countries) {
      if (country.nameAr.isEmpty) continue;

      // 1. Prefetch Child ID
      String codeToUse = country.code.trim();
      if (country.nameAr == 'فلسطين') codeToUse = '01';
      if (int.tryParse(codeToUse) != null && codeToUse.length < 2) {
        codeToUse = codeToUse.padLeft(2, '0');
      }

      try {
        SqliteService()
            .getNextCountryBasedChildId(country.nameAr, knownCode: codeToUse)
            .then((id) {
              _childIdCache[country.nameAr] = id;
            });

        // 2. Prefetch Cities
        if (!_citiesCache.containsKey(country.id)) {
          SqliteService().listCitiesByCountry(country.id!).then((cts) async {
            if (cts.isNotEmpty) {
              final seen = <String>{};
              final deduped =
                  cts
                      .where((c) => seen.add(c.nameAr))
                      .map((c) => c.toJson())
                      .toList();
              _citiesCache[country.id!] = deduped;
            } else {
              // Fallback to assets for pre-fetch
              final assetCities = await _fetchCitiesFromAssets(country.code);
              if (assetCities.isNotEmpty) {
                _citiesCache[country.id!] = assetCities;
              }
            }
          });
        }
      } catch (e) {
        print('⚠️ فشل التحميل المسبق لـ ${country.nameAr}: $e');
      }
    }
  }

  /// Helper to fetch cities from assets by country code
  Future<List<Map<String, dynamic>>> _fetchCitiesFromAssets(
    String countryCode,
  ) async {
    try {
      final jsonString = await rootBundle.loadString('assets/cities.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final List<dynamic>? citiesJson = jsonMap[countryCode] as List<dynamic>?;

      if (citiesJson != null) {
        return citiesJson.map((city) {
          return {
            'name_ar': city['name_ar'] ?? '',
            'name_en': city['name_en'] ?? '',
            'name_tr': city['name_tr'] ?? '',
            'country_id': 0, // Placeholder
          };
        }).toList();
      }
    } catch (e) {
      print('❌ Error fetching cities from assets for $countryCode: $e');
    }
    return [];
  }

  /// Optimized country change handler for instant UI updates
  void handleBirthCountryChange(Country? newValue) {
    if (newValue == null) return;

    (this as dynamic).setState(() {
      selectedBirthCountry = newValue;
      birthCountryCtl.text = newValue.nameAr;
      selectedBirthCity = null;
      birthCityCtl.text = '';

      if (_citiesCache.containsKey(newValue.id)) {
        birthCities = _citiesCache[newValue.id]!;
      }
    });

    if (newValue.id != null && !_citiesCache.containsKey(newValue.id)) {
      _loadBirthCities(newValue.id!);
    }
  }

  Future<void> _loadBirthCities(int countryId) async {
    if (_citiesCache.containsKey(countryId)) {
      final cachedCities = _citiesCache[countryId]!;
      if ((this as dynamic).mounted) {
        (this as dynamic).setState(() {
          birthCities = cachedCities;
        });
      }
      return;
    }

    try {
      final isWeb = kIsWeb;
      List<City> list = [];
      if (isWeb) {
        list = await FirebaseSyncService()
            .getCitiesByCountryFromFirebase(countryId)
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } else {
        list = await SqliteService().listCitiesByCountry(countryId);
        if (list.isEmpty) {
          list = await FirebaseSyncService()
              .getCitiesByCountryFromFirebase(countryId)
              .timeout(const Duration(seconds: 5), onTimeout: () => []);
        }
      }

      final uniqueCities = <String>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (var c in list) {
        if (uniqueCities.add(c.nameAr)) {
          uniqueList.add(c.toJson());
        }
      }
      _citiesCache[countryId] = uniqueList;
      if ((this as dynamic).mounted) {
        (this as dynamic).setState(() {
          birthCities = uniqueList;
        });
      }
    } catch (e) {
      print('Error loading birth cities: ');
    }
  }

  Future<void> showAddBirthCityDialog() async {
    final context = (this as dynamic).context;
    if (selectedBirthCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RegistrationFormI18n.errSelectCountryFirst)),
      );
      return;
    }

    final nameArCtl = TextEditingController();
    final nameEnCtl = TextEditingController();
    final nameTrCtl = TextEditingController();

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => Directionality(
              textDirection: getTextDirection(context),
              child: AlertDialog(
                title: Row(
                  textDirection: getTextDirection(context),
                  mainAxisAlignment: getAlignment(context),
                  children: [
                    Icon(Icons.location_city, color: Colors.green),
                    SizedBox(width: 8),
                    Text(RegistrationFormI18n.dialogAddCity),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameArCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'cityNameAr',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameEnCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'cityNameEn',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameTrCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'cityNameTr',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(RegistrationFormI18n.btnCancel),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameArCtl.text.trim().isEmpty) return;

                      final db = SqliteService();
                      final newCity = City(
                        countryId: selectedBirthCountry!.id ?? 0,
                        nameAr: nameArCtl.text.trim(),
                        nameEn:
                            nameEnCtl.text.trim().isEmpty
                                ? MultiLangTransliterator.toEnglish(
                                  nameArCtl.text.trim(),
                                )
                                : nameEnCtl.text.trim(),
                        nameTr:
                            nameTrCtl.text.trim().isEmpty
                                ? MultiLangTransliterator.toTurkish(
                                  nameArCtl.text.trim(),
                                )
                                : nameTrCtl.text.trim(),
                      );

                      await db.insertCity(newCity);
                      if (selectedBirthCountry!.id != null)
                        _citiesCache.remove(selectedBirthCountry!.id!);
                      if (selectedBirthCountry!.id != null)
                        await _loadBirthCities(selectedBirthCountry!.id!);

                      (this as dynamic).setState(() {
                        selectedBirthCity = newCity.nameAr;
                        birthCityCtl.text = newCity.nameAr;
                      });

                      Navigator.pop(context);
                    },
                    child: Text(RegistrationFormI18n.btnSave),
                  ),
                ],
              ),
            ),
      );
    }
  }

  void handleCountryChange(Country? newValue) {
    if (newValue == null) return;

    print('🌍 [FastSync] Switching to: ${newValue.nameAr}');

    // 1. Synchronous UI Update (Instant Response)
    (this as dynamic).setState(() {
      selectedCountry = newValue;
      countryCtl.text = newValue.nameAr;
      // Reset city
      selectedCity = null;
      cityCtl.text = '';

      // TECHNICAL OPTIMIZATION 1: Atomic ID Switch from Cache
      if (_childIdCache.containsKey(newValue.nameAr)) {
        final cachedId = _childIdCache[newValue.nameAr]!;
        print('⚡ ID Cache Hit: $cachedId');
        childIdCtl.text = cachedId;
      }

      // TECHNICAL OPTIMIZATION 2: Atomic Cities Switch from Cache
      if (newValue.id != null && _citiesCache.containsKey(newValue.id)) {
        print('🏙️ Cities Cache Hit for ${newValue.nameAr}');
        cities = _citiesCache[newValue.id]!;
      } else {
        cities = [];
      }
    });

    // 2. Asynchronous Operations (Background/Loading)
    // Perform these AFTER setState to avoid nesting and blocking

    // Process Child ID verification or generation
    if (_childIdCache.containsKey(newValue.nameAr)) {
      _backgroundVerifyId(newValue);
    } else {
      generateNewChildId();
    }

    // Load cities if not cached
    if (newValue.id == null || !_citiesCache.containsKey(newValue.id)) {
      loadCities(newValue.id ?? 0);
    }
  }

  /// Silently verify ID in background without blocking UI
  void _backgroundVerifyId(Country country) {
    String codeToUse = country.code.trim();
    if (country.nameAr == 'فلسطين') codeToUse = '01';
    if (int.tryParse(codeToUse) != null && codeToUse.length < 2) {
      codeToUse = codeToUse.padLeft(2, '0');
    }

    SqliteService()
        .getNextCountryBasedChildId(country.nameAr, knownCode: codeToUse)
        .then((freshId) {
          if (freshId != _childIdCache[country.nameAr]) {
            _childIdCache[country.nameAr] = freshId;
            // Only update UI if we are still on this country
            if (selectedCountry?.id == country.id) {
              (this as dynamic).setState(() {
                childIdCtl.text = freshId;
              });
            }
          }
        })
        .catchError((e) {
          print('⚠️ Background ID verify failed: $e');
          return null;
        });
  }

  /// Load cities for selected country
  Future<void> loadCities(int countryId) async {
    // 1. Check Cache first
    if (_citiesCache.containsKey(countryId)) {
      print('🚀 تحميل المدن من الذاكرة (Cache) للدولة $countryId');
      final cachedCities = _citiesCache[countryId]!;
      if ((this as dynamic).mounted) {
        (this as dynamic).setState(() {
          cities = cachedCities;
        });
      }
      return;
    }

    // 2. Prepare for loading
    if ((this as dynamic).mounted) {
      (this as dynamic).setState(() {
        cities = [];
      });
    }

    try {
      final isWeb = kIsWeb;
      print(
        '🔄 جاري جلب المدن من المصدر... (${isWeb ? "Web 🌐" : "Windows 🖥️"})',
      );

      List<City> list = [];
      if (isWeb) {
        list = await FirebaseSyncService()
            .getCitiesByCountryFromFirebase(countryId)
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } else {
        // Try local DB first
        list = await SqliteService().listCitiesByCountry(countryId);
        if (list.isEmpty) {
          // Fallback to Firebase
          list = await FirebaseSyncService()
              .getCitiesByCountryFromFirebase(countryId)
              .timeout(const Duration(seconds: 5), onTimeout: () => []);
        }
      }

      if (list.isNotEmpty) {
        final uniqueCities = <String>{};
        final uniqueList = <Map<String, dynamic>>[];
        for (var c in list) {
          if (uniqueCities.add(c.nameAr)) {
            uniqueList.add(c.toJson());
          }
        }

        // Save to Cache
        _citiesCache[countryId] = uniqueList;

        if ((this as dynamic).mounted) {
          (this as dynamic).setState(() {
            cities = uniqueList;
            print('✅ تم تحميل وتخزين ${cities.length} مدينة في الذاكرة');
          });
        }
      } else {
        print('⚠️ لا توجد مدن - جاري المحاولة من assets...');
        await _loadCitiesFromAssets(countryId);
        // Cache assets result too? Yes, usually safe.
        if (cities.isNotEmpty) {
          _citiesCache[countryId] = List.from(cities);
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل المدن: $e');
      await _loadCitiesFromAssets(countryId);
    }
  }

  /// Fallback method to load cities from JSON assets
  Future<void> _loadCitiesFromAssets(int countryId) async {
    String? countryCode;
    if (selectedCountry != null && selectedCountry!.id == countryId) {
      countryCode = selectedCountry!.code;
    } else {
      final country = countries.firstWhere(
        (c) => c.id == countryId,
        orElse:
            () => Country(
              id: -1,
              nameAr: '',
              nameEn: '',
              nameTr: '',
              code: '',
              updatedAt: DateTime.now(),
            ),
      );
      if (country.id != -1) {
        countryCode = country.code;
      }
    }

    if (countryCode == null || countryCode.isEmpty) {
      print('⚠️ Country code not found for ID $countryId');
      return;
    }

    final assetCities = await _fetchCitiesFromAssets(countryCode);
    if (assetCities.isNotEmpty) {
      (this as dynamic).setState(() {
        cities = assetCities;
      });
      print('✅ تم تحميل ${cities.length} مدينة من assets (fallback)');
    } else {
      print('⚠️ لا توجد مدن لـ $countryCode في assets');
      (this as dynamic).setState(() {
        cities = [];
      });
    }
  }

  /// Load supporting organizations
  Future<void> loadOrganizations() async {
    try {
      if (kIsWeb) {
        organizations = await FirebaseSyncService()
            .getAllOrganizationsFromFirebase()
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } else {
        final List<Organization> result =
            await SqliteService().listSupportingOrganizations();
        organizations =
            result.map((o) => o.toJson()).cast<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      print('Error loading organizations: $e');
    }
  }

  /// Load sponsors from database - only shows sponsors that exist in the database
  Future<void> loadSponsors() async {
    try {
      List<Sponsor> result;
      if (kIsWeb) {
        result = await FirebaseSyncService()
            .getAllSponsorsFromFirebase()
            .timeout(const Duration(seconds: 5), onTimeout: () => []);
      } else {
        result = await SqliteService().listSponsors();
      }

      masterSponsors = result;
    } catch (e) {
      print('Error loading sponsors: $e');
      masterSponsors = [];
    }
  }

  /// Load existing child data into form
  Future<void> loadExistingChildData() async {
    var child = (this as dynamic).widget.child;
    if (child == null) return;

    final isWeb = kIsWeb;
    print(
      '🔄 جاري تحديث بيانات اليتيم من المصدر... (${isWeb ? "Web 🌐" : "Windows 🖥️"})',
    );

    Child? freshChild;
    try {
      if (isWeb) {
        freshChild = await FirebaseSyncService().getChildFromFirebase(child.id);
      } else {
        freshChild = await SqliteService().getChildById(child.id);
        if (freshChild == null) {
          freshChild = await FirebaseSyncService().getChildFromFirebase(
            child.id,
          );
        }
      }
    } catch (e) {
      print('⚠️ Error fetching fresh child data: $e');
    }

    if (freshChild != null) {
      child = freshChild;
    }

    // Use the comprehensive population method
    await _populateFormFromChild(child);

    // Load payments separately as they are not part of the child object usually or might be outdated
    try {
      List<Payment> dbPayments;
      if (isWeb) {
        dbPayments = await FirebaseSyncService().getPaymentsFromFirebase(
          child.id,
        );
      } else {
        dbPayments = await SqliteService().listPayments(childId: child.id);
      }

      dbPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      (this as dynamic).setState(() {
        payments = dbPayments;
      });
      print('✅ تم تحميل ${dbPayments.length} مدفوعة');
    } catch (e) {
      print('❌ Error loading child payments: $e');
    }
  }

  /// Generate new child ID based on selected country
  Future<void> generateNewChildId() async {
    print('🔍 generateNewChildId() called');

    // Logic:
    // 1. If widget.child is null (New Registration) -> Always Generate
    // 2. If widget.child is not null (Editing) ->
    //    a. If country is same as original AND we already have an ID -> Keep old ID
    //    b. If country is different OR no ID yet -> Generate new ID

    final isEditing = (this as dynamic).widget.child != null;
    final originalCountry = (this as dynamic).widget.child?.country;
    final currentCountry = selectedCountry?.nameAr;
    final hasExistingId = childIdCtl.text.isNotEmpty;

    print('📊 isEditing: $isEditing');
    print('📊 originalCountry: $originalCountry');
    print('📊 currentCountry: $currentCountry');
    print('📊 hasExistingId: $hasExistingId (ID: ${childIdCtl.text})');

    // Only skip generation if:
    // - We are editing (not new)
    // - Country hasn't changed
    // - We already have a valid ID
    if (isEditing && originalCountry == currentCountry && hasExistingId) {
      // Same country and has ID, keep original ID
      print('📌 Keeping existing ID: ${childIdCtl.text}');
      return;
    }

    print('🔄 Proceeding to generate new ID...');

    if (selectedCountry != null) {
      // Use the actual code from the database/country object
      // This ensures consistency with what the user sees in the dropdown (e.g. Lebanon (03))
      String codeToUse = selectedCountry!.code.trim();

      // Special override for Palestine to ensure it always uses '01'
      // This addresses cases where the source (assets/DB/Firebase) might have 'PS' or other variations
      if (selectedCountry!.nameAr == 'فلسطين') {
        codeToUse = '01';
      }

      // Ensure code is at least 2 digits (e.g. "1" -> "01", "3" -> "03")
      // Only pad if it is numeric
      if (int.tryParse(codeToUse) != null && codeToUse.length < 2) {
        codeToUse = codeToUse.padLeft(2, '0');
      }

      print('🔧 Using country code: $codeToUse for ${selectedCountry!.nameAr}');

      // TECHNICAL OPTIMIZATION: Check cache first for instant UI response
      if (_childIdCache.containsKey(selectedCountry!.nameAr)) {
        final cachedId = _childIdCache[selectedCountry!.nameAr]!;
        print('⚡ Setting ID instantly from cache: $cachedId');
        (this as dynamic).setState(() {
          childIdCtl.text = cachedId;
        });

        // Still update in background to ensure total accuracy if data changed
        unawaited(
          SqliteService()
              .getNextCountryBasedChildId(
                selectedCountry!.nameAr,
                knownCode: codeToUse,
              )
              .then((freshId) {
                if (freshId != cachedId) {
                  _childIdCache[selectedCountry!.nameAr] = freshId;
                  (this as dynamic).setState(() {
                    childIdCtl.text = freshId;
                  });
                  print('🔄 Updated ID from background fetch: $freshId');
                }
              }),
        );
        return;
      }

      try {
        final id = await SqliteService().getNextCountryBasedChildId(
          selectedCountry!.nameAr,
          knownCode: codeToUse,
        );

        // Update cache
        _childIdCache[selectedCountry!.nameAr] = id;

        (this as dynamic).setState(() {
          childIdCtl.text = id;
        });
        print('✅ Generated new child ID: $id');
      } catch (e) {
        print('❌ Error generating child ID: $e');
      }
    } else {
      print('⚠️ selectedCountry is null, cannot generate ID');
    }
  }

  /// Rename/Move images in storage when ID changes
  Future<void> _moveImagesToNewIdFolder(
    String oldIdNum,
    String newIdNum,
  ) async {
    // This is a comprehensive operation.
    // 1. List all files in 'children/$oldIdNum/'
    // 2. Move them to 'children/$newIdNum/'
    // 3. Delete old folder (if empty)

    if (kIsWeb) {
      // On Web (GitHub), we can't easily "move" a folder.
      // We have to download and re-upload, or just update paths if strictly using URLs.
      // Since our storage is 'children/$id/filename', we must move them physically
      // if we want to maintain the structure.
      // For now, simpler approach: Just update the database paths.
      // But wait, the paths contain the ID! '.../children/OLD_ID/image.jpg'
      // So the links will still work as long as we don't delete the old folder.
      // BUT, for organization, we SHOULD move them.

      // Given the complexity of GitHub API move (get sha, get content, upload new, delete old),
      // performing this for potentially 10+ images during a form save might be too slow/risky.
      // STRATEGY:
      // For now, we will NOT move the physical files on Web to avoid data loss risk.
      // We will update the references in the database.
      // Future improvement: Background job to organize folders.
      print(
        '⚠️ [Web] Rename ID: Physical file move on GitHub skipped for safety. References will be valid.',
      );
    } else {
      // Windows: Rename directory
      try {
        final dataPath = await SettingsService.getEffectiveDataPath();
        final oldDir = Directory(p.join(dataPath, 'children', oldIdNum));
        final newDir = Directory(p.join(dataPath, 'children', newIdNum));

        if (await oldDir.exists()) {
          if (await newDir.exists()) {
            // Merge? Or Copy contents?
            // Just move files
            await for (var entity in oldDir.list()) {
              if (entity is File) {
                final newPath = p.join(newDir.path, p.basename(entity.path));
                await entity.rename(newPath);
              }
            }
            await oldDir.delete(); // Delete if empty
          } else {
            await oldDir.rename(newDir.path);
          }
          print('✅ [Windows] Renamed folder $oldIdNum to $newIdNum');
        }
      } catch (e) {
        print('❌ [Windows] Error renaming folder: $e');
      }
    }
  }

  /// Load child from database by ID
  Future<Child?> loadChildFromDatabase(String childId) async {
    try {
      final isWeb = kIsWeb;
      print(
        '🔄 جاري جلب بيانات اليتيم... (${isWeb ? "Web 🌐" : "Windows 🖥️"})',
      );

      Child? child;

      if (isWeb) {
        // الويب: Firebase فقط
        print('☁️ [Web] جاري الجلب من Firebase...');
        child = await FirebaseSyncService().getChildFromFirebase(childId);

        if (child != null) {
          print('✅ تم جلب من Firebase');
          await _populateFormFromChild(child);
          return child;
        }
      } else {
        // Windows: SQLite أولاً
        print('💾 جاري الجلب من SQLite...');
        child = await SqliteService().getChildById(childId);
        if (child != null) {
          print('✅ تم جلب من SQLite');
          await _populateFormFromChild(child);
          return child;
        }

        // Fallback: Firebase
        print('⚠️ SQLite فارغة - جاري البحث في Firebase...');
        child = await FirebaseSyncService().getChildFromFirebase(childId);
        if (child != null) {
          print('✅ تم جلب من Firebase');
          await _populateFormFromChild(child);
          return child;
        }
      }

      print('❌ لم يتم العثور على البيانات');
      return null;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  /// Populate form fields from child object
  Future<void> _populateFormFromChild(Child child) async {
    // Get current language code
    final currentContext = (this as dynamic).context;
    final languageCode = Localizations.localeOf(currentContext).languageCode;
    // Convert names based on current language
    String convertedFirstName = child.firstName;
    String convertedLastName = child.lastName;
    String convertedFatherName = child.fatherName;
    String convertedMotherName = child.motherName;
    if (languageCode == 'en') {
      convertedFirstName = MultiLangTransliterator.toEnglish(child.firstName);
      convertedLastName = MultiLangTransliterator.toEnglish(child.lastName);
      convertedFatherName = MultiLangTransliterator.toEnglish(child.fatherName);
      convertedMotherName = MultiLangTransliterator.toEnglish(child.motherName);
    } else if (languageCode == 'tr') {
      convertedFirstName = MultiLangTransliterator.toTurkish(child.firstName);
      convertedLastName = MultiLangTransliterator.toTurkish(child.lastName);
      convertedFatherName = MultiLangTransliterator.toTurkish(child.fatherName);
      convertedMotherName = MultiLangTransliterator.toTurkish(child.motherName);
    }

    // ✅ تحديث الـ UI باستخدام setState مع جميع القيم
    (this as dynamic).setState(() {
      // Basic Info
      firstNameCtl.text = convertedFirstName;
      fatherNameCtl.text = child.fatherName;
      grandfatherNameCtl.text = child.grandfatherName ?? '';
      familyNameCtl.text = child.lastName;
      lastNameCtl.text = child.lastName;
      fatherFullNameCtl.text = child.fatherTripleName;

      birthCountryCtl.text = child.birthCountry ?? '';
      birthCityCtl.text = child.birthCity ?? '';
      childIdCtl.text = child.childIdNumber;
      nationalIdCtl.text = child.nationalId ?? '';
      addressCtl.text = child.street ?? '';
      streetCtl.text = child.street ?? '';
      phoneCtl.text = child.guardianPhone ?? '';

      // Gender and dates
      gender = child.gender ?? 'M';
      dateOfBirth = child.dateOfBirth;
      healthStatus = child.healthStatus;

      if (dateOfBirth != null) {
        birthDateCtl.text = dateOfBirth!.toIso8601String().split('T')[0];
        ageCtl.text = (DateTime.now().year - dateOfBirth!.year).toString();
      } else {
        birthDateCtl.text = '';
        ageCtl.text = '';
      }

      // Parents Info
      fatherFullNameCtl.text =
          child.fatherTripleName.isNotEmpty
              ? child.fatherTripleName
              : convertedFatherName;
      fatherIdCtl.text = child.fatherIdNumber;
      fatherStatus = child.fatherStatus;
      fatherDeathCause = child.fatherDeathCause;
      fatherDeathDateCtl.text =
          child.fatherDeathDate != null
              ? child.fatherDeathDate!.toIso8601String().split('T')[0]
              : '';

      motherFullNameCtl.text = convertedMotherName;
      motherIdCtl.text = child.motherIdNumber;
      motherStatus = child.motherStatus;
      motherDeathCause = child.motherDeathCause;
      motherDeathDateCtl.text =
          child.motherDeathDate != null
              ? child.motherDeathDate!.toIso8601String().split('T')[0]
              : '';

      // Guardian Info
      guardianRelationship = child.guardianRelationship ?? 'Uncle';
      guardianNameCtl.text = child.guardianName ?? '';
      guardianPhoneCtl.text = child.guardianPhone ?? '';
      guardianAddressCtl.text = child.guardianAddress ?? child.street ?? '';

      // تعيين اسم الولي بناءً على علاقة الولي
      if (guardianRelationship == 'Mother' || guardianRelationship == 'الأم') {
        guardianNameCtl.text = convertedMotherName;
      } else if (guardianRelationship == 'Father' ||
          guardianRelationship == 'الأب') {
        guardianNameCtl.text = convertedFatherName;
      } else {
        // إذا كان الولي شخص آخر، نترك الحقل فارغاً أو نستخدم أي معلومات متوفرة
        if (guardianNameCtl.text.isEmpty) {
          guardianNameCtl.text = '';
        }
      }

      // Education Info
      schoolLevelCtl.text = child.educationLevel ?? '';
      educationLevel = _convertEducationLevelFromArabic(child.educationLevel);
      final convertedClass = _convertSchoolClassFromArabic(child.grade);
      schoolClass = (convertedClass.isNotEmpty) ? convertedClass : null;
      schoolNameCtl.text = child.schoolName ?? '';
      universityNameCtl.text =
          child.universityName ??
          (educationLevel == 'education_level_university'
              ? child.universityCollegeName ?? ''
              : '');
      universityCollegeCtl.text =
          educationLevel == 'education_level_university' &&
                  child.universityName == null
              ? ''
              : child.universityCollegeName ?? '';
      collegeSpecializationCtl.text = child.collegeSpecialization ?? '';
      universityYear = _convertUniversityYearFromArabic(child.universityYear);
      universityYearCtl.text = child.universityYear ?? '';

      // Financial Details
      paymentMethod = (child.paymentMethod == 'wallet') ? 'wallet' : 'bank';
      bankNameCtl.text = child.bankName ?? '';
      bankAccountNumberCtl.text = child.bankAccountNumber ?? '';
      bankIbanCtl.text = child.bankIban ?? '';
      bankAccountHolderNameCtl.text = child.bankAccountHolderName ?? '';
      walletNumberCtl.text = child.walletNumber ?? '';
      walletHolderNameCtl.text = child.walletHolderName ?? '';

      // Health Info
      disabilityType = child.disabilityType;
      disabilityCtl.text = child.specialNeeds ?? '';

      // Siblings
      siblingsList = List<Map<String, dynamic>>.from(child.siblings);

      print('✅ تم تعيين البيانات الأساسية في setState');
    });
    // Trigger transliteration update
    _updateFatherAndTransliterations();

    // Birth Place: Country & City
    if (child.birthCountry != null && child.birthCountry!.isNotEmpty) {
      final foundBirthCountry = _findCountryByName(child.birthCountry!);

      if (foundBirthCountry != null) {
        (this as dynamic).setState(() {
          selectedBirthCountry = foundBirthCountry;
          birthCountryCtl.text = foundBirthCountry.nameAr;
        });
        if (foundBirthCountry.id != null) {
          await _loadBirthCities(foundBirthCountry.id!);
        }
      } else {
        (this as dynamic).setState(() {
          birthCountryCtl.text = child.birthCountry ?? '';
        });
      }
    }

    if (selectedBirthCountry != null &&
        child.birthCity != null &&
        child.birthCity!.isNotEmpty) {
      String? foundCityName;
      try {
        final foundCity = birthCities.firstWhere(
          (c) => (c['name_ar'] ?? '') == child.birthCity,
        );
        foundCityName = foundCity['name_ar'];
      } catch (_) {
        try {
          final foundCity = birthCities.firstWhere(
            (c) =>
                (c['name_en'] ?? '') == child.birthCity ||
                (c['name_tr'] ?? '') == child.birthCity,
          );
          foundCityName = foundCity['name_ar'];
        } catch (_) {
          foundCityName = child.birthCity;
        }
      }

      (this as dynamic).setState(() {
        selectedBirthCity = foundCityName;
        birthCityCtl.text = foundCityName ?? '';
      });
    }

    // Country: Always store Arabic, but display current language
    if (child.country != null && child.country!.isNotEmpty) {
      final foundCountry = _findCountryByName(child.country!);

      if (foundCountry != null) {
        (this as dynamic).setState(() {
          selectedCountry = foundCountry;
          countryCtl.text = foundCountry.nameAr;
        });
        print('✅ تم تحديد البلد: ${foundCountry.nameAr}');
      } else {
        (this as dynamic).setState(() {
          countryCtl.text = child.country ?? '';
        });
        print('⚠️ لم يتم العثور على البلد "${child.country}" في القائمة');
      }
    }

    // City: Always store Arabic, but display current language
    if (selectedCountry != null &&
        child.city != null &&
        child.city!.isNotEmpty) {
      if (selectedCountry!.id != null) {
        await loadCities(selectedCountry!.id!);
      } else {
        print('⚠️ Country ID is null, skipping city load by ID');
      }

      String? foundCityName;
      try {
        final foundCity = cities.firstWhere(
          (c) => (c['name_ar'] ?? '') == child.city,
        );
        foundCityName = foundCity['name_ar'];
      } catch (_) {
        // Try other languages
        try {
          final foundCity = cities.firstWhere(
            (c) =>
                (c['name_en'] ?? '') == child.city ||
                (c['name_tr'] ?? '') == child.city,
          );
          foundCityName = foundCity['name_ar'];
        } catch (_) {
          foundCityName = child.city;
        }
      }

      (this as dynamic).setState(() {
        selectedCity = foundCityName;
        cityCtl.text = foundCityName ?? '';
      });
      print('✅ تم تحديد المدينة: $foundCityName');
    }

    // Split documents
    final allDocs = List<Document>.from(child.documents);

    // Synthesis: Ensure primary photos are in the documents list if they exist in the child object
    void ensureInList(String? path, String? fileName, String type) {
      if (path != null && path.isNotEmpty) {
        if (!allDocs.any((d) => d.type == type)) {
          allDocs.add(
            Document(
              id: 'legacy_${type}_${DateTime.now().millisecondsSinceEpoch}',
              fileName: fileName ?? p.basename(path),
              filePath: path,
              type: type,
            ),
          );
        }
      }
    }

    ensureInList(child.childPhotoPath, child.childPhotoFileName, 'Profile');
    ensureInList(
      child.motherIdPhotoPath,
      child.motherIdPhotoFileName,
      'MotherID',
    );
    ensureInList(
      child.guardianIdPhotoPath,
      child.guardianIdPhotoFileName,
      'Guardian',
    );
    ensureInList(
      child.fatherDeathCertificatePath,
      child.fatherDeathCertificateFileName,
      'FatherDeathCertificate',
    );
    ensureInList(
      child.motherDeathCertificatePath,
      child.motherDeathCertificateFileName,
      'MotherDeathCertificate',
    );

    (this as dynamic).setState(() {
      const certificateTypes = {
        'EducationCertificate',
        'BirthCertificate',
        'Certificate',
        'FatherDeathCertificate',
        'MotherDeathCertificate',
      };
      const medicalTypes = {'MedicalReport', 'HealthReport', 'Medical'};
      certificates =
          allDocs.where((d) => certificateTypes.contains(d.type)).toList();
      medicalReports =
          allDocs.where((d) => medicalTypes.contains(d.type)).toList();
      documents =
          allDocs
              .where(
                (d) =>
                    !certificateTypes.contains(d.type) &&
                    !medicalTypes.contains(d.type),
              )
              .toList();
    });
    print(
      '✅ تم تحميل ${documents.length} وثيقة، ${certificates.length} شهادة، ${medicalReports.length} تقرير طبي',
    );

    // Sponsor info
    if (child.sponsor != null) {
      (this as dynamic).setState(() {
        sponsorNameCtl.text = child.sponsor!.name;
        sponsorAmountCtl.text = child.sponsor!.amount.toString();
        sponsorStartDateCtl.text =
            child.sponsor!.startDate.toIso8601String().split('T')[0];
        sponsors = [child.sponsor!];
      });
      print('✅ تم تحميل بيانات الكفيل: ${child.sponsor!.name}');
    }

    print('✅ اكتمل _populateFormFromChild');
  }

  /// Show dialog to add new country
  Future<void> showAddCountryDialog() async {
    final context = (this as dynamic).context;
    final nameArCtl = TextEditingController();
    final nameEnCtl = TextEditingController();
    final nameTrCtl = TextEditingController();
    final codeCtl = TextEditingController();

    final nextCode = await _getNextCountryCode();
    codeCtl.text = nextCode;

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => Directionality(
              textDirection: getTextDirection(context),
              child: AlertDialog(
                title: Row(
                  textDirection: getTextDirection(context),
                  mainAxisAlignment: getAlignment(context),
                  children: [
                    Icon(Icons.public, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(RegistrationFormI18n.dialogAddCountry),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'countryCode',
                          ),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        readOnly: true,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameArCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'arabicName',
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.language),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameEnCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'englishName',
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.translate),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameTrCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'turkishName',
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(RegistrationFormI18n.btnCancel),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (nameArCtl.text.trim().isEmpty ||
                          nameEnCtl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(RegistrationFormI18n.errFillRequired),
                          ),
                        );
                        return;
                      }

                      try {
                        final newCountry = Country(
                          id: null,
                          code: codeCtl.text,
                          nameAr: nameArCtl.text.trim(),
                          nameEn: nameEnCtl.text.trim(),
                          nameTr: nameTrCtl.text.trim(),
                        );
                        await SqliteService().insertCountry(newCountry);
                        // Sync changes
                        await FirebaseSyncService().integrateAllData();
                        await loadCountries();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.successCountryAdded,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.formatErrorMessage(
                                'saveFailed',
                                value: e.toString(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text(RegistrationFormI18n.btnAdd),
                  ),
                ],
              ),
            ),
      );
    }
  }

  /// Show dialog to edit country code
  Future<void> showEditCountryDialog(Country country) async {
    final context = (this as dynamic).context;
    final codeCtl = TextEditingController(text: country.code);

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => Directionality(
              textDirection: getTextDirection(context),
              child: AlertDialog(
                title: Row(
                  textDirection: getTextDirection(context),
                  mainAxisAlignment: getAlignment(context),
                  children: [
                    Icon(Icons.edit, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(RegistrationFormI18n.dialogEditCountry),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الدولة: ${country.nameAr}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: codeCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.labelCountryCode,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                          helperText: RegistrationFormI18n.helperCountryCode,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'سيتم تحديث كود الدولة وتعديل جميع رموز الأيتام المرتبطين بها تلقائياً (مثلاً IHSAN03... سيصبح IHSAN02...).',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ملاحظة: لتبديل الأكواد بين دولتين (مثلاً سوريا ولبنان)، استخدم كوداً مؤقتاً (مثلاً 99) لتجنب تكرار الكود.',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(RegistrationFormI18n.btnCancel),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final newCode = codeCtl.text.trim();

                      if (newCode.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.errCountryCodeRequired,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newCode.length != 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.errCountryCodeTwoDigits,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        await SqliteService().updateCountryCode(
                          country.id!,
                          country.code,
                          newCode,
                          country.nameAr,
                        );

                        await loadCountries();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.successCountryCodeUpdated,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.formatErrorMessage(
                                'updateFailed',
                                value: e.toString(),
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.save),
                    label: Text(RegistrationFormI18n.btnSave),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
      );
    }
  }

  /// Show dialog to add new city
  Future<void> showAddCityDialog() async {
    final context = (this as dynamic).context;
    if (selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(RegistrationFormI18n.errSelectCountryFirst)),
      );
      return;
    }

    final nameArCtl = TextEditingController();
    final nameEnCtl = TextEditingController();
    final nameTrCtl = TextEditingController();

    if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => Directionality(
              textDirection: getTextDirection(context),
              child: AlertDialog(
                title: Row(
                  textDirection: getTextDirection(context),
                  mainAxisAlignment: getAlignment(context),
                  children: [
                    Icon(Icons.location_city, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(RegistrationFormI18n.dialogAddCity),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameArCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'arabicName',
                          ),
                          border: OutlineInputBorder(),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameEnCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'englishName',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameTrCtl,
                        decoration: InputDecoration(
                          labelText: RegistrationFormI18n.getFieldLabel(
                            'turkishName',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(RegistrationFormI18n.btnCancel),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (nameArCtl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(RegistrationFormI18n.errFillRequired),
                          ),
                        );
                        return;
                      }

                      try {
                        await SqliteService().insertCity(
                          City(
                            id: null,
                            countryId: selectedCountry!.id!,
                            nameAr: nameArCtl.text.trim(),
                            nameEn: nameEnCtl.text.trim(),
                            nameTr: nameTrCtl.text.trim(),
                          ),
                        );
                        await loadCities(selectedCountry!.id!);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.successCityAdded,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              RegistrationFormI18n.formatErrorMessage(
                                'saveFailed',
                                value: e.toString(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text(RegistrationFormI18n.btnAdd),
                  ),
                ],
              ),
            ),
      );
    }
  }

  /// Generate image filename following convention: CHILD{no of profile}-{Type}
  String _generateImageFileName(String imageType, String fileExtension) {
    String childId = childIdCtl.text.trim();

    // If child ID is empty, use a temporary ID
    if (childId.isEmpty) {
      childId = 'TEMP';
    }

    // Remove 'ihsan-' prefix if present
    if (childId.startsWith('ihsan-')) {
      childId = childId.substring(6);
    }

    if (imageType == 'Profile') {
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}-'
          '${now.millisecond.toString().padLeft(3, '0')}';
      return 'CHILD$childId-Photo-$timestamp$fileExtension';
    }
    if (imageType == 'MotherID') return 'CHILD$childId-MotherID$fileExtension';
    if (imageType == 'FatherID') return 'CHILD$childId-FatherID$fileExtension';
    if (imageType == 'BirthCertificate') {
      return 'CHILD$childId-BirthCertificate$fileExtension';
    }
    if (imageType == 'Guardian' || imageType == 'Guardain') {
      return 'CHILD$childId-Guardian$fileExtension';
    }
    if (imageType == 'Medical') return 'CHILD$childId-Medical$fileExtension';

    if (imageType == 'File' || imageType == 'Certificate') {
      // Find how many "File" or "Certificate" documents already exist for this child to get the next number
      int fileCount =
          documents
              .where((d) => d.type == 'File' || d.type == 'Certificate')
              .length +
          certificates
              .where((d) => d.type == 'File' || d.type == 'Certificate')
              .length +
          1;
      return 'CHILD$childId-${imageType == 'Certificate' ? 'Cert' : 'File'}$fileCount$fileExtension';
    }

    // Fallback for other types (medical, etc.)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CHILD${childId}_${imageType}_$timestamp$fileExtension';
  }

  String _attachmentStorageFolder(String type) {
    if (type == 'Profile') return 'family/personal_photos';
    if (type == 'BirthCertificate') return 'family/birth_certificates';
    if (type == 'MotherID') return 'family/mother_id';
    if (type == 'FatherDeathCertificate') {
      return 'family/father_death_certificate';
    }
    if (type == 'Guardian' ||
        type == 'Guardain' ||
        type == 'GuardianshipDeed') {
      return type == 'GuardianshipDeed'
          ? 'family/guardianship_deed'
          : 'family/guardian_id';
    }
    if (type == 'EducationCertificate' || type == 'Certificate') {
      return 'education/certificates';
    }
    if (type == 'MedicalReport' ||
        type == 'HealthReport' ||
        type == 'Medical') {
      return 'medical/reports';
    }
    return 'other';
  }

  String _attachmentStorageChildId() {
    final childId = childIdCtl.text.trim();
    return childId.isEmpty
        ? 'TEMP'
        : childId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  Future<String?> resolveAttachmentImagePath(Document document) async {
    final filePath = document.filePath.trim();
    if (filePath.startsWith('http') || filePath.startsWith('blob:')) {
      return filePath;
    }
    if (kIsWeb) return filePath.isEmpty ? null : filePath;
    if (filePath.isNotEmpty && await File(filePath).exists()) {
      return filePath;
    }

    final fileName = p.basename(
      document.fileName.isNotEmpty ? document.fileName : filePath,
    );
    if (fileName.isEmpty) return null;

    final baseDir = await _storage.getBaseDir();
    final candidates = <String>[];
    final pathParts = p.split(p.normalize(filePath));
    final filesIndex = pathParts.lastIndexWhere(
      (part) => part.toLowerCase() == 'files',
    );
    if (filesIndex >= 0 && filesIndex < pathParts.length - 1) {
      candidates.add(
        p.joinAll([baseDir.path, 'files', ...pathParts.skip(filesIndex + 1)]),
      );
    }

    candidates.add(
      p.join(
        baseDir.path,
        'files',
        'children',
        _attachmentStorageChildId(),
        _attachmentStorageFolder(document.type),
        fileName,
      ),
    );

    for (final candidate in candidates) {
      if (await File(candidate).exists()) return candidate;
    }
    return null;
  }

  Future<void> pickAttachmentFile({required String type}) async {
    final context = (this as dynamic).context;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}-'
          '${now.second.toString().padLeft(2, '0')}-'
          '${now.millisecond.toString().padLeft(3, '0')}';
      final originalName = p.basename(pickedFile.name);
      final extension =
          originalName.contains('.')
              ? originalName.substring(originalName.lastIndexOf('.'))
              : '';
      final baseName =
          extension.isEmpty
              ? originalName
              : originalName.substring(0, originalName.lastIndexOf('.'));
      final safeBaseName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final fileName = '${safeBaseName}_$timestamp$extension';
      final folder = _attachmentStorageFolder(type);
      final childStorageId = _attachmentStorageChildId();
      late final String filePath;

      if (kIsWeb) {
        final bytes = pickedFile.bytes;
        if (bytes == null) {
          throw StateError('The selected file could not be read.');
        }
        final uploadedPath = await GitHubStorageService.uploadImage(
          bytes: bytes,
          fileName: fileName,
          folder: 'children/$childStorageId/$folder',
        );
        if (uploadedPath == null) {
          throw StateError('The selected file could not be uploaded.');
        }
        filePath = uploadedPath;
      } else {
        final sourcePath = pickedFile.path;
        if (sourcePath == null || sourcePath.isEmpty) {
          throw StateError('The selected file has no readable path.');
        }
        final savedDocument = await _storage.saveFile(
          File(sourcePath),
          type: type,
          customFileName: fileName,
          relativeFolder: 'children/$childStorageId/$folder',
        );
        filePath = savedDocument.filePath;
      }

      final document = Document(
        id: const Uuid().v4(),
        fileName: fileName,
        filePath: filePath,
        type: type,
        uploadedAt: now,
      );
      (this as dynamic).setState(() {
        if (type == 'MedicalReport') {
          medicalReports.add(document);
        } else if (type == 'EducationCertificate' ||
            type == 'BirthCertificate') {
          certificates.add(document);
        } else {
          documents.add(document);
        }
      });
    } catch (e) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.get('attachment_upload_failed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick and crop image for documents
  Future<void> pickAndCropImage({
    required bool isDocument,
    bool isMedicalReport = false,
    String? customType,
  }) async {
    final context = (this as dynamic).context;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: kIsWeb, // Required for web to get bytes
      );

      if (result == null || result.files.isEmpty) return;

      if (kIsWeb) {
        // --- WEB WORKFLOW ---
        final bytes = result.files.first.bytes;
        if (bytes == null) return;

        final originalName = result.files.first.name;
        final fileExt =
            originalName.contains('.')
                ? '.${originalName.split('.').last}'
                : '.jpg';

        final docType =
            customType ??
            (isDocument
                ? (isMedicalReport ? 'Medical' : 'Profile')
                : 'Certificate');
        final fileName = _generateImageFileName(docType, fileExt);

        // Show uploading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('جاري الرفع إلى GitHub...')));

        final imageUrl = await GitHubStorageService.uploadImage(
          bytes: bytes,
          fileName: fileName,
          folder:
              'children/${_attachmentStorageChildId()}/'
              '${_attachmentStorageFolder(docType)}',
        );

        if (imageUrl != null) {
          final doc = Document(
            id: const Uuid().v4(),
            fileName: fileName,
            filePath: imageUrl,
            type: docType,
          );

          (this as dynamic).setState(() {
            if (isMedicalReport) {
              medicalReports.add(doc);
            } else if (isDocument) {
              // Handle replacement for singular types to avoid duplicates
              // Handle replacement for singular types to avoid duplicates
              if ([
                'MotherID',
                'Guardian',
                'Guardain',
                'BirthCertificate',
                'FatherDeathCertificate',
                'MotherDeathCertificate',
              ].contains(docType)) {
                documents.removeWhere((d) => d.type == docType);
                certificates.removeWhere((d) => d.type == docType);
              }
              documents.add(doc);
            } else {
              certificates.add(doc);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.successImageAdded),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // --- DESKTOP WORKFLOW ---
      final file = File(result.files.first.path!);

      // Validate file exists
      if (!file.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errFileNotFound),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // For medical reports, save without cropping
      if (isMedicalReport) {
        final fileExt =
            file.path.contains('.') ? '.${file.path.split('.').last}' : '';
        final customFileName = _generateImageFileName('Medical', fileExt);
        final savedDoc = await _storage.saveFile(
          file,
          type: 'medical',
          customFileName: customFileName,
          relativeFolder:
              'children/${_attachmentStorageChildId()}/'
              '${_attachmentStorageFolder('Medical')}',
        );

        medicalReports.add(savedDoc);
        // ... rest of desktop medical report logic
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.successMedicalAdded),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          (this as dynamic).setState(() {});
        }
        return;
      }

      // For other images, use cropper (if supported on this platform)
      File fileToSave = file;
      final docType = customType ?? (isDocument ? 'Profile' : 'Certificate');
      bool faceDetected = false;

      // Auto-detect and crop face for Profile photos
      if (docType == 'Profile') {
        final faceFile = await FaceDetectionService.detectAndCropFace(file);
        if (faceFile != null) {
          fileToSave = faceFile;
          faceDetected = true;
        }
      }

      if (!faceDetected) {
        try {
          // Try to use image cropper if available
          final loc = AppLocalizations.of(context);
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: file.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: loc.get('crop_image'),
                toolbarColor: Colors.deepOrange,
                toolbarWidgetColor: Colors.white,
              ),
              IOSUiSettings(title: loc.get('crop_image')),
            ],
          );

          if (croppedFile == null) return;
          fileToSave = File(croppedFile.path);
        } catch (e) {
          // Image cropper not supported on this platform, use original file
          // This happens on Windows and some other platforms
          fileToSave = file;
        }
      }

      final fileExt =
          fileToSave.path.contains('.')
              ? '.${fileToSave.path.split('.').last}'
              : '';
      final customFileName = _generateImageFileName(docType, fileExt);

      final savedDoc = await _storage.saveFile(
        fileToSave,
        type: docType,
        customFileName: customFileName,
        relativeFolder:
            'children/${_attachmentStorageChildId()}/'
            '${_attachmentStorageFolder(docType)}',
      );

      // Handle replacement for singular types to avoid duplicates
      if ([
        'MotherID',
        'BirthCertificate',
        'Guardian',
        'Guardain',
        'FatherDeathCertificate',
        'MotherDeathCertificate',
      ].contains(docType)) {
        documents.removeWhere((d) => d.type == docType);
        certificates.removeWhere((d) => d.type == docType);
      }

      if (isDocument) {
        documents.add(savedDoc);
      } else {
        certificates.add(savedDoc);
      }

      if (context.mounted) {
        String message = '';
        if (isDocument) {
          message = RegistrationFormI18n.successImageAdded;
        } else {
          message = RegistrationFormI18n.successCertificateAdded;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Scroll to show the image preview
        Future.delayed(Duration(milliseconds: 300), () {
          if (context.mounted) {
            // Trigger a rebuild to show the uploaded image
            (this as dynamic).setState(() {});
          }
        });
      }
    } on FileSystemException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RegistrationFormI18n.errFileSystem + e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RegistrationFormI18n.formatErrorMessage(
                'fileSave',
                value: e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick and crop image, return File (used for parent ID documents)
  /// [imageType] should be 'FatherID' or 'MotherID'
  Future<File?> pickAndCropImageFile({String imageType = 'FatherID'}) async {
    final context = (this as dynamic).context;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return null;

      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        final originalName = result.files.first.name;
        final fileExt =
            originalName.contains('.')
                ? '.${originalName.split('.').last}'
                : '.jpg';
        final fileName = _generateImageFileName(imageType, fileExt);

        if (bytes == null) return null;

        // On web, we upload directly and return a "File" proxy or the URL as path
        // We might want to store the URL in a way that the UI can use
        final imageUrl = await GitHubStorageService.uploadImage(
          bytes: bytes,
          fileName: fileName,
          folder: 'children/${childIdCtl.text}',
        );

        if (imageUrl != null) {
          final doc = Document(
            id: const Uuid().v4(),
            fileName: fileName,
            filePath: imageUrl,
            type: imageType,
          );

          (this as dynamic).setState(() {
            if (imageType == 'FatherDeathCertificate' ||
                imageType == 'MotherDeathCertificate') {
              if (!certificates.any((d) => d.type == imageType)) {
                certificates.add(doc);
              } else {
                certificates.removeWhere((d) => d.type == imageType);
                certificates.add(doc);
              }
            } else {
              if (!documents.any((d) => d.type == imageType)) {
                documents.add(doc);
              } else {
                documents.removeWhere((d) => d.type == imageType);
                documents.add(doc);
              }
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفع الصورة بنجاح على الويب'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return null;
      }

      final file = File(result.files.first.path!);

      File fileToUse = file;
      bool faceDetected = false;

      // Auto-detect and crop face for Profile photos
      if (imageType == 'Profile') {
        final faceFile = await FaceDetectionService.detectAndCropFace(file);
        if (faceFile != null) {
          fileToUse = faceFile;
          faceDetected = true;
        }
      }

      if (!faceDetected) {
        try {
          // Try to use image cropper if available
          final loc = AppLocalizations.of(context);
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: file.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: loc.get('crop_image'),
                toolbarColor: Colors.deepOrange,
                toolbarWidgetColor: Colors.white,
              ),
              IOSUiSettings(title: loc.get('crop_image')),
            ],
          );

          if (croppedFile != null) {
            fileToUse = File(croppedFile.path);
          }
        } catch (e) {
          // Image cropper not supported on this platform, use original file
          fileToUse = file;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RegistrationFormI18n.successCertUploaded),
            backgroundColor: Colors.green,
          ),
        );
      }

      return fileToUse;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RegistrationFormI18n.formatErrorMessage(
                'imageCrop',
                value: e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Get all uploaded documents from all lists and specific fields
  List<Document> get allUploadedDocuments {
    return <Document>[...documents, ...certificates, ...medicalReports];
  }

  /// Show confirmation then delete document
  Future<void> deleteDocumentWithConfirmation(Document doc) async {
    final context = (this as dynamic).context;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(RegistrationFormI18n.dialogConfirmDelete),
            content: Text(RegistrationFormI18n.msgConfirmDeleteDocument),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(RegistrationFormI18n.btnCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  RegistrationFormI18n.btnDelete,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _actualFileDeletion(doc);
    }
  }

  /// Private helper for file and database deletion
  Future<void> _actualFileDeletion(Document doc) async {
    try {
      final childIdNum = childIdCtl.text.trim();

      // 1. Delete from physical storage
      if (kIsWeb) {
        // Web: Delete from GitHub
        String? githubPath;
        if (doc.filePath.startsWith('http')) {
          githubPath = GitHubStorageService.extractPathFromUrl(doc.filePath);
        } else if (doc.fileName.isNotEmpty) {
          githubPath = 'children/$childIdNum/${doc.fileName}';
        }

        if (githubPath != null) {
          await GitHubStorageService.deleteImage(githubPath);
        }
      } else {
        // Windows: Delete from local disk
        if (doc.filePath.isNotEmpty) {
          final file = File(doc.filePath);
          if (await file.exists()) {
            await file.delete();
          } else if (doc.fileName.isNotEmpty) {
            // Try relative path resolution
            final dataPath = await SettingsService.getEffectiveDataPath();
            final altPaths = [
              p.join(dataPath, 'children', childIdNum, doc.fileName),
              p.join(dataPath, 'files', doc.fileName),
            ];
            for (var path in altPaths) {
              final altFile = File(path);
              if (await altFile.exists()) {
                await altFile.delete();
                break;
              }
            }
          }
        }
      }

      // 2. Delete from database if it exists there
      if (doc.id.isNotEmpty &&
          !doc.id.contains('_temp') &&
          !doc.id.contains('legacy')) {
        await SqliteService().deleteDocument(doc.id);
      }

      // 3. Update memory lists
      (this as dynamic).setState(() {
        documents.removeWhere((d) => d.id == doc.id);
        certificates.removeWhere((d) => d.id == doc.id);
        medicalReports.removeWhere((d) => d.id == doc.id);

        // Clear death certificate image files if needed
        if (doc.type == 'FatherDeathCertificate') {
          fatherDeathCertificateImage = null;
        } else if (doc.type == 'MotherDeathCertificate') {
          motherDeathCertificateImage = null;
        }
      });

      ScaffoldMessenger.of(
        (this as dynamic).context,
      ).showSnackBar(SnackBar(content: Text('تم حذف الملف بنجاح')));
    } catch (e) {
      debugPrint('Error during document deletion: $e');
      ScaffoldMessenger.of((this as dynamic).context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء الحذف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build Child object from current form state
  Child _buildChildFromForm() {
    final context = (this as dynamic).context;
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    final executorName =
        currentUser?.fullName ?? currentUser?.username ?? 'System';

    final id = (this as dynamic).widget.child?.id ?? Uuid().v4();

    // Extract primary photo paths from documents list
    final allDocs = [...documents, ...certificates, ...medicalReports];
    String? profilePath, profileName;
    String? motherIdPath, motherIdName;
    String? guardianIdPath, guardianIdName;
    String? fatherDeathPath, fatherDeathName;
    String? motherDeathPath, motherDeathName;
    Document? latestProfilePhoto;

    for (var doc in allDocs) {
      if (doc.type == 'Profile') {
        if (latestProfilePhoto == null ||
            doc.uploadedAt.isAfter(latestProfilePhoto.uploadedAt)) {
          latestProfilePhoto = doc;
        }
      }
      if (doc.type == 'MotherID') {
        motherIdPath = doc.filePath;
        motherIdName = doc.fileName;
      }
      if (doc.type == 'Guardian' || doc.type == 'Guardain') {
        guardianIdPath = doc.filePath;
        guardianIdName = doc.fileName;
      }
      if (doc.type == 'FatherDeathCertificate') {
        fatherDeathPath = doc.filePath;
        fatherDeathName = doc.fileName;
      }
      if (doc.type == 'MotherDeathCertificate') {
        motherDeathPath = doc.filePath;
        motherDeathName = doc.fileName;
      }
    }
    profilePath = latestProfilePhoto?.filePath;
    profileName = latestProfilePhoto?.fileName;
    final sortedSponsors = List<Sponsor>.from(sponsors)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final savedSponsor =
        sponsors.where((sponsor) => sponsor.isOngoing).firstOrNull ??
        sortedSponsors.firstOrNull;

    return Child(
      id: id,
      firstName: firstNameCtl.text.trim(),
      fatherName: fatherNameCtl.text.trim(),
      grandfatherName:
          grandfatherNameCtl.text.trim().isEmpty
              ? null
              : grandfatherNameCtl.text.trim(),
      lastName:
          familyNameCtl.text.trim().isNotEmpty
              ? familyNameCtl.text.trim()
              : lastNameCtl.text.trim(),
      childIdNumber: childIdCtl.text.trim(),
      gender: gender,
      dateOfBirth: dateOfBirth,
      country: countryCtl.text.trim(),
      city: cityCtl.text.trim(),
      street: streetCtl.text.trim(),
      birthCountry:
          birthCountryCtl.text.trim().isEmpty
              ? null
              : birthCountryCtl.text.trim(),
      birthCity:
          birthCityCtl.text.trim().isEmpty ? null : birthCityCtl.text.trim(),
      guardianPhone: guardianPhoneCtl.text.trim(),
      guardianName:
          guardianNameCtl.text.trim().isEmpty
              ? null
              : guardianNameCtl.text.trim(),
      guardianAddress:
          guardianAddressCtl.text.trim().isEmpty
              ? null
              : guardianAddressCtl.text.trim(),
      healthStatus: healthStatus,
      disabilityType: (healthStatus == 'Disabled') ? disabilityType : null,
      specialNeeds: disabilityCtl.text.trim(),
      educationLevel: _convertEducationLevelToArabic(educationLevel),
      grade: _convertSchoolClassToArabic(schoolClass),
      schoolName: schoolNameCtl.text.trim(),
      universityCollegeName:
          universityCollegeCtl.text.trim().isEmpty
              ? null
              : universityCollegeCtl.text.trim(),
      universityName:
          universityNameCtl.text.trim().isEmpty
              ? null
              : universityNameCtl.text.trim(),
      collegeSpecialization:
          collegeSpecializationCtl.text.trim().isEmpty
              ? null
              : collegeSpecializationCtl.text.trim(),
      universityYear: _convertUniversityYearToArabic(universityYear),
      nationalId:
          nationalIdCtl.text.trim().isEmpty ? null : nationalIdCtl.text.trim(),

      // Financial Details
      paymentMethod: paymentMethod,
      bankName: paymentMethod == 'bank' ? bankNameCtl.text.trim() : null,
      bankAccountNumber:
          paymentMethod == 'bank' ? bankAccountNumberCtl.text.trim() : null,
      bankIban: paymentMethod == 'bank' ? bankIbanCtl.text.trim() : null,
      bankAccountHolderName:
          paymentMethod == 'bank' ? bankAccountHolderNameCtl.text.trim() : null,
      walletNumber:
          walletNumberCtl.text.trim().isNotEmpty
              ? walletNumberCtl.text.trim()
              : null,
      walletHolderName:
          paymentMethod == 'wallet' ? walletHolderNameCtl.text.trim() : null,

      childPhotoPath: profilePath,
      childPhotoFileName: profileName,
      motherIdPhotoPath: motherIdPath,
      motherIdPhotoFileName: motherIdName,
      guardianIdPhotoPath: guardianIdPath,
      guardianIdPhotoFileName: guardianIdName,

      // Father Information
      fatherIdNumber:
          fatherIdCtl.text.trim().isEmpty ? '' : fatherIdCtl.text.trim(),
      fatherStatus: fatherStatus ?? 'Alive',
      fatherDeathDate:
          fatherDeathDateCtl.text.isNotEmpty
              ? DateTime.tryParse(fatherDeathDateCtl.text)
              : null,
      fatherDeathCause: fatherDeathCause,
      fatherDeathCertificatePath:
          fatherDeathPath ??
          (this as dynamic).widget.child?.fatherDeathCertificatePath,
      fatherDeathCertificateFileName:
          fatherDeathName ??
          (this as dynamic).widget.child?.fatherDeathCertificateFileName,

      // Mother Information
      motherName:
          motherFullNameCtl.text.trim().isEmpty
              ? ''
              : motherFullNameCtl.text.trim(),
      motherIdNumber:
          motherIdCtl.text.trim().isEmpty ? '' : motherIdCtl.text.trim(),
      motherStatus: motherStatus ?? 'Alive',
      motherDeathDate:
          motherDeathDateCtl.text.isNotEmpty
              ? DateTime.tryParse(motherDeathDateCtl.text)
              : null,
      motherDeathCause: motherDeathCause,
      motherDeathCertificatePath:
          motherDeathPath ??
          (this as dynamic).widget.child?.motherDeathCertificatePath,
      motherDeathCertificateFileName:
          motherDeathName ??
          (this as dynamic).widget.child?.motherDeathCertificateFileName,

      // Guardian Information
      guardianRelationship: guardianRelationship ?? 'Uncle',

      // Education included in educationLevel above

      // Documents
      documents: [...documents, ...certificates, ...medicalReports],
      siblings: List<Map<String, dynamic>>.from(siblingsList),

      // Sponsor
      sponsor: savedSponsor,
      createdAt: (this as dynamic).widget.child?.createdAt,
      updatedAt: DateTime.now(),
      createdBy: (this as dynamic).widget.child?.createdBy ?? executorName,
      updatedBy: executorName,
    );
  }

  String _siblingFirstName(String siblingName, Child parent) {
    final nameParts =
        siblingName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    final familyParts =
        [
          parent.fatherName,
          if (parent.grandfatherName?.trim().isNotEmpty == true)
            parent.grandfatherName!,
          parent.lastName,
        ].where((part) => part.trim().isNotEmpty).toList();

    final maxSharedCount =
        familyParts.length < nameParts.length
            ? familyParts.length
            : nameParts.length - 1;
    for (var sharedCount = maxSharedCount; sharedCount > 0; sharedCount--) {
      final nameSuffix = nameParts
          .skip(nameParts.length - sharedCount)
          .map((part) => part.toLowerCase())
          .join(' ');
      for (var start = 0; start + sharedCount <= familyParts.length; start++) {
        final commonSuffix = familyParts
            .skip(start)
            .take(sharedCount)
            .map((part) => part.toLowerCase())
            .join(' ');
        if (nameSuffix == commonSuffix) {
          return nameParts.take(nameParts.length - sharedCount).join(' ');
        }
      }
    }
    return siblingName.trim();
  }

  /// Check if a sibling's national ID conflicts with the current orphan or any existing child/sibling in the system
  Future<String?> checkSiblingNationalIdConflict(
    String nationalId, {
    String? currentChildId,
    String? excludeSiblingChildProfileId,
  }) async {
    final cleanId = nationalId.trim();
    if (cleanId.isEmpty) return null;

    // 1. Check against the main child being registered in this form
    if (nationalIdCtl.text.trim() == cleanId) {
      final name = firstNameCtl.text.trim();
      return name.isNotEmpty
          ? '$name (اليتيم الأساسي في هذه الاستمارة)'
          : 'اليتيم الأساسي في هذه الاستمارة';
    }

    // 2. Check against database children profiles
    try {
      List<Child> allChildren;
      if (kIsWeb) {
        allChildren = await FirebaseSyncService().getAllChildrenFromFirebase();
      } else {
        allChildren = await SqliteService().listChildren();
      }

      for (final child in allChildren) {
        // Skip current child if editing
        if (currentChildId != null && child.id == currentChildId) continue;
        if (excludeSiblingChildProfileId != null &&
            child.id == excludeSiblingChildProfileId) {
          continue;
        }

        // Check if child has this nationalId
        if (child.nationalId?.trim() == cleanId) {
          return child.fullName.trim().isNotEmpty
              ? child.fullName.trim()
              : child.childIdNumber;
        }

        // Also check if any sibling under this child was registered with this nationalId
        for (final sib in child.siblings) {
          final sibId = sib['id']?.toString().trim() ?? '';
          final sibProfileId = sib['childProfileId']?.toString().trim() ?? '';
          if (sibId == cleanId && sibProfileId.isNotEmpty) {
            if (excludeSiblingChildProfileId != null &&
                sibProfileId == excludeSiblingChildProfileId) {
              continue;
            }
            final sibName = sib['name']?.toString().trim() ?? '';
            return sibName.isNotEmpty
                ? sibName
                : 'أخ مسجل في ملف ${child.fullName}';
          }
        }
      }
    } catch (e) {
      print('Error checking sibling national ID conflict: $e');
    }

    return null;
  }

  /// Build reciprocal siblings list for a specific child in the family:
  /// - If target is NOT the parent orphan, adds the parent orphan (Muhammad) as a sibling.
  /// - Adds all other siblings from allSiblings EXCEPT the target child themselves (e.g. Khalil does not have Khalil in siblings).
  List<Map<String, dynamic>> _buildSiblingsForChild({
    required Child parent,
    required List<Map<String, dynamic>> allSiblings,
    String? currentChildProfileId,
    String? currentChildNationalId,
  }) {
    final result = <Map<String, dynamic>>[];

    // 1. If this child is NOT the parent orphan, add the parent orphan as a brother/sister!
    if (currentChildProfileId != parent.id) {
      result.add({
        'name':
            parent.fullName.trim().isNotEmpty
                ? parent.fullName.trim()
                : '${parent.firstName} ${parent.fatherName} ${parent.lastName}'
                    .trim(),
        'id': parent.nationalId ?? '',
        'childIdNumber': parent.childIdNumber,
        'childProfileId': parent.id,
        'birthDate': parent.dateOfBirth?.toIso8601String() ?? '',
        'gender': parent.gender ?? 'M',
        'isSponsored': parent.isSponsored,
        'sponsorshipStatus': parent.isSponsored ? 'sponsored' : 'unsponsored',
        'registerAsChild': true,
      });
    }

    // 2. Add all siblings from allSiblings EXCEPT the child themselves!
    for (final sib in allSiblings) {
      final sibProfileId = sib['childProfileId']?.toString().trim() ?? '';
      final sibId = sib['id']?.toString().trim() ?? '';

      // Skip if this sibling entry is the child itself
      if (currentChildProfileId != null &&
          currentChildProfileId.isNotEmpty &&
          sibProfileId == currentChildProfileId) {
        continue;
      }
      if (currentChildNationalId != null &&
          currentChildNationalId.isNotEmpty &&
          sibId == currentChildNationalId) {
        continue;
      }

      result.add(Map<String, dynamic>.from(sib));
    }

    return result;
  }

  Child _buildChildFromSibling(
    Child parent,
    Map<String, dynamic> sibling,
    String childIdNumber,
  ) {
    final siblingName = sibling['name']?.toString().trim() ?? '';
    final birthDate = DateTime.tryParse(sibling['birthDate']?.toString() ?? '');
    final nationalId = sibling['id']?.toString().trim();

    return Child(
      id: const Uuid().v4(),
      firstName: _siblingFirstName(siblingName, parent),
      fatherName: parent.fatherName,
      grandfatherName: parent.grandfatherName,
      lastName: parent.lastName,
      childIdNumber: childIdNumber,
      nationalId: nationalId == null || nationalId.isEmpty ? null : nationalId,
      gender: sibling['gender']?.toString() ?? parent.gender ?? 'M',
      dateOfBirth: birthDate,
      healthStatus: 'healthy',
      // Shared Family Certificates & Attachments
      fatherDeathCertificatePath: parent.fatherDeathCertificatePath,
      fatherDeathCertificateFileName: parent.fatherDeathCertificateFileName,
      motherDeathCertificatePath: parent.motherDeathCertificatePath,
      motherDeathCertificateFileName: parent.motherDeathCertificateFileName,
      motherIdPhotoPath: parent.motherIdPhotoPath,
      motherIdPhotoFileName: parent.motherIdPhotoFileName,
      guardianIdPhotoPath: parent.guardianIdPhotoPath,
      guardianIdPhotoFileName: parent.guardianIdPhotoFileName,
      documents:
          parent.documents
              .map(
                (d) => Document(
                  id: const Uuid().v4(),
                  fileName: d.fileName,
                  filePath: d.filePath,
                  type: d.type,
                  uploadedAt: d.uploadedAt,
                  updatedAt: d.updatedAt,
                ),
              )
              .toList(),
      // Shared Parents Data
      fatherIdNumber: parent.fatherIdNumber,
      fatherStatus: parent.fatherStatus,
      fatherDeathDate: parent.fatherDeathDate,
      fatherDeathCause: parent.fatherDeathCause,
      motherName: parent.motherName,
      motherIdNumber: parent.motherIdNumber,
      motherStatus: parent.motherStatus,
      motherDeathDate: parent.motherDeathDate,
      motherDeathCause: parent.motherDeathCause,
      // Shared Guardian Data
      guardianName: parent.guardianName,
      guardianAddress: parent.guardianAddress,
      guardianRelationship: parent.guardianRelationship,
      guardianPhone: parent.guardianPhone,
      // Shared Residence Data
      country: parent.country,
      city: parent.city,
      street: parent.street,
      birthCountry: parent.birthCountry,
      birthCity: parent.birthCity,
      // Shared Payment & Financial Data
      paymentMethod: parent.paymentMethod,
      bankName: parent.bankName,
      bankAccountNumber: parent.bankAccountNumber,
      bankIban: parent.bankIban,
      bankAccountHolderName: parent.bankAccountHolderName,
      walletName: parent.walletName,
      walletNumber: parent.walletNumber,
      walletHolderName: parent.walletHolderName,
      // Siblings list will be set accurately by _buildSiblingsForChild
      siblings: const [],
      createdBy: parent.createdBy,
      updatedBy: parent.updatedBy,
    );
  }

  Future<void> _persistSiblingProfile(
    Child child, {
    required SqliteService db,
    required FirebaseSyncService firebaseSync,
    required bool isWeb,
  }) async {
    if (isWeb) {
      await firebaseSync.saveChildToFirebase(child);
      WebCacheService().updateChildInCache(child);
      return;
    }

    await db.insertChild(child);
    try {
      await firebaseSync.syncChildData(child);
    } catch (e) {
      print('ℹ️ تم حفظ ملف الأخ محلياً (المزامنة مؤجلة: $e)');
    }
  }

  Future<int> _createSelectedSiblingProfiles(
    Child parent, {
    required SqliteService db,
    required FirebaseSyncService firebaseSync,
    required bool isWeb,
  }) async {
    final loc = AppLocalizations.of((this as dynamic).context);
    final selectedSiblings =
        siblingsList.asMap().entries.where((entry) {
          final sibling = entry.value;
          final childProfileId = sibling['childProfileId']?.toString() ?? '';
          return sibling['registerAsChild'] == true && childProfileId.isEmpty;
        }).toList();
    if (selectedSiblings.isEmpty) return 0;

    final countryName = parent.country?.trim() ?? '';
    if (countryName.isEmpty) {
      throw StateError(loc.get('sibling_profile_missing_country'));
    }

    final createdProfiles = <Child>[];
    for (final entry in selectedSiblings) {
      final sibling = entry.value;
      final siblingName = sibling['name']?.toString().trim() ?? '';
      if (siblingName.isEmpty) {
        throw StateError(loc.get('sibling_name_required_for_registration'));
      }
      final siblingNationalId = sibling['id']?.toString().trim() ?? '';
      if (siblingNationalId.isNotEmpty) {
        final conflict = await checkSiblingNationalIdConflict(
          siblingNationalId,
          currentChildId: parent.id,
        );
        if (conflict != null) {
          throw StateError(
            '${loc.get('sibling_national_id_already_used')}: $siblingNationalId ($conflict)',
          );
        }
      }

      final countryCode =
          selectedCountry?.nameAr == 'فلسطين' ? '01' : selectedCountry?.code;
      final childIdNumber = await db.getNextCountryBasedChildId(
        countryName,
        knownCode: countryCode,
      );
      final siblingChild = _buildChildFromSibling(
        parent,
        sibling,
        childIdNumber,
      );

      sibling['childProfileId'] = siblingChild.id;
      sibling['childIdNumber'] = siblingChild.childIdNumber;
      createdProfiles.add(siblingChild);
    }

    // 1. Update parent's siblings list (all siblings with their newly assigned childProfileIds)
    parent.siblings = _buildSiblingsForChild(
      parent: parent,
      allSiblings: siblingsList,
      currentChildProfileId: parent.id,
      currentChildNationalId: parent.nationalId,
    );
    parent.updatedAt = DateTime.now();
    await _persistSiblingProfile(
      parent,
      db: db,
      firebaseSync: firebaseSync,
      isWeb: isWeb,
    );

    // 2. Update each created sibling child's siblings list (contains parent + other siblings) and persist
    for (final siblingChild in createdProfiles) {
      siblingChild.siblings = _buildSiblingsForChild(
        parent: parent,
        allSiblings: siblingsList,
        currentChildProfileId: siblingChild.id,
        currentChildNationalId: siblingChild.nationalId,
      );
      siblingChild.updatedAt = DateTime.now();
      await _persistSiblingProfile(
        siblingChild,
        db: db,
        firebaseSync: firebaseSync,
        isWeb: isWeb,
      );
    }

    return createdProfiles.length;
  }

  Future<_SiblingSaveChoice?> _confirmSiblingRegistration(
    BuildContext context, {
    required int siblingCount,
    required int selectedCount,
  }) {
    final loc = AppLocalizations.of(context);
    return showDialog<_SiblingSaveChoice>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(loc.get('sibling_registration_confirmation_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.get('sibling_registration_confirmation_message')),
                const SizedBox(height: 12),
                Text(
                  '${loc.get('added_siblings')}: $siblingCount',
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  '${loc.get('sibling_registration_selected_count')}: $selectedCount',
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.pop(dialogContext, _SiblingSaveChoice.cancel),
                child: Text(loc.get('cancel')),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      dialogContext,
                      _SiblingSaveChoice.saveFamilyOnly,
                    ),
                child: Text(loc.get('sibling_registration_save_only')),
              ),
              if (selectedCount > 0)
                FilledButton.tonal(
                  onPressed:
                      () => Navigator.pop(
                        dialogContext,
                        _SiblingSaveChoice.registerSelected,
                      ),
                  child: Text(loc.get('sibling_registration_selected')),
                ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(
                      dialogContext,
                      _SiblingSaveChoice.registerAll,
                    ),
                child: Text(loc.get('sibling_registration_all')),
              ),
            ],
          ),
    );
  }

  Future<Child?> _getPersistedChild(
    String childId, {
    required SqliteService db,
    required FirebaseSyncService firebaseSync,
    required bool isWeb,
  }) {
    return isWeb
        ? firebaseSync.getChildFromFirebase(childId)
        : db.getChildById(childId);
  }

  Future<void> _verifySiblingDataSaved(
    Child parent, {
    required SqliteService db,
    required FirebaseSyncService firebaseSync,
    required bool isWeb,
  }) async {
    final savedParent = await _getPersistedChild(
      parent.id,
      db: db,
      firebaseSync: firebaseSync,
      isWeb: isWeb,
    );
    if (savedParent == null ||
        savedParent.siblings.length != parent.siblings.length ||
        List.generate(parent.siblings.length, (index) {
          final expected = parent.siblings[index];
          final actual = savedParent.siblings[index];
          return expected['name']?.toString() != actual['name']?.toString() ||
              expected['id']?.toString() != actual['id']?.toString() ||
              expected['birthDate']?.toString() !=
                  actual['birthDate']?.toString() ||
              expected['isSponsored'] != actual['isSponsored'] ||
              expected['sponsorshipStatus'] != actual['sponsorshipStatus'] ||
              expected['registerAsChild'] != actual['registerAsChild'] ||
              expected['gender']?.toString() != actual['gender']?.toString() ||
              expected['childProfileId']?.toString() !=
                  actual['childProfileId']?.toString() ||
              expected['childIdNumber']?.toString() !=
                  actual['childIdNumber']?.toString();
        }).any((hasMismatch) => hasMismatch)) {
      throw StateError(
        AppLocalizations.of(
          (this as dynamic).context,
        ).get('sibling_data_not_saved'),
      );
    }

    for (final sibling in parent.siblings) {
      final profileId = sibling['childProfileId']?.toString() ?? '';
      if (profileId.isEmpty) continue;

      final savedProfile = await _getPersistedChild(
        profileId,
        db: db,
        firebaseSync: firebaseSync,
        isWeb: isWeb,
      );
      if (savedProfile == null ||
          savedProfile.childIdNumber != sibling['childIdNumber']?.toString()) {
        throw StateError(
          AppLocalizations.of(
            (this as dynamic).context,
          ).get('sibling_profile_not_saved'),
        );
      }
    }
  }

  /// Save form as draft
  Future<void> saveDraft() async {
    final context = (this as dynamic).context;
    try {
      final child = _buildChildFromForm();
      final baseDir = await _storage.getBaseDir();
      final draftsDir = Directory('${baseDir.path}/drafts');

      if (!await draftsDir.exists()) {
        await draftsDir.create(recursive: true);
      }

      final draftFile = File(
        '${draftsDir.path}/draft_${child.id}_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await draftFile.writeAsString(jsonEncode(child.toJson()));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RegistrationFormI18n.successDraftSaved),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RegistrationFormI18n.formatErrorMessage(
                'draftSave',
                value: e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Strip absolute paths from child object before saving to database
  /// This ensures only filenames are stored as requested by user
  void _stripAbsolutePaths(Child child) {
    String? strip(String? pth) {
      if (pth == null || pth.isEmpty) return pth;
      if (pth.startsWith('http') || pth.startsWith('blob:')) return pth;
      return p.basename(pth);
    }

    child.childPhotoPath = strip(child.childPhotoPath);
    child.motherIdPhotoPath = strip(child.motherIdPhotoPath);
    child.guardianIdPhotoPath = strip(child.guardianIdPhotoPath);
    child.fatherDeathCertificatePath = strip(child.fatherDeathCertificatePath);
    child.motherDeathCertificatePath = strip(child.motherDeathCertificatePath);

    for (var doc in child.documents) {
      doc.filePath = strip(doc.filePath) ?? '';
    }
  }

  /// Submit form and save to database
  Future<bool> submit({bool isFinalStep = false}) async {
    final context = (this as dynamic).context;
    if (!_formKey.currentState!.validate()) return false;

    if (!context.mounted) return false;

    final isWeb = kIsWeb;
    final isActuallyFinal = isFinalStep;

    // Only prompt and process sibling independent profiles if we are at the final step!
    if (isActuallyFinal) {
      final pendingSiblings =
          siblingsList.where((sibling) {
            final childProfileId = sibling['childProfileId']?.toString() ?? '';
            return childProfileId.isEmpty;
          }).toList();
      if (pendingSiblings.isNotEmpty) {
        final selectedCount =
            pendingSiblings
                .where((sibling) => sibling['registerAsChild'] == true)
                .length;
        final choice = await _confirmSiblingRegistration(
          context,
          siblingCount: siblingsList.length,
          selectedCount: selectedCount,
        );
        if (!context.mounted ||
            choice == null ||
            choice == _SiblingSaveChoice.cancel) {
          return false;
        }

        if (choice == _SiblingSaveChoice.registerAll) {
          for (final sibling in pendingSiblings) {
            sibling['registerAsChild'] = true;
            sibling['gender'] ??= gender ?? 'M';
          }
        } else if (choice == _SiblingSaveChoice.saveFamilyOnly) {
          for (final sibling in pendingSiblings) {
            sibling['registerAsChild'] = false;
          }
        }
        (this as dynamic).setState(() {});
      }

      final selectedSiblingCount =
          siblingsList.where((sibling) {
            final childProfileId = sibling['childProfileId']?.toString() ?? '';
            return sibling['registerAsChild'] == true && childProfileId.isEmpty;
          }).length;
      if (selectedSiblingCount > 0) {
        final loc = AppLocalizations.of(context);
        if (countryCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.get('sibling_profile_missing_country'))),
          );
          return false;
        }
        if (siblingsList.any(
          (sibling) =>
              sibling['registerAsChild'] == true &&
              (sibling['childProfileId']?.toString().isEmpty ?? true) &&
              (sibling['name']?.toString().trim().isEmpty ?? true),
        )) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.get('sibling_name_required_for_registration')),
            ),
          );
          return false;
        }

        // Validate national IDs of selected siblings
        final selectedNationalIds = <String>[];
        for (final sibling in siblingsList) {
          if (sibling['registerAsChild'] == true &&
              (sibling['childProfileId']?.toString().isEmpty ?? true)) {
            final id = sibling['id']?.toString().trim() ?? '';
            final name = sibling['name']?.toString().trim() ?? '';
            if (id.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'يرجى إدخال رقم الهوية للأخ ($name) لتسجيله في البرنامج',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
            if (id == nationalIdCtl.text.trim()) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'رقم هوية الأخ ($name) مطابق لرقم هوية اليتيم الأساسي!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
            if (selectedNationalIds.contains(id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'رقم الهوية ($id) مكرر بين أكثر من أخ في القائمة!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
            selectedNationalIds.add(id);

            final conflict = await checkSiblingNationalIdConflict(
              id,
              currentChildId: (this as dynamic).widget.child?.id,
            );
            if (conflict != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'رقم الهوية ($id) للأخ ($name) مسجل مسبقاً في النظام لليتيم: $conflict',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              return false;
            }
          }
        }
      }
    }

    var registeredSiblingCount = 0;

    try {
      // إنشاء Dialog للتقدم
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => Dialog(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'جاري حفظ البيانات...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 10),
                    ValueListenableBuilder<String>(
                      valueListenable: _savingStatus,
                      builder:
                          (ctx, status, child) => Text(
                            status,
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                            textDirection: TextDirection.rtl,
                          ),
                    ),
                  ],
                ),
              ),
            ),
      );

      final isEditing = (this as dynamic).widget.child != null;
      final originalChildIdNum = (this as dynamic).widget.child?.childIdNumber;

      if (childIdCtl.text.isEmpty) {
        _updateSavingStatus('توليد معرف اليتيم...');
        int count = 0;
        if (isWeb) {
          try {
            final all =
                await FirebaseSyncService().getAllChildrenFromFirebase();
            count = all.length;
          } catch (e) {
            print('⚠️ فشل جلب العدد من Firebase: $e');
            count = DateTime.now().millisecondsSinceEpoch % 1000;
          }
        } else {
          final all = await SqliteService().listChildren();
          count = all.length;
        }
        final nextNum = (count + 1).toString().padLeft(3, '0');
        childIdCtl.text = 'ihsan-$nextNum';
      }

      _updateSavingStatus('بناء بيانات اليتيم...');
      final child = _buildChildFromForm();

      // Strip paths to store only filenames in database (as requested)
      _stripAbsolutePaths(child);

      final db = SqliteService();
      final firebaseSync = FirebaseSyncService();

      if (isWeb) {
        // ==================== WEB WORKFLOW ====================

        // Handle ID Change on Web (if needed for cleanup, though we skip physical move for safety)
        if (isEditing &&
            originalChildIdNum != null &&
            originalChildIdNum != child.childIdNumber) {
          print(
            '🔄 [Web] ID Changed from $originalChildIdNum to ${child.childIdNumber}',
          );
          // We don't move physical files on GitHub to avoid risk
          // But we should delete the OLD document from Firestore to avoid duplication
          // (Since we are creating a new doc with new ID).
          // However, our child ID (UUID) stays same?
          // WAIT: Child.id is UUID. child.childIdNumber is the "IHSAN..." string.
          // Firestore document ID is usually Child.id (UUID).
          // So updating the document is fine.
          // The files are stored in 'children/$childIdNumber/'.
          // So the links inside the doc will still point to old folder 'children/OLD_ID/'
          // which is valid since we didn't delete it.
          // So this is actually safe!
        }

        _updateSavingStatus('رفع البيانات إلى Firebase...');
        await firebaseSync.saveChildToFirebase(child);

        if (payments.isNotEmpty) {
          _updateSavingStatus('رفع المدفوعات إلى Firebase...');
          // If ID changed, we might want to migrate payments?
          // Payments are subcollection of child doc. Child doc ID (UUID) didn't change.
          // So payments are fine.
          for (int i = 0; i < payments.length; i++) {
            _updateSavingStatus(
              'رفع المدفوعات (${i + 1}/${payments.length})...',
            );
            await firebaseSync.savePaymentToFirebase(child.id, payments[i]);
          }
        }

        // Update web cache to reflect new data immediately
        _updateSavingStatus('تحديث الذاكرة المؤقتة...');
        WebCacheService().updateChildInCache(child);

        print('✅ [Web] تم الحفظ بنجاح في السحابة');
      } else {
        // ==================== WINDOWS WORKFLOW ====================

        // Handle ID Change on Windows (Physical Move)
        if (isEditing &&
            originalChildIdNum != null &&
            originalChildIdNum != child.childIdNumber) {
          _updateSavingStatus('نقل الملفات إلى المعرف الجديد...');
          await _moveImagesToNewIdFolder(
            originalChildIdNum,
            child.childIdNumber,
          );

          // Update paths in the child object to point to new folder?
          // Since we store only filenames in DB, and build paths dynamically based on ID,
          // it should "just work" as long as files are physically moved.
        }

        _updateSavingStatus('حفظ البيانات محلياً (SQLite)...');
        await db.insertChild(child);

        _updateSavingStatus('حفظ المدفوعات محلياً...');
        await db.deletePaymentsByChildId(child.id);
        for (final p in payments) {
          p.childId = child.id;
          await db.insertPayment(p);
        }

        // Attempt async sync
        _updateSavingStatus('جاري المزامنة مع السحابة...');
        try {
          await firebaseSync.syncChildData(child);
          print('✅ [Windows] تم الحفظ محلياً والمزامنة مع السحابة');
        } catch (e) {
          print('ℹ️ [Windows] تم الحفظ محلياً (مزامنة مؤجلة: $e)');
        }
      }

      await _verifySiblingDataSaved(
        child,
        db: db,
        firebaseSync: firebaseSync,
        isWeb: isWeb,
      );

      if (isActuallyFinal) {
        final selectedSiblingCount =
            siblingsList.where((sibling) {
              final childProfileId =
                  sibling['childProfileId']?.toString() ?? '';
              return sibling['registerAsChild'] == true &&
                  childProfileId.isEmpty;
            }).length;
        if (selectedSiblingCount > 0) {
          _updateSavingStatus('جاري إنشاء ملفات الإخوة...');
          registeredSiblingCount = await _createSelectedSiblingProfiles(
            child,
            db: db,
            firebaseSync: firebaseSync,
            isWeb: isWeb,
          );
        }
      }

      await _verifySiblingDataSaved(
        child,
        db: db,
        firebaseSync: firebaseSync,
        isWeb: isWeb,
      );

      _updateSavingStatus('انتظر...');
      // Invalidate cache for this country so the next registration gets fresh ID
      if (selectedCountry != null) {
        _childIdCache.remove(selectedCountry!.nameAr);
      }
      await Future.delayed(const Duration(seconds: 1));

      // إغلاق Dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم حفظ بيانات اليتيم بنجاح!\nالمعرف: ${child.childIdNumber}'
                    '${child.siblings.isNotEmpty ? '\n${AppLocalizations.of(context).get('sibling_details_saved')}' : ''}'
                    '${registeredSiblingCount > 0 ? '\n${AppLocalizations.of(context).get('sibling_profiles_created')}' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return true;
    } catch (e) {
      // إغلاق Dialog في حالة الخطأ
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('❌ خطأ في الحفظ: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('خطأ في الحفظ: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }

  void _updateSavingStatus(String status) {
    _savingStatus.value = status;
    print('📝 $status');
  }

  /// Finish and close form
  Future<void> finishAndClose() async {
    final saved = await submit(isFinalStep: true);
    final context = (this as dynamic).context;
    if (saved && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<Child?> _submitAndGetReportChild(BuildContext context) async {
    if (!await submit()) return null;

    final savedChildren = await SqliteService().listChildren();
    for (final child in savedChildren) {
      if (child.childIdNumber == childIdCtl.text.trim()) return child;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RegistrationFormI18n.errChildNotLocated),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  /// Generate and open PDF report
  Future<void> generatePdfReport({bool includePayments = false}) async {
    final context = (this as dynamic).context;

    try {
      final child = await _submitAndGetReportChild(context);
      if (child == null) {
        return;
      }

      await OrphanReportPDF.generateAndOpen(
        child,
        context: context,
        locale: Localizations.localeOf(context),
        includePaymentsTable: includePayments,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RegistrationFormI18n.formatErrorMessage(
                'reportGeneration',
                value: e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List?> generatePdfPreviewBytes({
    required bool includePayments,
  }) async {
    final context = (this as dynamic).context;

    try {
      final child = await _submitAndGetReportChild(context);
      if (child == null) return null;

      final locale = Localizations.localeOf(context);
      return OrphanPdfReport(
        child: child,
        locale: locale,
        includePaymentsTable: includePayments,
        reportTitleKey: 'orphan_form',
      ).generatePdfBytes(locale);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RegistrationFormI18n.formatErrorMessage(
                'reportGeneration',
                value: e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Check if child with this national ID or Name already exists in database
  Future<bool> _checkIfChildAlreadyExists({
    String? nationalId,
    String? firstName,
    String? lastName,
  }) async {
    try {
      List<Child> children;
      if (kIsWeb) {
        children = await FirebaseSyncService().getAllChildrenFromFirebase();
      } else {
        children = await SqliteService().listChildren();
      }

      final currentChildId = (this as dynamic).widget.child?.id;

      return children.any((child) {
        // Skip current child during edit
        if (currentChildId != null && child.id == currentChildId) return false;

        // Check National ID if provided
        if (nationalId != null &&
            nationalId.isNotEmpty &&
            child.nationalId == nationalId) {
          return true;
        }

        // Check Name and Family Name
        if (firstName != null &&
            lastName != null &&
            child.firstName.trim().toLowerCase() ==
                firstName.trim().toLowerCase() &&
            child.lastName.trim().toLowerCase() ==
                lastName.trim().toLowerCase()) {
          return true;
        }

        return false;
      });
    } catch (e) {
      print('Error checking child existence: $e');
      return false;
    }
  }

  /// Validate current step - returns Future for async validation
  Future<bool> validateCurrentStepAsync() async {
    final context = (this as dynamic).context;
    switch (currentStep) {
      case 0:
        // Check First Name
        if (firstNameCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errFirstNameRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Check Family Name
        if (familyNameCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errFamilyNameRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Check National ID
        if (nationalIdCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errNationalIdRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Validate National ID format (numbers only)
        if (!RegExp(r'^[0-9]*$').hasMatch(nationalIdCtl.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errNationalIdNumbersOnly),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Check if child with this national ID or Name already exists
        final exists = await _checkIfChildAlreadyExists(
          nationalId: nationalIdCtl.text.trim(),
          firstName: firstNameCtl.text.trim(),
          lastName: familyNameCtl.text.trim(),
        );
        if (exists) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(RegistrationFormI18n.errChildAlreadyRegistered),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return false;
        }

        // Check that both father and mother are not alive
        if (fatherStatus == 'Alive' && motherStatus == 'Alive') {
          if (context.mounted) {
            final locale = Localizations.localeOf(context);
            String errorMessage;

            if (locale.languageCode == 'ar') {
              errorMessage =
                  'لا يمكن إدخال يتيم إذا كان الأب والأم على قيد الحياة';
            } else if (locale.languageCode == 'en') {
              errorMessage =
                  'Cannot register an orphan if both parents are living';
            } else if (locale.languageCode == 'tr') {
              errorMessage = 'Her iki ebeveyn yaşıyorsa yetim kaydedilemez';
            } else {
              errorMessage =
                  'لا يمكن إدخال يتيم إذا كان الأب والأم على قيد الحياة';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return false;
        }

        return true;
      case 1:
        if (healthStatus == 'Disabled' && disabilityCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errDisabilityRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 2:
        if (documents.isEmpty && certificates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errDocumentRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  /// Validate current step
  bool validateCurrentStep() {
    final context = (this as dynamic).context;
    switch (currentStep) {
      case 0:
        // Check First Name
        if (firstNameCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errFirstNameRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Check Family Name
        if (familyNameCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errFamilyNameRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Check National ID
        if (nationalIdCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errNationalIdRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Validate National ID format (numbers only)
        if (!RegExp(r'^[0-9]*$').hasMatch(nationalIdCtl.text.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errNationalIdNumbersOnly),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Note: For duplicate check, call validateCurrentStepAsync instead
        return true;

      case 1:
        if (healthStatus == 'Disabled' && disabilityCtl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errDisabilityRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 2:
        if (documents.isEmpty && certificates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(RegistrationFormI18n.errDocumentRequired),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  /// Get next country code
  Future<String> _getNextCountryCode() async {
    if (countries.isEmpty) return '01';
    int maxCode = 0;
    for (var country in countries) {
      try {
        final code = int.parse(country.code);
        if (code > maxCode) maxCode = code;
      } catch (e) {}
    }
    return (maxCode + 1).toString().padLeft(2, '0');
  }

  /// Add a new sibling
  Future<void> addSibling(BuildContext context) async {
    final siblingNameCtl = TextEditingController();
    final siblingIdCtl = TextEditingController();
    DateTime? siblingBirthDate;
    String sponsorshipStatus = 'unsponsored';
    bool registerAsChild = false;
    String siblingGender = gender ?? 'M';

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(loc.get('add_sibling')),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sibling Name
                          TextField(
                            controller: siblingNameCtl,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_name'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: siblingGender,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_gender'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people_outline),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'M',
                                child: Text(loc.get('gender_male')),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Text(loc.get('gender_female')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => siblingGender = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: registerAsChild,
                            title: Text(loc.get('register_sibling_as_child')),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged:
                                (value) => setState(
                                  () => registerAsChild = value ?? false,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Sibling ID
                          TextField(
                            controller: siblingIdCtl,
                            decoration: InputDecoration(
                              labelText: loc.get('national_id'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                              hintText: loc.get('numbers_only'),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade600,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          // Birth Date
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: loc.get('birth_date'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.edit_calendar),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => siblingBirthDate = picked);
                                  }
                                },
                              ),
                            ),
                            controller: TextEditingController(
                              text:
                                  siblingBirthDate != null
                                      ? siblingBirthDate!
                                          .toIso8601String()
                                          .split('T')[0]
                                      : '',
                            ),
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: sponsorshipStatus,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_sponsorship_status'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'sponsored',
                                child: Text(loc.get('sponsored')),
                              ),
                              DropdownMenuItem<String>(
                                value: 'unsponsored',
                                child: Text(loc.get('not_sponsored')),
                              ),
                              DropdownMenuItem<String>(
                                value: 'candidate',
                                child: Text(loc.get('sponsorship_candidate')),
                              ),
                            ],
                            onChanged:
                                (value) => setState(
                                  () =>
                                      sponsorshipStatus =
                                          value ?? 'unsponsored',
                                ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.get('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = siblingNameCtl.text.trim();
                          final id = siblingIdCtl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.get('please_enter_sibling_name'),
                                ),
                              ),
                            );
                            return;
                          }

                          if (registerAsChild && id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'يرجى إدخال رقم الهوية للأخ لتسجيله في البرنامج',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (id.isNotEmpty) {
                            if (id == nationalIdCtl.text.trim()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'رقم هوية الأخ مطابق لرقم هوية اليتيم الأساسي!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final duplicateInList = siblingsList.any(
                              (s) => s['id']?.toString().trim() == id,
                            );
                            if (duplicateInList) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'رقم الهوية مكرر مع أخ آخر في هذه القائمة!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final conflict =
                                await checkSiblingNationalIdConflict(
                                  id,
                                  currentChildId:
                                      (this as dynamic).widget.child?.id,
                                );
                            if (conflict != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'رقم الهوية ($id) مسجل مسبقاً في النظام لليتيم: $conflict',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                              return;
                            }
                          }

                          siblingsList.add({
                            'name': name,
                            'id': id,
                            'birthDate':
                                siblingBirthDate?.toIso8601String() ?? '',
                            'sponsorshipStatus': sponsorshipStatus,
                            'isSponsored': sponsorshipStatus == 'sponsored',
                            'gender': siblingGender,
                            'registerAsChild': registerAsChild,
                          });

                          Navigator.pop(context);
                          (this as dynamic).setState(() {});
                        },
                        child: Text(loc.get('add_button')),
                      ),
                    ],
                  ),
            ),
      );
    }
  }

  /// Remove sibling from list
  void removeSibling(int index) {
    siblingsList.removeAt(index);
  }

  String siblingSponsorshipStatus(Map<String, dynamic> sibling) {
    final status = sibling['sponsorshipStatus']?.toString();
    if (status == 'sponsored' ||
        status == 'unsponsored' ||
        status == 'candidate') {
      return status!;
    }
    return sibling['isSponsored'] == true ? 'sponsored' : 'unsponsored';
  }

  /// Edit a sibling
  Future<void> editSibling(BuildContext context, int index) async {
    final sibling = siblingsList[index];
    final siblingNameCtl = TextEditingController(text: sibling['name']);
    final siblingIdCtl = TextEditingController(text: sibling['id'] ?? '');
    DateTime? siblingBirthDate;
    String sponsorshipStatus = siblingSponsorshipStatus(sibling);
    bool registerAsChild = sibling['registerAsChild'] == true;
    String siblingGender = sibling['gender']?.toString() ?? gender ?? 'M';
    final isAlreadyRegistered =
        (sibling['childProfileId']?.toString().isNotEmpty ?? false);

    // Parse birth date if available
    if (sibling['birthDate'] != null && sibling['birthDate']!.isNotEmpty) {
      try {
        siblingBirthDate = DateTime.parse(sibling['birthDate']!);
      } catch (e) {
        siblingBirthDate = null;
      }
    }

    if (context.mounted) {
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(loc.get('edit_sibling')),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sibling Name
                          TextField(
                            controller: siblingNameCtl,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_name'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: siblingGender,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_gender'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people_outline),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'M',
                                child: Text(loc.get('gender_male')),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Text(loc.get('gender_female')),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => siblingGender = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: registerAsChild || isAlreadyRegistered,
                            title: Text(loc.get('register_sibling_as_child')),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged:
                                isAlreadyRegistered
                                    ? null
                                    : (value) => setState(
                                      () => registerAsChild = value ?? false,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          // Sibling ID
                          TextField(
                            controller: siblingIdCtl,
                            decoration: InputDecoration(
                              labelText: loc.get('national_id'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.credit_card),
                              hintText: loc.get('numbers_only'),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade600,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          // Birth Date
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: loc.get('birth_date'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.edit_calendar),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        siblingBirthDate ?? DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => siblingBirthDate = picked);
                                  }
                                },
                              ),
                            ),
                            controller: TextEditingController(
                              text:
                                  siblingBirthDate != null
                                      ? siblingBirthDate!
                                          .toIso8601String()
                                          .split('T')[0]
                                      : '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: sponsorshipStatus,
                            decoration: InputDecoration(
                              labelText: loc.get('sibling_sponsorship_status'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'sponsored',
                                child: Text(loc.get('sponsored')),
                              ),
                              DropdownMenuItem<String>(
                                value: 'unsponsored',
                                child: Text(loc.get('not_sponsored')),
                              ),
                              DropdownMenuItem<String>(
                                value: 'candidate',
                                child: Text(loc.get('sponsorship_candidate')),
                              ),
                            ],
                            onChanged:
                                (value) => setState(
                                  () =>
                                      sponsorshipStatus =
                                          value ?? 'unsponsored',
                                ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.get('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = siblingNameCtl.text.trim();
                          final id = siblingIdCtl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.get('please_enter_sibling_name'),
                                ),
                              ),
                            );
                            return;
                          }

                          if ((registerAsChild || isAlreadyRegistered) &&
                              id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'يرجى إدخال رقم الهوية للأخ لتسجيله في البرنامج',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (id.isNotEmpty) {
                            if (id == nationalIdCtl.text.trim()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'رقم هوية الأخ مطابق لرقم هوية اليتيم الأساسي!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final duplicateInList = siblingsList
                                .asMap()
                                .entries
                                .any(
                                  (e) =>
                                      e.key != index &&
                                      e.value['id']?.toString().trim() == id,
                                );
                            if (duplicateInList) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'رقم الهوية مكرر مع أخ آخر في هذه القائمة!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final conflict =
                                await checkSiblingNationalIdConflict(
                                  id,
                                  currentChildId:
                                      (this as dynamic).widget.child?.id,
                                  excludeSiblingChildProfileId:
                                      sibling['childProfileId']?.toString(),
                                );
                            if (conflict != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'رقم الهوية ($id) مسجل مسبقاً في النظام لليتيم: $conflict',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                              return;
                            }
                          }

                          siblingsList[index] = {
                            ...sibling,
                            'name': name,
                            'id': id,
                            'birthDate':
                                siblingBirthDate?.toIso8601String() ?? '',
                            'sponsorshipStatus': sponsorshipStatus,
                            'isSponsored': sponsorshipStatus == 'sponsored',
                            'gender': siblingGender,
                            'registerAsChild':
                                registerAsChild || isAlreadyRegistered,
                          };
                          Navigator.pop(context);
                          (this as dynamic).setState(() {});
                        },
                        child: Text(RegistrationFormI18n.btnUpdate),
                      ),
                    ],
                  ),
            ),
      );
    }
  }

  /// Add a new payment record
  Future<void> addPayment({
    required double amount,
    required DateTime paidAt,
    String? currency,
    String? note,
    String? sponsorId,
  }) async {
    final context = (this as dynamic).context;
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;

    final paymentId = const Uuid().v4();
    final childId = childIdCtl.text;

    final payment = Payment(
      id: paymentId,
      childId: childId,
      sponsorId: sponsorId,
      amount: amount,
      currency: currency ?? selectedCurrency ?? 'شيكل',
      paidAt: paidAt,
      note: note,
      createdBy: currentUser?.fullName ?? currentUser?.username ?? 'System',
      updatedBy: currentUser?.fullName ?? currentUser?.username ?? 'System',
    );

    payments.add(payment);

    // Save to database
    try {
      await SqliteService().insertPayment(payment);
    } catch (e) {
      debugPrint('Error saving payment: $e');
      payments.removeWhere((p) => p.id == paymentId);
      rethrow;
    }
  }

  /// Delete a payment record
  Future<void> deletePayment(String paymentId) async {
    payments.removeWhere((p) => p.id == paymentId);
    // TODO: Implement delete in database when needed
  }

  /// Load payments for current child
  Future<void> loadPayments() async {
    try {
      final childId = childIdCtl.text;
      if (childId.isEmpty) return;

      final paymentsList = await SqliteService().listPayments(childId: childId);
      payments = paymentsList;
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }
  }

  /// Get total payments for current child
  double getTotalPayments() {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }
}
