/// Localization and Internationalization (i18n) strings for Registration Form
/// This file contains all translated and transliterable text used in the registration form

class RegistrationFormI18n {
  // ==================== Education Level Keys ====================
  static const String educationLevelNone = 'education_level_none';
  static const String educationLevelPrimary = 'education_level_primary';
  static const String educationLevelMiddle = 'education_level_middle';
  static const String educationLevelSecondary = 'education_level_secondary';
  static const String educationLevelUniversity = 'education_level_university';
  static const String educationLevelCollege = 'education_level_college';
  static const String educationLevelNotStudying =
      'education_level_not_studying';

  // ==================== University Year Keys ====================
  static const String year1 = 'year_1';
  static const String year2 = 'year_2';
  static const String year3 = 'year_3';
  static const String year4 = 'year_4';
  static const String year5 = 'year_5';
  static const String year6 = 'year_6';
  static const String yearGraduate = 'year_graduate';

  // ==================== School Class Keys ====================
  static const String primary1 = 'primary_1';
  static const String primary2 = 'primary_2';
  static const String primary3 = 'primary_3';
  static const String primary4 = 'primary_4';
  static const String primary5 = 'primary_5';
  static const String primary6 = 'primary_6';
  static const String middle7 = 'middle_7';
  static const String middle8 = 'middle_8';
  static const String middle9 = 'middle_9';
  static const String secondary10 = 'secondary_10';
  static const String secondary11 = 'secondary_11';
  static const String secondary12 = 'secondary_12';

  // ==================== Arabic Text Translations ====================
  /// Educational levels in Arabic
  static Map<String, String> educationLevelToArabic = {
    educationLevelNone: 'مرحلة ما قبل الدراسة',
    educationLevelPrimary: 'ابتدائي',
    educationLevelMiddle: 'إعدادي',
    educationLevelSecondary: 'ثانوي',
    educationLevelUniversity: 'جامعي',
    educationLevelCollege: 'كلية',
    educationLevelNotStudying: 'لا يدرس',
  };

  /// University years in Arabic
  static Map<String, String> universityYearToArabic = {
    year1: 'السنة الأولى',
    year2: 'السنة الثانية',
    year3: 'السنة الثالثة',
    year4: 'السنة الرابعة',
    year5: 'السنة الخامسة',
    year6: 'السنة السادسة',
    yearGraduate: 'خريج',
  };

  /// School classes in Arabic
  static Map<String, String> schoolClassToArabic = {
    primary1: 'الأول',
    primary2: 'الثاني',
    primary3: 'الثالث',
    primary4: 'الرابع',
    primary5: 'الخامس',
    primary6: 'السادس',
    middle7: 'السابع',
    middle8: 'الثامن',
    middle9: 'التاسع',
    secondary10: 'العاشر',
    secondary11: 'الحادي عشر',
    secondary12: 'الثاني عشر',
  };

  // ==================== Reverse Maps (Arabic to Key) ====================
  /// Reverse mapping: Arabic text to education level key
  static Map<String, String> arabicToEducationLevel = {
    'مرحلة ما قبل الدراسة': educationLevelNone,
    'ما دون عمر الدراسة': educationLevelNone,
    'لا يوجد': educationLevelNone,
    'ابتدائي': educationLevelPrimary,
    'إعدادي': educationLevelMiddle,
    'ثانوي': educationLevelSecondary,
    'جامعي': educationLevelUniversity,
    'كلية': educationLevelCollege,
    'لا يدرس': educationLevelNotStudying,
  };

  /// Reverse mapping: Arabic text to university year key
  static Map<String, String> arabicToUniversityYear = {
    'السنة الأولى': year1,
    'السنة الثانية': year2,
    'السنة الثالثة': year3,
    'السنة الرابعة': year4,
    'السنة الخامسة': year5,
    'السنة السادسة': year6,
    'خريج': yearGraduate,
  };

  /// Reverse mapping: Arabic text to school class key
  static Map<String, String> arabicToSchoolClass = {
    'الأول': primary1,
    'الثاني': primary2,
    'الثالث': primary3,
    'الرابع': primary4,
    'الخامس': primary5,
    'السادس': primary6,
    'السابع': middle7,
    'الثامن': middle8,
    'التاسع': middle9,
    'العاشر': secondary10,
    'الحادي عشر': secondary11,
    'الثاني عشر': secondary12,
  };

  // ==================== Validation & Error Messages ====================
  /// Dialog title: Add new country
  static const String dialogAddCountry = 'إضافة دولة جديدة';

  /// Dialog title: Edit country code
  static const String dialogEditCountry = 'تعديل رقم الدولة';

  /// Dialog title: Add new city
  static const String dialogAddCity = 'إضافة مدينة جديدة';

