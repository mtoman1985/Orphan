// خدمة تحويل الأسماء العربية إلى الإنجليزية والتركية
class MultiLangTransliterator {
  // جدول التحويل من العربية إلى الإنجليزية
  static final Map<String, String> _arabicToEnglish = {
    'ا': 'a',
    'أ': 'a',
    'إ': 'i',
    'آ': 'a', // Changed from aa to a to avoid collapsing issues
    'ب': 'b',
    'ت': 't',
    'ث': 'th',
    'ج': 'j',
    'ح': 'h',
    'خ': 'kh',
    'د': 'd',
    'ذ': 'dh',
    'ر': 'r',
    'ز': 'z',
    'س': 's',
    'ش': 'sh',
    'ص': 's',
    'ض': 'd',
    'ط': 't',
    'ظ': 'z',
    'ع': 'a',
    'غ': 'gh',
    'ف': 'f',
    'ق': 'q',
    'ك': 'k',
    'ل': 'l',
    'م': 'm',
    'ن': 'n',
    'ه': 'h',
    'و': 'w',
    'ي': 'y',
    'ى': 'a',
    'ة': 'a', // Changed from h to a (standard for names like Fatima)
    'ء': '',
    'ئ': 'y',
    'ؤ': 'w',
    'َ': 'a',
    'ِ': 'i',
    'ُ': 'u',
    'ً': 'an',
    'ٍ': 'in',
    'ٌ': 'un',
    'ّ': '',
    'ْ': '',
    'ـ': '', // Kashida (Tatweel) - should be ignored
  };

  // جدول التحويل من العربية إلى التركية
  static final Map<String, String> _arabicToTurkish = {
    'ا': 'a',
    'أ': 'a',
    'إ': 'i',
    'آ': 'a',
    'ب': 'b',
    'ت': 't',
    'ث': 's',
    'ج': 'c',
    'ح': 'h',
    'خ': 'h',
    'د': 'd',
    'ذ': 'z',
    'ر': 'r',
    'ز': 'z',
    'س': 's',
    'ش': 'ş',
    'ص': 's',
    'ض': 'd',
    'ط': 't',
    'ظ': 'z',
    'ع': 'a',
    'غ': 'g',
    'ف': 'f',
    'ق': 'k',
    'ك': 'k',
    'ل': 'l',
    'م': 'm',
    'ن': 'n',
    'ه': 'h',
    'و': 'v',
    'ي': 'y',
    'ى': 'a',
    'ة': 'e',
    'ء': '',
    'ئ': 'y',
    'ؤ': 'v',
    'َ': 'a',
    'ِ': 'i',
    'ُ': 'u',
    'ً': 'an',
    'ٍ': 'in',
    'ٌ': 'un',
    'ّ': '',
    'ْ': '',
    'ـ': '', // Kashida (Tatweel) - should be ignored
  };

