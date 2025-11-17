# Orphan App - Local Database Setup

## نظرة عامة
تم تكوين تطبيق Orphan Flutter لاستخدام قاعدة بيانات محلية **SQLite** بدلاً من قاعدة بيانات سحابية.

## المكتبات المستخدمة
- **sqflite**: مكتبة SQLite لـ Flutter
- **sqflite_common_ffi**: دعم FFI لـ SQLite على سطح المكتب والويب

## الملفات المضافة

### 1. `lib/services/database_service.dart`
خدمة قاعدة البيانات التي توفر:
- **إنشاء وتهيئة قاعدة البيانات** (`_initDatabase`, `_onCreate`)
- **عمليات CRUD على الأطفال**:
  - `insertChild()` - إضافة طفل جديد
  - `getAllChildren()` - جلب جميع الأطفال
  - `getChild()` - جلب طفل محدد بـ ID
  - `updateChild()` - تحديث بيانات الطفل
  - `deleteChild()` - حذف طفل
  - `searchChildren()` - البحث عن أطفال بالاسم

### 2. جداول قاعدة البيانات

#### جدول `children`
يحتوي على معلومات الأطفال:
```sql
CREATE TABLE children (
  id TEXT PRIMARY KEY,
  fullName TEXT NOT NULL,
  dateOfBirth TEXT,
  childIdNumber TEXT NOT NULL,
  fatherName TEXT,
  fatherIdNumber TEXT,
  motherName TEXT,
  motherIdNumber TEXT,
  motherStatus TEXT DEFAULT 'Alive',
  healthStatus TEXT DEFAULT 'Healthy',
  disabilityType TEXT,
  siblings TEXT,
  documents TEXT,
  sponsor TEXT,
  createdAt TEXT NOT NULL
)
```

#### جدول `sponsors`
معلومات الكفلاء:
```sql
CREATE TABLE sponsors (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  createdAt TEXT NOT NULL
)
```

#### جدول `documents`
الوثائق المرفوعة:
```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  childId TEXT NOT NULL,
  name TEXT NOT NULL,
  filePath TEXT NOT NULL,
  uploadedAt TEXT NOT NULL,
  FOREIGN KEY (childId) REFERENCES children(id)
)
```

## كيفية الاستخدام

### 1. استيراد الخدمة
```dart
import 'package:orphan/services/database_service.dart';
```

### 2. الحصول على نسخة من الخدمة
```dart
final dbService = DatabaseService();
```

### 3. إضافة طفل جديد
```dart
final child = Child(
  id: 'child-001',
  fullName: 'أحمد محمد',
  dateOfBirth: DateTime(2010, 5, 15),
  childIdNumber: '1234567890',
);
await dbService.insertChild(child);
```

### 4. جلب جميع الأطفال
```dart
final children = await dbService.getAllChildren();
```

### 5. جلب طفل محدد
```dart
final child = await dbService.getChild('child-001');
```

### 6. تحديث بيانات الطفل
```dart
child.fullName = 'أحمد علي محمد';
await dbService.updateChild(child);
```

### 7. حذف طفل
```dart
await dbService.deleteChild('child-001');
```

### 8. البحث عن أطفال
```dart
final results = await dbService.searchChildren('أحمد');
```

## موقع قاعدة البيانات
- **Android**: `/data/data/com.example.orphan/databases/orphan.db`
- **iOS**: `Documents/orphan.db`
- **Windows/macOS**: `AppData/Local/orphan.db` أو `Library/Application Support/orphan.db`

## تثبيت المكتبات
```bash
flutter pub get
```

## ملاحظات مهمة
1. قاعدة البيانات تُنشأ تلقائياً عند أول تشغيل للتطبيق
2. جميع البيانات محفوظة محلياً على الجهاز
3. يمكن إضافة المزيد من الجداول والعمليات حسب الحاجة
4. استخدم `closeDatabase()` عند إغلاق التطبيق

## التطوير المستقبلي
- إضافة عمليات CRUD للكفلاء (Sponsors)
- إضافة عمليات CRUD للوثائق (Documents)
- إضافة عمليات النسخ الاحتياطي والاستعادة
- إضافة تشفير البيانات الحساسة