  /// Dialog button: Cancel
  static const String btnCancel = 'إلغاء';

  /// Dialog button: Add
  static const String btnAdd = 'إضافة';

  /// Dialog button: Save
  static const String btnSave = 'حفظ';

  /// Dialog button: Update
  static const String btnUpdate = 'تحديث';

  /// Error: Please fill required fields
  static const String errFillRequired = 'يرجى ملء الحقول المطلوبة';

  /// Success: Country added successfully
  static const String successCountryAdded = 'تمت إضافة الدولة بنجاح';

  /// Success: City added successfully
  static const String successCityAdded = 'تمت إضافة المدينة بنجاح';

  /// Success: Certificate uploaded
  static const String successCertUploaded = 'تم تحميل الشهادة بنجاح';

  /// Success: Medical report added
  static const String successMedicalAdded = 'تقرير طبي مضاف بنجاح';

  /// Success: Image added
  static const String successImageAdded = 'صورة مضافة بنجاح';

  /// Success: Certificate added
  static const String successCertificateAdded = 'شهادة مضافة بنجاح';

  /// Success: Child saved successfully
  static const String successChildSaved = 'تم حفظ بيانات اليتم بنجاح';

  /// Success: Draft saved
  static const String successDraftSaved = 'تم حفظ المسودة بنجاح';

  /// Success: Country code updated
  static const String successCountryCodeUpdated =
      'تم تحديث رقم الدولة وجميع أكواد الأيتام بنجاح';

  /// Error: Select country first
  static const String errSelectCountryFirst = 'يرجى اختيار الدولة أولاً';

  /// Error: Country code required
  static const String errCountryCodeRequired = 'يرجى إدخال رقم الدولة';

  /// Error: Country code must be two digits
  static const String errCountryCodeTwoDigits =
      'يجب أن يكون الرقم مكوناً من رقمين';

  /// Error: First name required
  static const String errFirstNameRequired = 'الاسم الأول مطلوب';

  /// Error: Family name required
  static const String errFamilyNameRequired = 'اسم العائلة مطلوب';

  /// Error: National ID required
  static const String errNationalIdRequired = 'رقم هوية اليتم مطلوب';

  /// Error: National ID must be numbers only
  static const String errNationalIdNumbersOnly =
      'رقم الهوية يجب أن يحتوي على أرقام فقط';

  /// Error: Child already registered with this ID
  static const String errChildIdExists = 'اليتم برقم الهوية هذا مسجل مسبقاً';

  /// Error: Child already registered with this Name or ID
  static const String errChildAlreadyRegistered =
      'تم إضافة اليتيم مسبقاً (الاسم أو رقم الهوية موجود بالفعل)';

  /// Error: Disability description required
  static const String errDisabilityRequired = 'يرجى وصف الإعاقة';

  /// Error: At least one document required
  static const String errDocumentRequired = 'يرجى تحميل وثيقة واحدة على الأقل';

  /// Error: File system error
  static const String errFileSystem = 'خطأ في نظام الملفات: ';

  /// Error: Unable to locate saved child
  static const String errChildNotLocated = 'لم يتم العثور على بيانات اليتم';

  /// Error: File not found
  static const String errFileNotFound = 'الملف غير موجود';

  /// Error: Please enter sibling name
  static const String errSiblingNameRequired = 'يرجى إدخال اسم الأخ/الأخت';

  /// Dialog title: Confirm delete
  static const String dialogConfirmDelete = 'تأكيد الحذف';

  /// Message: Confirm document deletion
  static const String msgConfirmDeleteDocument =
      'هل أنت متأكد من رغبتك في حذف هذه الوثيقة؟';

  /// Button: Delete
  static const String btnDelete = 'حذف';

  /// Dialog title: Add sibling
  static const String dialogAddSibling = 'إضافة أخ/أخت';

  /// Dialog title: Edit sibling
  static const String dialogEditSibling = 'تعديل بيانات أخ/أخت';

  /// Label: Sibling name
  static const String labelSiblingName = 'اسم الأخ/الأخت *';

  /// Label: National ID
  static const String labelNationalId = 'رقم الهوية';

  /// Label: Date of birth
  static const String labelDateOfBirth = 'تاريخ الميلاد';

  /// Label: Is sponsored
  static const String labelIsSponsored = 'هل يحصل على دعم';

  /// Label: Country code
  static const String labelCountryCode = 'رقم الدولة';

  /// Label: Arabic name
  static const String labelArabicName = 'الاسم بالعربية';

  /// Label: English name
  static const String labelEnglishName = 'الاسم بالإنجليزية';

  /// Label: Turkish name
  static const String labelTurkishName = 'الاسم بالتركية';