  // أسماء شائعة بالإنجليزية
  static final Map<String, String> _commonNamesEnglish = {
    'محمد': 'Muhammad',
    'أحمد': 'Ahmad',
    'علي': 'Ali',
    'حسن': 'Hassan',
    'حسين': 'Hussein',
    'عمر': 'Omar',
    'خالد': 'Khaled',
    'يوسف': 'Yusuf',
    'إبراهيم': 'Ibrahim',
    'عبدالله': 'Abdullah',
    'عبدالرحمن': 'Abdulrahman',
    'سليمان': 'Sulaiman',
    'إسماعيل': 'Ismail',
    'موسى': 'Musa',
    'عيسى': 'Isa',
    'صالح': 'Saleh',
    'طارق': 'Tariq',
    'عبد': 'Abd',
    'الله': 'Allah',
    'الرحمن': 'Rahman',
    'فاطمة': 'Fatima',
    'عائشة': 'Aisha',
    'خديجة': 'Khadija',
    'زينب': 'Zainab',
    'مريم': 'Maryam',
    'سارة': 'Sarah',
    'ليلى': 'Layla',
    'حفصة': 'Hafsa',
    'رقية': 'Ruqayya',
    'أمينة': 'Amina',
    'سمية': 'Sumaya',
    'آسية': 'Asiya',
    'آدم': 'Adam',
    'عرفات': 'Arafat',
    'الفقعاوي': 'Al-Faqawi',
    'محمود': 'Mahmoud',
    'سعيد': 'Said',
    'أنس': 'Anas',
    'حمزة': 'Hamza',
    'زكريا': 'Zakaria',
    'يحيى': 'Yahya',
    'فارس': 'Faris',
    'ريان': 'Rayan',
    'كنان': 'Kenan',
    'زيد': 'Zaid',
    'جنى': 'Jana',
    'لمى': 'Lama',
    'هدى': 'Huda',
    'ندى': 'Nada',
    'رنا': 'Rana',
    'رشا': 'Rasha',
    'نور': 'Nour',
    'هديل': 'Hadeel',
    'إيمان': 'Iman',
    'أمل': 'Amal',
    'حنان': 'Hanan',
    'منال': 'Manal',
    'منى': 'Mona',
    'سناء': 'Sanaa',
    'وفاء': 'Wafaa',
    'صفاء': 'Safaa',
    'علاء': 'Alaa',
    'بهاء': 'Bahaa',
    'فؤاد': 'Fouad',
    'رائد': 'Raed',
    'وائل': 'Wael',
    'نائل': 'Nael',
    'باسل': 'Basel',
    'تامر': 'Tamer',
    'رامي': 'Rami',
    'سامي': 'Sami',
    'شادي': 'Shady',
    'هاني': 'Hany',
    'فادي': 'Fady',
    'أيمن': 'Ayman',
    'أكرم': 'Akram',
    'أمجد': 'Amjad',
    'أشرف': 'Ashraf',
    'أدهم': 'Adham',
    'أسامة': 'Osama',
    'ماجد': 'Majed',
    'وليد': 'Walid',
    'وحيد': 'Wahid',
    'سمير': 'Samir',
    'منير': 'Munir',
    'شريف': 'Sherif',
    'لطفي': 'Lotfi',
    'فتحي': 'Fathi',
    'صبحي': 'Sobhi',
    'حمدي': 'Hamdi',
    'فوزي': 'Fawzi',
    'رمزي': 'Ramzi',
    'عزمي': 'Azmi',
    'رفعت': 'Rifaat',
    'طلعت': 'Talaat',
    'مدحت': 'Medhat',
    'بهجت': 'Bahgat',
    'عصمت': 'Ismat',
    'رأفت': 'Raafat',
    'ثروت': 'Tharwat',
    'صفوت': 'Safwat',
    'نشأت': 'Nashat',
    'عزت': 'Ezzat',
    'حكمت': 'Hikmat',
    'عوكل': 'Awkal',
    'صبح': 'Sobeh',
    'عياش': 'Ayash',
    'سوار': 'Siwar',
    'جود': 'Joud',
    'ليان': 'Layan',
    'سديل': 'Sadeel',
    'رهف': 'Rahaf',
    'رند': 'Rand',
    'راما': 'Rama',
    'تالا': 'Tala',
    'سما': 'Sama',
    'شهد': 'Shahd',
    'ملك': 'Malak',
    'حلا': 'Hala',
    'ميرا': 'Mira',
    'ديالا': 'Diala',
    'بيسان': 'Bisan',
    'ماسة': 'Massa',
    'رودينا': 'Rodina',
    'روفان': 'Rovan',
    'ياسين': 'Yassin',
    'مؤمن': 'Moamen',
    'مخلص': 'Mokhles',
    'رامز': 'Ramez',
    'حجازي': 'Hijazi',
    'منصور': 'Mansour',
    'قدورة': 'Qadoura',
    'عصفور': 'Asfour',
    'كحيل': 'Kahil',
    'بركة': 'Baraka',
    'شعت': 'Shaath',
    'النجار': 'Al-Najjar',
    'أبو': 'Abu',
    'ابو': 'Abu',
    'ابن': 'Ibn',
    'بن': 'Bin',
    'دغمش': 'Doghmosh',
    'حلس': 'Helles',
    'جعفر': 'Jaafar',
    'مطر': 'Matar',
    'بكر': 'Bakr',
    'باقر': 'Baqer',
    'جابر': 'Jaber',
    'صابر': 'Saber',
    'نادر': 'Nader',
    'عامر': 'Amer',
    'عصام': 'Essam',
    'عادل': 'Adel',
    'سفيان': 'Sufian',
    'عطية': 'Attiya',
    'جمعة': 'Jomaa',
    'خميس': 'Khamis',
    'رمضان': 'Ramadan',
    'شعبان': 'Shaaban',
    'رجب': 'Rajab',
    'القدرة': 'Al-Qidra',
    'المصري': 'Al-Masry',
    'عاشور': 'Ashour',
    'البيوك': 'Al-Byouk',
    'شلح': 'Shallah',
    'نصار': 'Nassar',
    'برهوم': 'Barhoum',
    'صلاح': 'Salah',
    'مشتهى': 'Mushtaha',
    'الحية': 'Al-Hayya',
    'الدحدوح': 'Al-Dahdouh',
    'نوفل': 'Nofal',
    'غريب': 'Ghareeb',
    'البطنيجي': 'Al-Batniji',
    'الودية': 'Al-Wadiya',
    'حمد': 'Hamad',
    'عبيد': 'Obeid',
    'سالم': 'Salem',
    'بشر': 'Beshr',
    'المبحوح': 'Al-Mabhouh',
    'زين الدين': 'Zain Al-Din',
    'شهاب': 'Shehab',
    'صياد': 'Sayyad',
    'عوض': 'Awad',
    'هنية': 'Haniya',
    'مشعل': 'Mashal',
    'عباس': 'Abbas',
  };

