# نظام إدارة اليتامى - Orphan Management System

تطبيق سطح مكتب Flutter متقدم لإدارة سجلات الأطفال اليتامى مع دعم كامل للمزامنة السحابية.

A comprehensive Flutter desktop application for managing orphan records with full cloud synchronization support.

## الميزات الرئيسية / Main Features

### 📋 إدارة السجلات / Record Management

- ✅ إنشاء وتعديل وحذف سجلات الأطفال
- ✅ تتبع المعلومات الشخصية (الاسم، تاريخ الميلاد، الحالة الصحية)
- ✅ تسجيل حالة الوالدين (متوفي/حي) مع تواريخ الوفاة
- ✅ رفع الشهادات والوثائق المختلفة

### 📸 إدارة الصور / Image Management

- ✅ صورة شخصية للطفل
- ✅ صور الهوية (الأم والوصي)
- ✅ شهادات الوفاة (الأب والأم)
- ✅ دعم الحفظ المحلي والسحابي

### 🌐 المزامنة السحابية / Cloud Synchronization

- ✅ تحميل البيانات والصور إلى السحابة
- ✅ تنزيل البيانات من السحابة
- ✅ نسخ احتياطية كاملة
- ✅ التحقق من الاتصال بالإنترنت
- ℹ️ [اقرأ دليل المزامنة السحابية](./CLOUD_SYNC_GUIDE.md)

### 🗄️ قاعدة البيانات / Database

- ✅ SQLite محلي لتخزين البيانات
- ✅ دعم PostgreSQL على الخادم البعيد
- ✅ مزامنة تلقائية بين المحلي والسحابة

### 🌍 اللغات المدعومة / Supported Languages

- 🇸🇦 العربية (Arabic)
- 🇬🇧 English
- 🇹🇷 Türkçe (Turkish)

### 📚 إدارة التعليم / Education Management

- ✅ 6 مستويات تعليمية مع وقت ديناميكي
- ✅ تحميل شهادات التعليم

### 👨‍👩‍👧 إدارة الكفلاء / Sponsorship Management

- ✅ إضافة وإدارة الكفلاء
- ✅ تتبع المستحقات الشهرية
- ✅ تقارير شهرية

## البنية / Project Structure

```
lib/
├── main.dart                 # نقطة الدخول الرئيسية
├── models/                   # نماذج البيانات
│   ├── child.dart           # نموذج اليتيم
│   ├── document.dart        # نموذج الوثيقة
│   └── sponsor.dart         # نموذج الكفيل
├── services/                # خدمات المزامنة والتخزين
│   ├── sqlite_service.dart  # قاعدة البيانات المحلية
│   ├── storage_service.dart # إدارة الملفات
│   ├── api_service.dart     # API الخادم
│   └── cloud_sync_service.dart # المزامنة السحابية ⭐ جديد
├── pages/                   # صفحات التطبيق
│   ├── registration_form.dart
│   ├── children_page.dart
│   ├── cloud_sync_page.dart # صفحة المزامنة السحابية ⭐ جديد
│   └── ...
└── l10n/                    # ملفات الترجمة
    ├── app_en.arb
    ├── app_ar.arb
    └── app_tr.arb

server/                       # خادم Express.js
├── index.js
├── package.json
└── README.md

db/                          # قاعدة البيانات
├── init_orphan_db.sql       # تهيئة قاعدة البيانات
├── migrate_json_to_pg.py    # نقل البيانات من JSON
└── README.md
```

## المتطلبات / Requirements

- **Flutter SDK**: >= 3.0.0
- **Dart SDK**: >= 2.18.0
- **Node.js**: >= 14.0 (للخادم)
- **PostgreSQL**: >= 12.0 (اختياري)
- **Windows**: Windows 10/11 (للتطبيق)

## التثبيت / Installation

### 1. إعداد Flutter

```bash
flutter pub get
```

### 2. إعداد الخادم (اختياري)

```bash
cd server
npm install
cp .env.example .env
# حرر .env وأدخل بيانات قاعدة البيانات
npm run dev
```

### 3. إعداد قاعدة البيانات

```bash
# استخدم pgAdmin أو بديل
psql -U postgres -d orphan_db -f db/init_orphan_db.sql
```

## التشغيل / Running

### تشغيل التطبيق

```bash
flutter run -d windows
```

### بناء التطبيق

```bash
flutter build windows
```

### تشغيل الخادم

```bash
cd server
npm run dev      # تطوير
npm run build    # بناء
npm start        # إنتاج
```

## الاستخدام / Usage

### تحميل بيانات إلى السحابة

1. افتح التطبيق
2. انقر على **"Cloud Sync"** من القائمة الجانبية
3. اختر الأطفال المراد تحميلهم
4. انقر **"تحميل المختارة"**

### تنزيل البيانات من السحابة

1. افتح **"Cloud Sync"**
2. انقر **"تنزيل الكل"**

### إنشاء نسخة احتياطية

1. افتح **"Cloud Sync"**
2. انقر **"نسخة احتياطية"**

## اقتراحات النمو / Growth Roadmap

- [ ] **قائمة الانتظار (Offline Queue)** - حفظ التحديثات عند انقطاع الإنترنت
- [ ] **ضغط الصور (Image Compression)** - تقليل حجم الصور تلقائياً
- [ ] **المزامنة التلقائية (Auto Sync)** - مزامنة دورية في الخلفية
- [ ] **تشفير البيانات (Encryption)** - تشفير معلومات حساسة
- [ ] **المصادقة (Authentication)** - تسجيل دخول آمن
- [ ] **صلاحيات الوصول (Permissions)** - إدارة صلاحيات المستخدمين
- [ ] **التقارير المتقدمة (Advanced Reports)** - تقارير تحليلية متقدمة
- [ ] **التطبيق المحمول (Mobile App)** - دعم iOS و Android

## المساهمة / Contributing

نرحب بالمساهمات! يرجى:

1. Fork المستودع
2. أنشئ فرع جديد (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push إلى الفرع (`git push origin feature/AmazingFeature`)
5. افتح Pull Request

## الترخيص / License

هذا المشروع مرخص تحت MIT License.

## الدعم / Support

للمساعدة والدعم:

- 📧 البريد الإلكتروني: support@orphan-system.local
- 📝 الإبلاغ عن الأخطاء: [GitHub Issues](../../issues)
- 📚 الوثائق: [اقرأ الدليل الكامل](./CLOUD_SYNC_GUIDE.md)

---

**آخر تحديث:** 2024
**الإصدار:** 1.0 (بميزات مزامنة سحابية)