  /// Helper text: Two digit country code
  static const String helperCountryCode =
      'أدخل رقماً من رقمين (مثال: 01, 02, 03)';

  /// Helper text: Numbers only
  static const String hintNumbersOnly = 'أرقام فقط';

  /// Helper text: Numbers only
  static const String helperNumbersOnly = 'أرقام فقط';

  /// Info: Country code will update all children
  static const String infoCountryCodeWillUpdate =
      'سيتم تحديث جميع أكواد الأيتام المرتبطة بهذه الدولة تلقائياً';

  /// Image crop toolbar title
  static const String cropToolbarTitle = 'قص الصورة';

  // ==================== Utility Methods ====================

  /// Convert education level key to Arabic text
  static String getEducationLevelArabic(String? key) {
    if (key == null) return '';
    return educationLevelToArabic[key] ?? 'ما دون عمر الدراسة';
  }

  /// Convert university year key to Arabic text
  static String getUniversityYearArabic(String? key) {
    if (key == null) return '';
    return universityYearToArabic[key] ?? '';
  }

  /// Convert Arabic text to education level key
  static String getEducationLevelKey(String? arabicText) {
    if (arabicText == null) return educationLevelNone;
    return arabicToEducationLevel[arabicText] ?? educationLevelNone;
  }

  /// Convert Arabic text to university year key
  static String getUniversityYearKey(String? arabicText) {
    if (arabicText == null) return '';
    return arabicToUniversityYear[arabicText] ?? '';
  }

  /// Convert school class key to Arabic text
  static String getSchoolClassArabic(String? key) {
    if (key == null) return '';
    return schoolClassToArabic[key] ?? '';
  }

  /// Convert Arabic text to school class key
  static String getSchoolClassKey(String? arabicText) {
    if (arabicText == null) return '';
    return arabicToSchoolClass[arabicText] ?? '';
  }

  /// Comment from calculateEducationLevelFromAge
  static const String commentEducationAge = '''
  حساب المستوى التعليمي من تاريخ الميلاد
  0-4: مادون سن الدراسة
  6-12: ابتدائي
  13-14: إعدادي
  15-17: ثانوي
  18+: جامعي
  ''';

  // ==================== Localization Methods ====================

  /// Get Arabic label for any field
  static String getFieldLabel(String fieldName) {
    final labels = {
      'countryCode': 'رقم الدولة',
      'arabicName': 'الاسم بالعربية',
      'englishName': 'الاسم بالإنجليزية',
      'turkishName': 'الاسم بالتركية',
      'siblingName': 'اسم الأخ/الأخت',
      'nationalId': 'رقم الهوية',
      'dateOfBirth': 'تاريخ الميلاد',
      'firstName': 'الاسم الأول',
      'familyName': 'اسم العائلة',
      'disability': 'نوع الإعاقة',
      'document': 'المرفق',
      'isSponsored': 'هل يحصل على دعم',
    };
    return labels[fieldName] ?? fieldName;
  }

  /// Get Arabic helper/hint text for fields
  static String getFieldHint(String fieldName) {
    final hints = {
      'countryCode': 'أدخل رقماً من رقمين (مثال: 01, 02, 03)',
      'numbersOnly': 'أرقام فقط',
      'selectDate': 'اختر التاريخ',
      'cropImage': 'قص الصورة',
    };
    return hints[fieldName] ?? '';
  }

  /// Format error messages with dynamic content
  static String formatErrorMessage(String errorType, {String? value}) {
    switch (errorType) {
      case 'fieldRequired':
        return 'حقل "${value ?? 'غير محدد'}" مطلوب';
      case 'invalidFormat':
        return 'صيغة "${value ?? 'البيانات'}" غير صحيحة';
      case 'numberOnly':
        return 'يجب إدخال أرقام فقط في "${value ?? 'الحقل'}"';
      case 'duplicateEntry':
        return 'البيانات "${value ?? 'المدخلة'}" موجودة بالفعل';
      case 'fileSystemError':
        return 'خطأ في نظام الملفات: $value';
      case 'genericError':
        return 'خطأ: $value';
      case 'saveFailed':
        return 'فشل الحفظ: $value';
      case 'updateFailed':
        return 'فشل التحديث: $value';
      case 'fileSave':
        return 'خطأ في حفظ الملف: $value';
      case 'imageCrop':
        return 'خطأ في قص الصورة: $value';
      case 'draftSave':
        return 'خطأ في حفظ المسودة: $value';
      case 'submitFailed':
        return 'فشل إرسال النموذج: $value';
      case 'reportGeneration':
        return 'خطأ في إنشاء التقرير: $value';
      case 'validation':
        return 'خطأ في التحقق: $value';
      default:
        return 'حدث خطأ: $value';
    }
  }