  // أسماء شائعة بالتركية
  static final Map<String, String> _commonNamesTurkish = {
    'محمد': 'Muhammed',
    'أحمد': 'Ahmet',
    'علي': 'Ali',
    'حسن': 'Hasan',
    'حسين': 'Hüseyin',
    'عمر': 'Ömer',
    'خالد': 'Halid',
    'يوسف': 'Yusuf',
    'إبراهيم': 'İbrahim',
    'عبدالله': 'Abdullah',
    'عبدالرحمن': 'Abdurrahman',
    'سليمان': 'Süleyman',
    'إسماعيل': 'İsmail',
    'موسى': 'Musa',
    'عيسى': 'İsa',
    'صالح': 'Salih',
    'طارق': 'Tarık',
    'عبد': 'Abd',
    'الله': 'Allah',
    'الرحمن': 'Rahman',
    'فاطمة': 'Fatma',
    'عائشة': 'Ayşe',
    'خديجة': 'Hatice',
    'زينب': 'Zeynep',
    'مريم': 'Meryem',
    'سارة': 'Sara',
    'ليلى': 'Leyla',
    'حفصة': 'Hafsa',
    'رقية': 'Rukiye',
    'أمينة': 'Emine',
    'سمية': 'Sümeyye',
    'آسية': 'Asiye',
    'آدم': 'Adem',
    'عرفات': 'Arafat',
    'الفقعاوي': 'El-Faqawi',
    'محمود': 'Mahmud',
    'سعيد': 'Said',
    'أنس': 'Enes',
    'حمزة': 'Hamza',
    'زكريا': 'Zekeriya',
    'يحيى': 'Yahya',
    'فارس': 'Faris',
    'ريان': 'Reyyan',
    'كنان': 'Kenan',
    'زيد': 'Zeyd',
    'جنى': 'Cena',
    'لمى': 'Lema',
    'هدى': 'Hüda',
    'ندى': 'Neda',
    'رنا': 'Rana',
    'رشا': 'Reşa',
    'نور': 'Nur',
    'هديل': 'Hedil',
    'إيمان': 'İman',
    'أمل': 'Emel',
    'حنان': 'Hanan',
    'منال': 'Menal',
    'منى': 'Muna',
    'سناء': 'Sena',
    'وفاء': 'Vefa',
    'صفاء': 'Sefa',
    'علاء': 'Ala',
    'بهاء': 'Baha',
    'فؤاد': 'Fuad',
    'رائد': 'Raid',
    'وائل': 'Vail',
    'نائل': 'Nail',
    'باسل': 'Basıl',
    'تامر': 'Tamer',
    'رامي': 'Rami',
    'سامي': 'Sami',
    'شادي': 'Şadi',
    'هاني': 'Hani',
    'فادي': 'Fadi',
    'أيمن': 'Eymen',
    'أكرم': 'Ekrem',
    'أمجد': 'Emced',
    'أشرف': 'Eşref',
    'أدهم': 'Edhem',
    'أسامة': 'Usame',
    'ماجد': 'Macid',
    'وليد': 'Velid',
    'وحيد': 'Vahid',
    'سمير': 'Semir',
    'منير': 'Münir',
    'شريف': 'Şerif',
    'لطفي': 'Lütfi',
    'فتحي': 'Fethi',
    'صبحي': 'Subhi',
    'حمدي': 'Hamdi',
    'فوزي': 'Fevzi',
    'رمزي': 'Remzi',
    'عزمي': 'Azmi',
    'رفعت': 'Rıfat',
    'طلعت': 'Talat',
    'مدحت': 'Midhat',
    'بهجت': 'Behcet',
    'عصمت': 'Ismet',
    'رأفت': 'Rafet',
    'ثروت': 'Servet',
    'صفوت': 'Saffet',
    'نشأت': 'Neşat',
    'عزت': 'İzzet',
    'حكمت': 'Hikmet',
    'عوكل': 'Avkal',
    'عياش': 'Ayyash',
    'سوار': 'Suvar',
    'جود': 'Cud',
    'ليان': 'Layan',
    'سديل': 'Sedil',
    'رهف': 'Rahaf',
    'رند': 'Rand',
    'راما': 'Rama',
    'تالا': 'Tala',
    'سما': 'Sama',
    'شهد': 'Şehd',
    'ملك': 'Melek',
    'حلا': 'Hala',
    'ميرا': 'Mira',
    'ديالا': 'Diyala',
    'بيسان': 'Bisan',
    'ماسة': 'Masa',
    'رودينا': 'Rodina',
    'روفان': 'Rovan',
    'ياسين': 'Yasin',
    'مؤمن': 'Mümin',
    'مخلص': 'Muhlis',
    'رامز': 'Ramiz',
    'حجازي': 'Hicazi',
    'منصور': 'Mansur',
    'قدورة': 'Kadura',
    'النجار': 'Neccar',
    'أبو': 'Abu',
    'ابو': 'Abu',
    'القدرة': 'Kudra',
    'المصري': 'Mısri',
    'عاشور': 'Aşur',
    'البيت': 'Ebit',
    'كحيل': 'Kahil',
    'شلح': 'Şallah',
    'نصار': 'Nassar',
    'برهوم': 'Barhum',
    'صلاح': 'Salah',
    'مشتهى': 'Müşteha',
    'غريب': 'Garib',
  };