  /// Format success messages
  static String formatSuccessMessage(String messageType, {String? itemName}) {
    switch (messageType) {
      case 'added':
        return 'تم إضافة ${itemName ?? "العنصر"} بنجاح';
      case 'updated':
        return 'تم تحديث ${itemName ?? "البيانات"} بنجاح';
      case 'saved':
        return 'تم حفظ ${itemName ?? "البيانات"} بنجاح';
      case 'deleted':
        return 'تم حذف ${itemName ?? "العنصر"} بنجاح';
      case 'uploaded':
        return 'تم تحميل ${itemName ?? "الملف"} بنجاح';
      default:
        return 'تم الانتهاء بنجاح';
    }
  }

  /// Get confirmation dialogs messages
  static String getConfirmationMessage(String action) {
    final messages = {
      'delete': 'هل أنت متأكد من رغبتك في الحذف؟',
      'save': 'هل تريد حفظ البيانات الحالية؟',
      'discard': 'هل تريد تجاهل التغييرات؟',
      'overwrite': 'هل تريد استبدال البيانات الحالية؟',
    };
    return messages[action] ?? 'هل أنت متأكد؟';
  }

  /// Get validation feedback messages
  static String getValidationFeedback(String validationType, {String? detail}) {
    switch (validationType) {
      case 'emptyField':
        return 'يرجى ملء "${detail ?? 'الحقل المطلوب'}"';
      case 'shortInput':
        return '"${detail ?? 'المدخل'}" قصير جداً';
      case 'longInput':
        return '"${detail ?? 'المدخل'}" طويل جداً';
      case 'invalidEmail':
        return 'البريد الإلكتروني غير صحيح';
      case 'invalidPhone':
        return 'رقم الهاتف غير صحيح';
      case 'passwordMismatch':
        return 'كلمات المرور غير متطابقة';
      case 'ageNotValid':
        return 'العمر غير صحيح';
      default:
        return 'البيانات المدخلة غير صحيحة';
    }
  }

  /// Get operation status messages
  static String getOperationStatus(String status, {String? detail}) {
    switch (status) {
      case 'loading':
        return 'جاري التحميل...';
      case 'processing':
        return 'جاري المعالجة...';
      case 'saving':
        return 'جاري الحفظ...';
      case 'uploading':
        return 'جاري التحميل...';
      case 'deleting':
        return 'جاري الحذف...';
      case 'updating':
        return 'جاري التحديث...';
      case 'completed':
        return 'تم الانتهاء${detail != null ? " - $detail" : ""}';
      case 'failed':
        return 'فشلت العملية${detail != null ? " - $detail" : ""}';
      case 'cancelled':
        return 'تم الإلغاء';
      default:
        return 'حالة غير معروفة';
    }
  }

  /// Get placeholder text for input fields
  static String getFieldPlaceholder(String fieldType) {
    final placeholders = {
      'name': 'أدخل الاسم',
      'email': 'أدخل البريد الإلكتروني',
      'phone': 'أدخل رقم الهاتف',
      'address': 'أدخل العنوان',
      'notes': 'أدخل الملاحظات',
      'search': 'ابحث...',
      'code': 'أدخل الرمز',
      'date': 'اختر التاريخ',
    };
    return placeholders[fieldType] ?? 'أدخل البيانات';
  }

  /// Get filter/category labels
  static String getCategoryLabel(String category) {
    final categories = {
      'all': 'الكل',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'pending': 'قيد الانتظار',
      'completed': 'مكتمل',
      'archive': 'الأرشيف',
      'draft': 'مسودة',
      'published': 'منشور',
    };
    return categories[category] ?? category;
  }

  /// Get time-related labels
  static String getTimeLabel(String timeType) {
    final times = {
      'today': 'اليوم',
      'yesterday': 'أمس',
      'thisWeek': 'هذا الأسبوع',
      'thisMonth': 'هذا الشهر',
      'thisYear': 'هذا العام',
      'allTime': 'كل الوقت',
      'recent': 'الأخيرة',
    };
    return times[timeType] ?? timeType;
  }

  /// Get gender/relationship labels
  static String getGenderLabel(String gender) {
    final genders = {
      'male': 'ذكر',
      'female': 'أنثى',
      'other': 'آخر',
      'M': 'ذكر',
      'F': 'أنثى',
    };
    return genders[gender] ?? gender;
  }

  /// Get relationship type labels
  static String getRelationshipLabel(String relationship) {
    final relationships = {
      'father': 'الأب',
      'mother': 'الأم',
      'brother': 'الأخ',
      'sister': 'الأخت',
      'uncle': 'العم',
      'aunt': 'العمة',
      'grandfather': 'الجد',
      'grandmother': 'الجدة',
      'guardian': 'الوصي',
      'sponsor': 'الراعي',
      'Uncle': 'العم',
      'Aunt': 'العمة',
      'Brother': 'الأخ',
      'Sister': 'الأخت',
      'Other': 'آخر',
    };
    return relationships[relationship] ?? relationship;
  }

  /// Get health status labels
  static String getHealthStatusLabel(String status) {
    final statuses = {
      'healthy': 'سليم',
      'Healthy': 'سليم',
      'sick': 'مريض',
      'Sick': 'مريض',
      'disabled': 'معاق',
      'Disabled': 'معاق',
      'chronic': 'مرض مزمن',
      'recovering': 'في طور التعافي',
    };
    return statuses[status] ?? status;
  }

  /// Get parent status labels
  static String getParentStatusLabel(String status) {
    final statuses = {
      'alive': 'حي',
      'Alive': 'حي',
      'deceased': 'متوفى',
      'Deceased': 'متوفى',
      'unknown': 'غير معروف',
      'Unknown': 'غير معروف',
      'separated': 'منفصل',
    };
    return statuses[status] ?? status;
  }

  /// Get sponsor type labels
  static String getSponsorTypeLabel(String type) {
    final types = {
      'monthly': 'شهري',
      'Monthly': 'شهري',
      'yearly': 'سنوي',
      'Yearly': 'سنوي',
      'oneTime': 'لمرة واحدة',
      'temporary': 'مؤقت',
      'permanent': 'دائم',
    };
    return types[type] ?? type;
  }

  /// Get currency labels
  static String getCurrencyLabel(String currency) {
    final currencies = {
      'شيكل': 'شيكل فلسطيني',
      'دولار': 'دولار أمريكي',
      'دينار': 'دينار أردني',
      'يورو': 'يورو',
      'ILS': 'شيكل فلسطيني',
      'USD': 'دولار أمريكي',
      'JOD': 'دينار أردني',
      'EUR': 'يورو',
    };
    return currencies[currency] ?? currency;
  }

  /// Get document type labels
  static String getDocumentTypeLabel(String docType) {
    final types = {
      'id': 'هوية',
      'passport': 'جواز سفر',
      'birth': 'شهادة ميلاد',
      'school': 'شهادة مدرسية',
      'medical': 'تقرير طبي',
      'photo': 'صورة شخصية',
      'certificate': 'شهادة',
      'other': 'أخرى',
    };
    return types[docType] ?? docType;
  }

  /// Get system messages
  static String getSystemMessage(
    String messageKey, {
    Map<String, String>? params,
  }) {
    final messages = {
      'noData': 'لا توجد بيانات',
      'noResults': 'لم يتم العثور على نتائج',
      'serverError': 'خطأ في الخادم. يرجى المحاولة لاحقاً',
      'networkError': 'خطأ في الاتصال. تأكد من اتصالك بالإنترنت',
      'unauthorized': 'غير مصرح. يرجى تسجيل الدخول',
      'forbidden': 'لا لديك صلاحيات للقيام بهذا الإجراء',
      'notFound': 'لم يتم العثور على البيانات المطلوبة',
      'timeout': 'انتهت مهلة الانتظار. يرجى المحاولة مجدداً',
      'unknown': 'حدث خطأ غير متوقع',
      'retrying': 'جاري إعادة المحاولة...',
      'offline': 'أنت غير متصل بالإنترنت',
    };
    return messages[messageKey] ?? messageKey;
  }

  /// Format detailed error with context
  static String formatDetailedError(
    String errorCode, {
    String? context,
    dynamic value,
  }) {
    String baseMessage = '';
    switch (errorCode) {
      case '400':
        baseMessage = 'طلب غير صحيح';
        break;
      case '401':
        baseMessage = 'غير مصرح';
        break;
      case '403':
        baseMessage = 'لا توجد صلاحيات';
        break;
      case '404':
        baseMessage = 'لم يتم العثور على البيانات';
        break;
      case '500':
        baseMessage = 'خطأ في الخادم';
        break;
      case '503':
        baseMessage = 'الخدمة غير متاحة حالياً';
        break;
      default:
        baseMessage = 'خطأ: $errorCode';
    }

    if (context != null) {
      baseMessage += ' ($context)';
    }
    if (value != null) {
      baseMessage += ' - $value';
    }

    return baseMessage;
  }