  /// تحويل نص عربي إلى الإنجليزية
  static String toEnglish(String arabicText) {
    if (arabicText.isEmpty) return '';

    final trimmed = arabicText.trim();
    final normalized = _normalizeArabic(arabicText);

    // البحث في الأسماء الشائعة أولاً بالاسم الأصلي أو المنظم
    if (_commonNamesEnglish.containsKey(trimmed)) {
      return _commonNamesEnglish[trimmed]!;
    }
    if (_commonNamesEnglish.containsKey(normalized)) {
      return _commonNamesEnglish[normalized]!;
    }

    String result = normalized;

    // معالجة أل التعريف
    result = result.replaceAll('ال', 'al-');

    // تحويل الأحرف
    _arabicToEnglish.forEach((arabic, english) {
      result = result.replaceAll(arabic, english);
    });

    // تنظيف
    return _cleanResult(result);
  }

  /// تحويل نص عربي إلى التركية
  static String toTurkish(String arabicText) {
    if (arabicText.isEmpty) return '';

    final trimmed = arabicText.trim();
    final normalized = _normalizeArabic(arabicText);

    // البحث في الأسماء الشائعة أولاً
    if (_commonNamesTurkish.containsKey(trimmed)) {
      return _commonNamesTurkish[trimmed]!;
    }
    if (_commonNamesTurkish.containsKey(normalized)) {
      return _commonNamesTurkish[normalized]!;
    }

    String result = normalized;

    // تحويل الأحرف
    _arabicToTurkish.forEach((arabic, turkish) {
      result = result.replaceAll(arabic, turkish);
    });

    // تنظيف
    return _cleanResult(result);
  }

  /// تنظيف النتيجة
  static String _cleanResult(String text) {
    String result = text.trim();

    // إزالة الأحرف المكررة الزائدة (مثل AAA -> AA)
    // لاحظ: لا نحذف المكرر الثنائي لأنه قد يكون مقصوداً في الإنجليزية مثل (ss, ll, oo, ee)
    result = result.replaceAll(RegExp(r'(.)\1{2,}'), r'\1\1');

    // إزالة المسافات المتعددة
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // إزالة أي أحرف غير لاتينية أو غير مسموح بها (بصرف النظر عن المسافات والواصلات والنقاط)
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\.]'), '');

    // جعل الحرف الأول كبير لكل كلمة
    if (result.isNotEmpty) {
      result = result
          .split(' ')
          .map((word) {
            if (word.isEmpty) return '';
            if (word.startsWith('al-')) {
              return 'Al-' +
                  word.substring(3)[0].toUpperCase() +
                  word.substring(3).toLowerCase();
            }
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    return result;
  }

  /// تحقق إذا كان النص عربي
  static bool isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// تنظيف النص العربي من الحركات والتشكيل والكشيدة
  static String _normalizeArabic(String text) {
    String result = text.trim();
    // إزالة التشكيل والحركات
    result = result.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    // إزالة الكشيدة
    result = result.replaceAll('\u0640', '');
    return result;
  }
}