  /// Get empty state messages
  static String getEmptyStateMessage(String stateType) {
    final messages = {
      'noChildren': 'لا توجد أيتام مسجلة',
      'noSponsors': 'لا يوجد رعاة',
      'noDocuments': 'لا توجد مرفقات',
      'noDrafts': 'لا توجد مسودات',
      'noSearchResults': 'لم يتم العثور على نتائج البحث',
      'noPayments': 'لا توجد عمليات دفع مسجلة',
      'noHistory': 'لا يوجد سجل',
      'empty': 'فارغ',
    };
    return messages[stateType] ?? 'لا توجد بيانات';
  }

  // ==================== Registration Form Specific Methods ====================

  /// Get step titles for registration form
  static String getStepTitle(int step) {
    final titles = {
      0: 'المعلومات الأساسية والعائلية',
      1: 'التعليم والصحة',
      2: 'المرفقات',
      3: 'الرعاية والدعم',
      4: 'المدفوعات',
      5: 'التقارير',
    };
    return titles[step] ?? 'الخطوة $step';
  }

  /// Get step descriptions
  static String getStepDescription(int step) {
    final descriptions = {
      0: 'أدخل المعلومات الأساسية والعائلية للطفل',
      1: 'أدخل معلومات التعليم والحالة الصحية',
      2: 'أرفق المرفقات والشهادات المطلوبة',
      3: 'أضف معلومات الراعي والدعم',
      4: 'سجل المدفوعات والمساهمات',
      5: 'عرض التقارير والإحصائيات',
    };
    return descriptions[step] ?? '';
  }

  /// Get input field labels for registration form
  static String getRegistrationFieldLabel(String fieldKey) {
    final labels = {
      'firstName': 'الاسم الأول *',
      'lastName': 'اسم العائلة *',
      'fatherName': 'اسم الأب',
      'motherName': 'اسم الأم',
      'grandfatherName': 'اسم الجد',
      'birthDate': 'تاريخ الميلاد *',
      'gender': 'الجنس',
      'nationalId': 'رقم الهوية *',
      'childId': 'رقم اليتم',
      'country': 'الدولة *',
      'city': 'المدينة',
      'address': 'العنوان',
      'street': 'الشارع',
      'phone': 'رقم الهاتف',
      'schoolLevel': 'مستوى التعليم',
      'schoolName': 'اسم المدرسة',
      'schoolClass': 'الفصل الدراسي',
      'grade': 'الدرجة',
      'university': 'الجامعة',
      'universityYear': 'السنة الجامعية',
      'disability': 'نوع الإعاقة',
      'healthStatus': 'الحالة الصحية',
      'notes': 'ملاحظات',
      'sponsorName': 'اسم الراعي',
      'sponsorPhone': 'هاتف الراعي',
      'sponsorAmount': 'المبلغ المدعوم',
      'documents': 'المرفقات',
    };
    return labels[fieldKey] ?? fieldKey;
  }

  /// Get input field hints for registration form
  static String getRegistrationFieldHint(String fieldKey) {
    final hints = {
      'firstName': 'أدخل الاسم الأول للطفل',
      'lastName': 'أدخل اسم العائلة',
      'birthDate': 'اختر تاريخ الميلاد',
      'nationalId': 'أدخل رقم الهوية (أرقام فقط)',
      'phone': 'أدخل رقم الهاتف',
      'address': 'أدخل العنوان الكامل',
      'schoolName': 'اسم المدرسة أو المؤسسة التعليمية',
      'notes': 'أضف أي ملاحظات إضافية...',
      'sponsorName': 'اسم الشخص أو المؤسسة الداعمة',
      'sponsorAmount': 'المبلغ المخصص للدعم الشهري',
    };
    return hints[fieldKey] ?? '';
  }

  /// Get validation messages for registration form fields
  static String getRegistrationValidationMessage(
    String fieldKey,
    String validationType,
  ) {
    final validations = {
      'firstName_empty': 'الاسم الأول مطلوب',
      'firstName_short': 'الاسم قصير جداً (حد أدنى 2 أحرف)',
      'firstName_long': 'الاسم طويل جداً (حد أقصى 50 حرف)',
      'lastName_empty': 'اسم العائلة مطلوب',
      'lastName_short': 'الاسم قصير جداً (حد أدنى 2 أحرف)',
      'lastName_long': 'الاسم طويل جداً (حد أقصى 50 حرف)',
      'birthDate_empty': 'تاريخ الميلاد مطلوب',
      'birthDate_future': 'لا يمكن أن يكون تاريخ الميلاد في المستقبل',
      'birthDate_invalid': 'تاريخ ميلاد غير صحيح',
      'nationalId_empty': 'رقم الهوية مطلوب',
      'nationalId_invalid': 'رقم الهوية يجب أن يحتوي على أرقام فقط',
      'nationalId_short': 'رقم الهوية قصير جداً',
      'nationalId_long': 'رقم الهوية طويل جداً',
      'phone_invalid': 'رقم الهاتف غير صحيح',
      'country_empty': 'يرجى اختيار الدولة',
      'documents_empty': 'يرجى تحميل مرفق واحد على الأقل',
      'disability_required': 'يرجى وصف الإعاقة عند تحديد معاق',
      'sponsorAmount_invalid': 'المبلغ يجب أن يكون أكبر من صفر',
    };
    return validations['${fieldKey}_$validationType'] ?? 'بيانات غير صحيحة';
  }

  /// Get dialog titles for registration form
  static String getRegistrationDialogTitle(String dialogType) {
    final titles = {
      'addCountry': 'إضافة دولة جديدة',
      'editCountry': 'تعديل بيانات الدولة',
      'deleteCountry': 'حذف الدولة',
      'addCity': 'إضافة مدينة جديدة',
      'editCity': 'تعديل بيانات المدينة',
      'deleteCity': 'حذف المدينة',
      'addSibling': 'إضافة أخ/أخت',
      'editSibling': 'تعديل بيانات الأخ/الأخت',
      'deleteSibling': 'حذف الأخ/الأخت',
      'addSponsor': 'إضافة راعي جديد',
      'editSponsor': 'تعديل بيانات الراعي',
      'addPayment': 'إضافة عملية دفع',
      'confirmDelete': 'تأكيد الحذف',
      'confirmSave': 'تأكيد الحفظ',
      'selectImage': 'اختيار صورة',
      'cropImage': 'قص الصورة',
      'uploadDocument': 'تحميل مرفق',
    };
    return titles[dialogType] ?? 'عملية';
  }

  /// Get confirmation messages for registration form
  static String getRegistrationConfirmationMessage(String action) {
    final messages = {
      'deleteChild': 'هل أنت متأكد من رغبتك في حذف بيانات هذا اليتم؟',
      'deleteCountry': 'هل أنت متأكد من رغبتك في حذف هذه الدولة؟',
      'deleteCity': 'هل أنت متأكد من رغبتك في حذف هذه المدينة؟',
      'deleteSibling': 'هل أنت متأكد من رغبتك في حذف بيانات هذا الأخ/الأخت؟',
      'deleteSponsor': 'هل أنت متأكد من رغبتك في حذف هذا الراعي؟',
      'deleteDocument': 'هل أنت متأكد من رغبتك في حذف هذا المرفق؟',
      'saveWithoutChanges': 'لم يتم إجراء أي تغييرات. هل تريد المتابعة؟',
      'leaveForm': 'هل تريد مغادرة النموذج؟ قد تفقد التغييرات غير المحفوظة',
      'submitForm': 'هل أنت متأكد من رغبتك في إرسال البيانات؟',
      'updateChild': 'هل أنت متأكد من رغبتك في تحديث بيانات هذا اليتم؟',
    };
    return messages[action] ?? 'هل أنت متأكد؟';
  }

  /// Get success messages for registration operations
  static String getRegistrationSuccessMessage(
    String operation, {
    String? itemName,
  }) {
    switch (operation) {
      case 'childAdded':
        return 'تم إضافة اليتم بنجاح';
      case 'childUpdated':
        return 'تم تحديث بيانات اليتم بنجاح';
      case 'childDeleted':
        return 'تم حذف اليتم بنجاح';
      case 'countryAdded':
        return 'تم إضافة الدولة بنجاح';
      case 'countryUpdated':
        return 'تم تحديث بيانات الدولة بنجاح';
      case 'countryDeleted':
        return 'تم حذف الدولة بنجاح';
      case 'cityAdded':
        return 'تم إضافة المدينة بنجاح';
      case 'cityUpdated':
        return 'تم تحديث بيانات المدينة بنجاح';
      case 'cityDeleted':
        return 'تم حذف المدينة بنجاح';
      case 'siblingAdded':
        return 'تم إضافة الأخ/الأخت بنجاح';
      case 'siblingUpdated':
        return 'تم تحديث بيانات الأخ/الأخت بنجاح';
      case 'siblingDeleted':
        return 'تم حذف الأخ/الأخت بنجاح';
      case 'sponsorAdded':
        return 'تم إضافة الراعي بنجاح';
      case 'sponsorUpdated':
        return 'تم تحديث بيانات الراعي بنجاح';
      case 'sponsorDeleted':
        return 'تم حذف الراعي بنجاح';
      case 'documentAdded':
        return 'تم إضافة المرفق بنجاح';
      case 'documentDeleted':
        return 'تم حذف المرفق بنجاح';
      case 'paymentAdded':
        return 'تم إضافة عملية الدفع بنجاح';
      case 'paymentDeleted':
        return 'تم حذف عملية الدفع بنجاح';
      case 'formSaved':
        return 'تم حفظ النموذج بنجاح';
      case 'draftSaved':
        return 'تم حفظ المسودة بنجاح';
      case 'formSubmitted':
        return 'تم إرسال النموذج بنجاح';
      case 'reportGenerated':
        return 'تم إنشاء التقرير بنجاح';
      default:
        return 'تمت العملية بنجاح';
    }
  }

  /// Get error messages for registration form
  static String getRegistrationErrorMessage(
    String errorType, {
    String? details,
  }) {
    switch (errorType) {
      case 'saveFailed':
        return 'فشل حفظ البيانات. ${details ?? "يرجى المحاولة مجدداً"}';
      case 'loadFailed':
        return 'فشل تحميل البيانات. ${details ?? "يرجى المحاولة مجدداً"}';
      case 'deleteFailed':
        return 'فشل حذف البيانات. ${details ?? "يرجى المحاولة مجدداً"}';
      case 'uploadFailed':
        return 'فشل تحميل الملف. ${details ?? "يرجى المحاولة مجدداً"}';
      case 'networkError':
        return 'خطأ في الاتصال بالإنترنت. تأكد من الاتصال';
      case 'serverError':
        return 'خطأ في الخادم. يرجى المحاولة لاحقاً';
      case 'validation':
        return 'خطأ في التحقق من البيانات. ${details ?? "تحقق من المدخلات"}';
      case 'duplicate':
        return 'البيانات المدخلة موجودة بالفعل. ${details ?? ""}';
      case 'notFound':
        return 'البيانات المطلوبة غير موجودة';
      case 'unauthorized':
        return 'لا لديك صلاحيات كافية لإجراء هذه العملية';
      case 'fileNotFound':
        return 'الملف غير موجود أو قد تم حذفه';
      case 'invalidFormat':
        return 'صيغة البيانات غير صحيحة. ${details ?? ""}';
      default:
        return 'حدث خطأ غير متوقع. ${details ?? "يرجى المحاولة لاحقاً"}';
    }
  }

  /// Get button labels for registration form
  static String getRegistrationButtonLabel(String buttonType) {
    final labels = {
      'save': 'حفظ',
      'submit': 'إرسال',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'update': 'تحديث',
      'next': 'التالي',
      'previous': 'السابق',
      'finish': 'إنهاء',
      'continue': 'متابعة',
      'clear': 'مسح',
      'reset': 'إعادة تعيين',
      'search': 'بحث',
      'filter': 'تصفية',
      'export': 'تصدير',
      'print': 'طباعة',
      'download': 'تحميل',
      'upload': 'رفع',
      'selectImage': 'اختيار صورة',
      'takePhoto': 'التقاط صورة',
      'cropImage': 'قص الصورة',
      'removeImage': 'إزالة الصورة',
      'addMore': 'إضافة المزيد',
      'removeAll': 'إزالة الكل',
    };
    return labels[buttonType] ?? buttonType;
  }

  /// Get placeholder text for registration form fields
  static String getRegistrationPlaceholder(String fieldKey) {
    final placeholders = {
      'firstName': 'مثال: محمد',
      'lastName': 'مثال: أحمد',
      'fatherName': 'مثال: علي محمود',
      'motherName': 'مثال: فاطمة علي',
      'phone': '+970-59-1234567',
      'email': 'example@example.com',
      'notes': 'أضف أي ملاحظات إضافية هنا...',
      'address': 'مثال: شارع النيل، القاهرة',
      'searchQuery': 'ابحث عن...',
      'sponsorName': 'اسم الراعي أو المؤسسة',
    };
    return placeholders[fieldKey] ?? '';
  }

  /// Get informational messages
  static String getInfoMessage(String infoType) {
    final messages = {
      'countryCodeUpdate':
          'سيتم تحديث جميع أكواد الأيتام المرتبطة بهذه الدولة تلقائياً',
      'requiredFields': 'الحقول المشار إليها بـ (*) مطلوبة',
      'autoSave': 'يتم حفظ البيانات تلقائياً',
      'unsavedChanges': 'توجد تغييرات غير محفوظة',
      'loadingData': 'جاري تحميل البيانات...',
      'noInternet': 'لا توجد اتصال إنترنت. ستعمل التطبيق بدون اتصال',
      'dataSaved': 'تم حفظ البيانات على الجهاز',
      'selectAtLeastOne': 'يجب اختيار عنصر واحد على الأقل',
      'maxFilesReached': 'تم الوصول للحد الأقصى من الملفات',
      'fileSize': 'حجم الملف يتجاوز الحد الأقصى المسموح',
    };
    return messages[infoType] ?? '';
  }
}
