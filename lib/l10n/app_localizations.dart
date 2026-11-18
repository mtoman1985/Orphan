import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @school.
  ///
  /// In ar, this message translates to:
  /// **'المدرسة'**
  String get school;

  /// No description provided for @siblings_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الإخوة'**
  String get siblings_data;

  /// No description provided for @bank_info.
  ///
  /// In ar, this message translates to:
  /// **'البيانات المالية'**
  String get bank_info;

  /// No description provided for @bank_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم البنك'**
  String get bank_name;

  /// No description provided for @account_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحساب'**
  String get account_number;

  /// No description provided for @iban.
  ///
  /// In ar, this message translates to:
  /// **'الايبان'**
  String get iban;

  /// No description provided for @account_holder.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب الحساب'**
  String get account_holder;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @health_info_title.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الصحية'**
  String get health_info_title;

  /// No description provided for @any_health_problem.
  ///
  /// In ar, this message translates to:
  /// **'هل توجد أي مشكلة صحية:'**
  String get any_health_problem;

  /// No description provided for @health_problem_description.
  ///
  /// In ar, this message translates to:
  /// **'وصف المشكلة الصحية:'**
  String get health_problem_description;

  /// No description provided for @education_info_title.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات التعليمية'**
  String get education_info_title;

  /// No description provided for @education_level_colon.
  ///
  /// In ar, this message translates to:
  /// **'المستوى التعليمي:'**
  String get education_level_colon;

  /// No description provided for @school_name_colon.
  ///
  /// In ar, this message translates to:
  /// **'اسم المدرسة:'**
  String get school_name_colon;

  /// No description provided for @grade_colon.
  ///
  /// In ar, this message translates to:
  /// **'الصف:'**
  String get grade_colon;

  /// No description provided for @home_address_colon.
  ///
  /// In ar, this message translates to:
  /// **'عنوان السكن:'**
  String get home_address_colon;

  /// No description provided for @phone_number_colon.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف:'**
  String get phone_number_colon;

  /// No description provided for @orphan_sponsorship_program.
  ///
  /// In ar, this message translates to:
  /// **'برنامج كفالة الأيتام'**
  String get orphan_sponsorship_program;

  /// No description provided for @orphan_form.
  ///
  /// In ar, this message translates to:
  /// **'استمارة يتيم'**
  String get orphan_form;

  /// No description provided for @orphan_form_title.
  ///
  /// In ar, this message translates to:
  /// **'استمارة اليتم'**
  String get orphan_form_title;

  /// No description provided for @orphan_form_description.
  ///
  /// In ar, this message translates to:
  /// **'استمارة معلومات اليتيم الشاملة'**
  String get orphan_form_description;

  /// No description provided for @father_death_date_colon.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ وفاة الأب'**
  String get father_death_date_colon;

  /// No description provided for @father_death_cause_colon.
  ///
  /// In ar, this message translates to:
  /// **'سبب وفاة الأب'**
  String get father_death_cause_colon;

  /// No description provided for @mother_death_date_colon.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ وفاة الأم'**
  String get mother_death_date_colon;

  /// No description provided for @mother_death_cause_colon.
  ///
  /// In ar, this message translates to:
  /// **'سبب وفاة الأم'**
  String get mother_death_cause_colon;

  /// No description provided for @active_sponsors_label.
  ///
  /// In ar, this message translates to:
  /// **'الكفلاء النشطين'**
  String get active_sponsors_label;

  /// No description provided for @active_status.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active_status;

  /// No description provided for @add_button.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add_button;

  /// No description provided for @add_custom_cause.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سبب مخصص'**
  String get add_custom_cause;

  /// No description provided for @add_new_city.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مدينة جديدة'**
  String get add_new_city;

  /// No description provided for @add_new_country.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دولة جديدة'**
  String get add_new_country;

  /// No description provided for @add_new_currency.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عملة جديدة'**
  String get add_new_currency;

  /// No description provided for @add_new_currency_dialog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عملة جديدة'**
  String get add_new_currency_dialog;

  /// No description provided for @add_new_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل جديد'**
  String get add_new_sponsor;

  /// No description provided for @add_new_sponsor_dialog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل جديد'**
  String get add_new_sponsor_dialog;

  /// No description provided for @add_payment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دفعة'**
  String get add_payment;

  /// No description provided for @add_sibling.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أخ/أخت'**
  String get add_sibling;

  /// No description provided for @add_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل'**
  String get add_sponsor;

  /// No description provided for @add_sponsor_button.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل'**
  String get add_sponsor_button;

  /// No description provided for @add_sponsor_currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get add_sponsor_currency;

  /// No description provided for @add_sponsor_dialog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل'**
  String get add_sponsor_dialog;

  /// No description provided for @add_sponsor_dialog_title.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل'**
  String get add_sponsor_dialog_title;

  /// No description provided for @add_sponsor_end_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء (YYYY-MM-DD)'**
  String get add_sponsor_end_date;

  /// No description provided for @add_sponsor_name_field.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكفيل'**
  String get add_sponsor_name_field;

  /// No description provided for @add_sponsor_start_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية (YYYY-MM-DD)'**
  String get add_sponsor_start_date;

  /// No description provided for @added_siblings.
  ///
  /// In ar, this message translates to:
  /// **'الأخوة المضافون'**
  String get added_siblings;

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age;

  /// No description provided for @age_label.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age_label;

  /// No description provided for @age_years.
  ///
  /// In ar, this message translates to:
  /// **'{age} سنة'**
  String age_years(Object age);

  /// No description provided for @alive.
  ///
  /// In ar, this message translates to:
  /// **'على قيد الحياة'**
  String get alive;

  /// No description provided for @all_basic_data.
  ///
  /// In ar, this message translates to:
  /// **'جميع البيانات الأساسية'**
  String get all_basic_data;

  /// No description provided for @all_children_sponsored_message.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيتام غير مكفولين - جميع الأيتام لديهم كفلاء!'**
  String get all_children_sponsored_message;

  /// No description provided for @all_orphans_report_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الأيتام'**
  String get all_orphans_report_title;

  /// No description provided for @all_sponsors_report_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الكفلاء'**
  String get all_sponsors_report_title;

  /// No description provided for @amount_label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get amount_label;

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأيتام'**
  String get appTitle;

  /// No description provided for @are_you_sure_delete.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف'**
  String get are_you_sure_delete;

  /// No description provided for @aunt.
  ///
  /// In ar, this message translates to:
  /// **'عمة'**
  String get aunt;

  /// No description provided for @basic_information.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الأساسية'**
  String get basic_information;

  /// No description provided for @birth_certificate.
  ///
  /// In ar, this message translates to:
  /// **'شهادة الميلاد'**
  String get birth_certificate;

  /// No description provided for @both_parents_alive_error.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إدخال يتيم إذا كان الأب والأم على قيد الحياة'**
  String get both_parents_alive_error;

  /// No description provided for @birth_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get birth_date;

  /// No description provided for @birth_date_label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get birth_date_label;

  /// No description provided for @brother.
  ///
  /// In ar, this message translates to:
  /// **'أخ'**
  String get brother;

  /// No description provided for @btn_back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get btn_back;

  /// No description provided for @btn_cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get btn_cancel;

  /// No description provided for @btn_continue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get btn_continue;

  /// No description provided for @btn_finish.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get btn_finish;

  /// No description provided for @btn_pdf.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get btn_pdf;

  /// No description provided for @btn_save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get btn_save;

  /// No description provided for @btn_save_draft.
  ///
  /// In ar, this message translates to:
  /// **'حفظ المسودة'**
  String get btn_save_draft;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @cancel_button.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel_button;

  /// No description provided for @change_certificate.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الشهادة'**
  String get change_certificate;

  /// No description provided for @childDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اليتيم'**
  String get childDetails;

  /// No description provided for @child_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف'**
  String get child_deleted;

  /// No description provided for @child_id_code.
  ///
  /// In ar, this message translates to:
  /// **'رمز اليتيم'**
  String get child_id_code;

  /// No description provided for @child_id_label.
  ///
  /// In ar, this message translates to:
  /// **'كود اليتيم'**
  String get child_id_label;

  /// No description provided for @child_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم اليتيم'**
  String get child_name;

  /// No description provided for @child_name_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم اليتيم'**
  String get child_name_label;

  /// No description provided for @child_personal_info.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية للطفل'**
  String get child_personal_info;

  /// No description provided for @child_photo.
  ///
  /// In ar, this message translates to:
  /// **'الصورة الشخصية'**
  String get child_photo;

  /// No description provided for @children.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام'**
  String get children;

  /// No description provided for @childrenLoaded.
  ///
  /// In ar, this message translates to:
  /// **'طفل'**
  String get childrenLoaded;

  /// No description provided for @childrenRecords.
  ///
  /// In ar, this message translates to:
  /// **'سجلات الأيتام'**
  String get childrenRecords;

  /// No description provided for @children_and_amounts_title.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام والمبالغ المدفوعة'**
  String get children_and_amounts_title;

  /// No description provided for @children_records.
  ///
  /// In ar, this message translates to:
  /// **'سجلات الأيتام'**
  String get children_records;

  /// No description provided for @choose_file.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف'**
  String get choose_file;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @close_button.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close_button;

  /// No description provided for @code_label.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get code_label;

  /// No description provided for @complete_orphan_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير تفصيلي كامل عن اليتيم المختار'**
  String get complete_orphan_report;

  /// No description provided for @complete_orphans_list_title.
  ///
  /// In ar, this message translates to:
  /// **'قائمة شاملة بجميع الأيتام المسجلين'**
  String get complete_orphans_list_title;

  /// No description provided for @complete_sponsor_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير تفصيلي كامل عن الكفيل المختار'**
  String get complete_sponsor_report;

  /// No description provided for @complete_sponsors_list_title.
  ///
  /// In ar, this message translates to:
  /// **'قائمة شاملة بجميع الكفلاء المسجلين'**
  String get complete_sponsors_list_title;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @contact_info.
  ///
  /// In ar, this message translates to:
  /// **'4. معلومات الاتصال'**
  String get contact_info;

  /// No description provided for @contact_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الاتصال'**
  String get contact_information;

  /// No description provided for @countries_available.
  ///
  /// In ar, this message translates to:
  /// **'دول متاحة'**
  String get countries_available;

  /// No description provided for @country.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get country;

  /// No description provided for @country_label.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get country_label;

  /// No description provided for @create_child_profile.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء استعلام'**
  String get create_child_profile;

  /// No description provided for @creation_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنشاء'**
  String get creation_date;

  /// No description provided for @crop_image.
  ///
  /// In ar, this message translates to:
  /// **'قص الصورة'**
  String get crop_image;

  /// No description provided for @currency_added.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة العملة'**
  String get currency_added;

  /// No description provided for @currency_hint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: الريال السعودي'**
  String get currency_hint;

  /// No description provided for @currency_name_field.
  ///
  /// In ar, this message translates to:
  /// **'اسم العملة'**
  String get currency_name_field;

  /// No description provided for @currency_symbol_sar.
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get currency_symbol_sar;

  /// No description provided for @databaseExportedTo.
  ///
  /// In ar, this message translates to:
  /// **'تم تصدير قاعدة البيانات إلى'**
  String get databaseExportedTo;

  /// No description provided for @databaseImportedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد قاعدة البيانات بنجاح. تم تحميل'**
  String get databaseImportedSuccess;

  /// No description provided for @database_exported.
  ///
  /// In ar, this message translates to:
  /// **'تم تصدير قاعدة البيانات إلى'**
  String get database_exported;

  /// No description provided for @database_imported.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد قاعدة البيانات بنجاح. تم تحميل'**
  String get database_imported;

  /// No description provided for @date_format_hint.
  ///
  /// In ar, this message translates to:
  /// **'صيغة التاريخ (YYYY-MM-DD)'**
  String get date_format_hint;

  /// No description provided for @date_start.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get date_start;

  /// No description provided for @death_cause.
  ///
  /// In ar, this message translates to:
  /// **'سبب الوفاة'**
  String get death_cause;

  /// No description provided for @death_cause_accident.
  ///
  /// In ar, this message translates to:
  /// **'حادث'**
  String get death_cause_accident;

  /// No description provided for @death_cause_disease.
  ///
  /// In ar, this message translates to:
  /// **'مرض'**
  String get death_cause_disease;

  /// No description provided for @death_cause_natural.
  ///
  /// In ar, this message translates to:
  /// **'وفاة طبيعية'**
  String get death_cause_natural;

  /// No description provided for @death_cause_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get death_cause_other;

  /// No description provided for @death_cause_war.
  ///
  /// In ar, this message translates to:
  /// **'حرب'**
  String get death_cause_war;

  /// No description provided for @data_types.
  ///
  /// In ar, this message translates to:
  /// **'أنواع البيانات'**
  String get data_types;

  /// No description provided for @death_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الوفاة'**
  String get death_date;

  /// No description provided for @deceased.
  ///
  /// In ar, this message translates to:
  /// **'متوفى'**
  String get deceased;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @delete_child.
  ///
  /// In ar, this message translates to:
  /// **'حذف اليتيم'**
  String get delete_child;

  /// No description provided for @financial_system.
  ///
  /// In ar, this message translates to:
  /// **'النظام المالي'**
  String get financial_system;

  /// No description provided for @financial_system_title.
  ///
  /// In ar, this message translates to:
  /// **'النظام المالي'**
  String get financial_system_title;

  /// No description provided for @finance_control_panel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم والإحصائيات العامة'**
  String get finance_control_panel;

  /// No description provided for @refresh_data.
  ///
  /// In ar, this message translates to:
  /// **'تحديث البيانات'**
  String get refresh_data;

  /// No description provided for @total_sales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get total_sales;

  /// No description provided for @total_purchases.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتريات'**
  String get total_purchases;

  /// No description provided for @net_balance.
  ///
  /// In ar, this message translates to:
  /// **'صافي الرصيد'**
  String get net_balance;

  /// No description provided for @quick_access.
  ///
  /// In ar, this message translates to:
  /// **'الوصول السريع'**
  String get quick_access;

  /// No description provided for @customers_and_suppliers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء والموردين'**
  String get customers_and_suppliers;

  /// No description provided for @registered_count.
  ///
  /// In ar, this message translates to:
  /// **'مسجل'**
  String get registered_count;

  /// No description provided for @inventory_and_items.
  ///
  /// In ar, this message translates to:
  /// **'المخزون والأصناف'**
  String get inventory_and_items;

  /// No description provided for @items_count_label.
  ///
  /// In ar, this message translates to:
  /// **'صنف'**
  String get items_count_label;

  /// No description provided for @invoices_log.
  ///
  /// In ar, this message translates to:
  /// **'سجل الفواتير'**
  String get invoices_log;

  /// No description provided for @invoices_count_label.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة'**
  String get invoices_count_label;

  /// No description provided for @purchase_invoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة مشتريات'**
  String get purchase_invoice;

  /// No description provided for @register_new_entry.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل وارد جديد'**
  String get register_new_entry;

  /// No description provided for @sales_invoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة مبيعات'**
  String get sales_invoice;

  /// No description provided for @register_new_sale.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل عملية بيع'**
  String get register_new_sale;

  /// No description provided for @finance_payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get finance_payments;

  /// No description provided for @finance_receipts_and_vouchers.
  ///
  /// In ar, this message translates to:
  /// **'سندات القبض والصرف'**
  String get finance_receipts_and_vouchers;

  /// No description provided for @manage_customers_suppliers.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العملاء والموردين'**
  String get manage_customers_suppliers;

  /// No description provided for @search_customer_hint.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن عميل...'**
  String get search_customer_hint;

  /// No description provided for @no_data_found.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بيانات'**
  String get no_data_found;

  /// No description provided for @add_new_customer_supplier.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عميل/مورد جديد'**
  String get add_new_customer_supplier;

  /// No description provided for @edit_customer_data.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات العميل'**
  String get edit_customer_data;

  /// No description provided for @supplier_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المورد'**
  String get supplier_data;

  /// No description provided for @customer_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل'**
  String get customer_data;

  /// No description provided for @customer_label.
  ///
  /// In ar, this message translates to:
  /// **'زبون'**
  String get customer_label;

  /// No description provided for @supplier_label.
  ///
  /// In ar, this message translates to:
  /// **'مورد'**
  String get supplier_label;

  /// No description provided for @full_name_label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get full_name_label;

  /// No description provided for @phone_number_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone_number_label;

  /// No description provided for @save_data.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البيانات'**
  String get save_data;

  /// No description provided for @confirm_delete_title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirm_delete_title;

  /// No description provided for @confirm_delete_customer_msg.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا العميل؟ قد يتم حذف البيانات المرتبطة به.'**
  String get confirm_delete_customer_msg;

  /// No description provided for @manage_items.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأصناف'**
  String get manage_items;

  /// No description provided for @search_item_hint.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن صنف...'**
  String get search_item_hint;

  /// No description provided for @no_items_found.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أصناف'**
  String get no_items_found;

  /// No description provided for @add_new_item.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صنف جديد'**
  String get add_new_item;

  /// No description provided for @edit_item.
  ///
  /// In ar, this message translates to:
  /// **'تعديل صنف'**
  String get edit_item;

  /// No description provided for @item_details.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الصنف'**
  String get item_details;

  /// No description provided for @item_name_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصنف'**
  String get item_name_label;

  /// No description provided for @unit_label.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة (مثال: قطعة، كجم)'**
  String get unit_label;

  /// No description provided for @save_item.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الصنف'**
  String get save_item;

  /// No description provided for @confirm_delete_item_msg.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا الصنف؟'**
  String get confirm_delete_item_msg;

  /// No description provided for @item_type_materials.
  ///
  /// In ar, this message translates to:
  /// **'مواد'**
  String get item_type_materials;

  /// No description provided for @item_type_supplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات'**
  String get item_type_supplies;

  /// No description provided for @item_type_service.
  ///
  /// In ar, this message translates to:
  /// **'خدمة'**
  String get item_type_service;

  /// No description provided for @item_type_product.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get item_type_product;

  /// No description provided for @vouchers_and_payments.
  ///
  /// In ar, this message translates to:
  /// **'السندات والمدفوعات'**
  String get vouchers_and_payments;

  /// No description provided for @total_receipts.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المقبوضات'**
  String get total_receipts;

  /// No description provided for @total_payments.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المدفوعات'**
  String get total_payments;

  /// No description provided for @search_vouchers_hint.
  ///
  /// In ar, this message translates to:
  /// **'بحث برقم السند أو الملاحظات...'**
  String get search_vouchers_hint;

  /// No description provided for @all_filter.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all_filter;

  /// No description provided for @receipts_in.
  ///
  /// In ar, this message translates to:
  /// **'مقبوضات (In)'**
  String get receipts_in;

  /// No description provided for @payments_out.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعات (Out)'**
  String get payments_out;

  /// No description provided for @no_vouchers_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سندات'**
  String get no_vouchers_found;

  /// No description provided for @new_voucher.
  ///
  /// In ar, this message translates to:
  /// **'سند جديد'**
  String get new_voucher;

  /// No description provided for @receipt_voucher.
  ///
  /// In ar, this message translates to:
  /// **'سند قبض'**
  String get receipt_voucher;

  /// No description provided for @payment_voucher.
  ///
  /// In ar, this message translates to:
  /// **'سند صرف'**
  String get payment_voucher;

  /// No description provided for @undefined_customer.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get undefined_customer;

  /// No description provided for @customer_prefix.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get customer_prefix;

  /// No description provided for @financial_party.
  ///
  /// In ar, this message translates to:
  /// **'الطرف المالي (العميل/المورد)'**
  String get financial_party;

  /// No description provided for @date_label.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date_label;

  /// No description provided for @payment_method_label.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get payment_method_label;

  /// No description provided for @cash_label.
  ///
  /// In ar, this message translates to:
  /// **'نقدي (Cash)'**
  String get cash_label;

  /// No description provided for @check_label.
  ///
  /// In ar, this message translates to:
  /// **'شيك (Check)'**
  String get check_label;

  /// No description provided for @transfer_label.
  ///
  /// In ar, this message translates to:
  /// **'تحويل بنكي (Transfer)'**
  String get transfer_label;

  /// No description provided for @notes_statement.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات / بيان'**
  String get notes_statement;

  /// No description provided for @save_voucher.
  ///
  /// In ar, this message translates to:
  /// **'حفظ السند'**
  String get save_voucher;

  /// No description provided for @select_customer_msg.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار العميل/المورد'**
  String get select_customer_msg;

  /// No description provided for @valid_amount_msg.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال مبلغ صحيح'**
  String get valid_amount_msg;

  /// No description provided for @new_receipt_voucher.
  ///
  /// In ar, this message translates to:
  /// **'سند قبض جديد'**
  String get new_receipt_voucher;

  /// No description provided for @new_payment_voucher.
  ///
  /// In ar, this message translates to:
  /// **'سند صرف جديد'**
  String get new_payment_voucher;

  /// No description provided for @manage_invoices.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الفواتير'**
  String get manage_invoices;

  /// No description provided for @total_sales_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get total_sales_label;

  /// No description provided for @total_purchases_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتريات'**
  String get total_purchases_label;

  /// No description provided for @search_invoices_hint.
  ///
  /// In ar, this message translates to:
  /// **'بحث برقم الفاتورة أو الملاحظات...'**
  String get search_invoices_hint;

  /// No description provided for @sales_filter.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات'**
  String get sales_filter;

  /// No description provided for @purchases_filter.
  ///
  /// In ar, this message translates to:
  /// **'مشتريات'**
  String get purchases_filter;

  /// No description provided for @no_invoices_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواتير'**
  String get no_invoices_found;

  /// No description provided for @new_invoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة جديدة'**
  String get new_invoice;

  /// No description provided for @invoice_label.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة'**
  String get invoice_label;

  /// No description provided for @invoice_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الفاتورة'**
  String get invoice_data;

  /// No description provided for @invoice_type.
  ///
  /// In ar, this message translates to:
  /// **'نوع الفاتورة'**
  String get invoice_type;

  /// No description provided for @items_label.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف'**
  String get items_label;

  /// No description provided for @add_line_item.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صنف للفاتورة'**
  String get add_line_item;

  /// No description provided for @item_label.
  ///
  /// In ar, this message translates to:
  /// **'الصنف'**
  String get item_label;

  /// No description provided for @quantity_label.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantity_label;

  /// No description provided for @unit_price_label.
  ///
  /// In ar, this message translates to:
  /// **'السعر الإفرادي'**
  String get unit_price_label;

  /// No description provided for @final_total_label.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي النهائي:'**
  String get final_total_label;

  /// No description provided for @delete_invoice_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف الفاتورة'**
  String get delete_invoice_title;

  /// No description provided for @confirm_delete_invoice.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الفاتورة؟'**
  String get confirm_delete_invoice;

  /// No description provided for @select_client_msg.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار العميل'**
  String get select_client_msg;

  /// No description provided for @no_items_msg.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إضافة أصناف للفاتورة'**
  String get no_items_msg;

  /// No description provided for @no_items_added_yet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إضافة أصناف بعد'**
  String get no_items_added_yet;

  /// No description provided for @registration_in_progress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التسجيل...'**
  String get registration_in_progress;

  /// No description provided for @no_phone_label.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رقم'**
  String get no_phone_label;

  /// No description provided for @financial_system_desc.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المبيعات والمشتريات والمخزون'**
  String get financial_system_desc;

  /// No description provided for @save_invoice.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الفاتورة'**
  String get save_invoice;

  /// No description provided for @user_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المستخدمين'**
  String get user_management;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @delete_child_title.
  ///
  /// In ar, this message translates to:
  /// **'حذف اليتيم'**
  String get delete_child_title;

  /// No description provided for @delete_sibling.
  ///
  /// In ar, this message translates to:
  /// **'حذف الأخ/الأخت'**
  String get delete_sibling;

  /// No description provided for @disability_hint.
  ///
  /// In ar, this message translates to:
  /// **'إذا كان لديه أي إعاقات أو ملاحظات صحية...'**
  String get disability_hint;

  /// No description provided for @disability_label.
  ///
  /// In ar, this message translates to:
  /// **'الإعاقة/الملاحظات'**
  String get disability_label;

  /// No description provided for @disability_notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الإعاقة'**
  String get disability_notes;

  /// No description provided for @disability_type_auditory.
  ///
  /// In ar, this message translates to:
  /// **'سمعي'**
  String get disability_type_auditory;

  /// No description provided for @disability_type_label.
  ///
  /// In ar, this message translates to:
  /// **'نوع الإعاقة'**
  String get disability_type_label;

  /// No description provided for @disability_type_mental.
  ///
  /// In ar, this message translates to:
  /// **'ذهني'**
  String get disability_type_mental;

  /// No description provided for @disability_type_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get disability_type_other;

  /// No description provided for @disability_type_physical.
  ///
  /// In ar, this message translates to:
  /// **'حركي'**
  String get disability_type_physical;

  /// No description provided for @disability_type_speech.
  ///
  /// In ar, this message translates to:
  /// **'نطقي'**
  String get disability_type_speech;

  /// No description provided for @disability_type_visual.
  ///
  /// In ar, this message translates to:
  /// **'بصري'**
  String get disability_type_visual;

  /// No description provided for @disabled.
  ///
  /// In ar, this message translates to:
  /// **'معاق'**
  String get disabled;

  /// No description provided for @documents.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get documents;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @edit_sibling.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الأخ/الأخت'**
  String get edit_sibling;

  /// No description provided for @education_certificates.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات الدراسية'**
  String get education_certificates;

  /// No description provided for @education_level.
  ///
  /// In ar, this message translates to:
  /// **'مستوى التعليم'**
  String get education_level;

  /// No description provided for @education_level_label.
  ///
  /// In ar, this message translates to:
  /// **'مستوى التعليم'**
  String get education_level_label;

  /// No description provided for @education_level_college.
  ///
  /// In ar, this message translates to:
  /// **'كلية'**
  String get education_level_college;

  /// No description provided for @education_level_middle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادي'**
  String get education_level_middle;

  /// No description provided for @education_level_none.
  ///
  /// In ar, this message translates to:
  /// **'مرحلة ما قبل الدراسة'**
  String get education_level_none;

  /// No description provided for @education_level_not_studying.
  ///
  /// In ar, this message translates to:
  /// **'لا يدرس'**
  String get education_level_not_studying;

  /// No description provided for @education_level_primary.
  ///
  /// In ar, this message translates to:
  /// **'ابتدائي'**
  String get education_level_primary;

  /// No description provided for @education_level_secondary.
  ///
  /// In ar, this message translates to:
  /// **'ثانوي'**
  String get education_level_secondary;

  /// No description provided for @education_level_university.
  ///
  /// In ar, this message translates to:
  /// **'جامعي'**
  String get education_level_university;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @error_creating_report.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إنشاء التقرير'**
  String get error_creating_report;

  /// No description provided for @error_generating_pdf.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في إنشاء ملف PDF'**
  String get error_generating_pdf;

  /// No description provided for @exportDB.
  ///
  /// In ar, this message translates to:
  /// **'تصدير بيانات الأيتام'**
  String get exportDB;

  /// No description provided for @exportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير'**
  String get exportFailed;

  /// No description provided for @export_db.
  ///
  /// In ar, this message translates to:
  /// **'تصدير قاعدة البيانات'**
  String get export_db;

  /// No description provided for @export_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التصدير'**
  String get export_failed;

  /// No description provided for @face_detected.
  ///
  /// In ar, this message translates to:
  /// **'تم اكتشاف الوجه - يرجى الاقتصاص'**
  String get face_detected;

  /// No description provided for @family_documents.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات العائلة'**
  String get family_documents;

  /// No description provided for @family_income.
  ///
  /// In ar, this message translates to:
  /// **'دخل العائلة'**
  String get family_income;

  /// No description provided for @family_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get family_name;

  /// No description provided for @father.
  ///
  /// In ar, this message translates to:
  /// **'الأب'**
  String get father;

  /// No description provided for @father_death_certificate.
  ///
  /// In ar, this message translates to:
  /// **'شهادة وفاة الأب'**
  String get father_death_certificate;

  /// No description provided for @father_full_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأب ثلاثي'**
  String get father_full_name;

  /// No description provided for @father_id.
  ///
  /// In ar, this message translates to:
  /// **'هوية الأب'**
  String get father_id;

  /// No description provided for @father_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الأب'**
  String get father_information;

  /// No description provided for @father_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الأب'**
  String get father_data;

  /// No description provided for @father_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأب'**
  String get father_name;

  /// No description provided for @father_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الأب'**
  String get father_status;

  /// No description provided for @father_death_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ وفاة الأب'**
  String get father_death_date;

  /// No description provided for @father_death_cause.
  ///
  /// In ar, this message translates to:
  /// **'سبب وفاة الأب'**
  String get father_death_cause;

  /// No description provided for @female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get female;

  /// No description provided for @file_not_found.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير موجود'**
  String get file_not_found;

  /// No description provided for @files_count.
  ///
  /// In ar, this message translates to:
  /// **'ملفات'**
  String get files_count;

  /// No description provided for @fill_all_fields.
  ///
  /// In ar, this message translates to:
  /// **'يرجى ملء جميع الحقول'**
  String get fill_all_fields;

  /// No description provided for @first_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get first_name;

  /// No description provided for @gender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get gender;

  /// No description provided for @gender_female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get gender_female;

  /// No description provided for @gender_male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get gender_male;

  /// No description provided for @generate_and_print.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء وطباعة التقرير'**
  String get generate_and_print;

  /// No description provided for @generate_pdf.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير PDF'**
  String get generate_pdf;

  /// No description provided for @generate_pdf_report.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تقرير PDF'**
  String get generate_pdf_report;

  /// No description provided for @generating_report.
  ///
  /// In ar, this message translates to:
  /// **'جاري إنشاء التقرير...'**
  String get generating_report;

  /// No description provided for @grade.
  ///
  /// In ar, this message translates to:
  /// **'الصف'**
  String get grade;

  /// No description provided for @grandfather.
  ///
  /// In ar, this message translates to:
  /// **'الجد'**
  String get grandfather;

  /// No description provided for @grandmother.
  ///
  /// In ar, this message translates to:
  /// **'الجدة'**
  String get grandmother;

  /// No description provided for @guardian_address.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الولي'**
  String get guardian_address;

  /// No description provided for @guardian_address_label.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الولي'**
  String get guardian_address_label;

  /// No description provided for @guardian_id_photo.
  ///
  /// In ar, this message translates to:
  /// **'صورة هوية الولي'**
  String get guardian_id_photo;

  /// No description provided for @guardian_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الولي'**
  String get guardian_information;

  /// No description provided for @guardian_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الولي ثلاثي'**
  String get guardian_name;

  /// No description provided for @guardian_phone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف الولي'**
  String get guardian_phone;

  /// No description provided for @guardian_phone_label.
  ///
  /// In ar, this message translates to:
  /// **'هاتف الولي'**
  String get guardian_phone_label;

  /// No description provided for @health.
  ///
  /// In ar, this message translates to:
  /// **'الصحة'**
  String get health;

  /// No description provided for @health_and_education_info.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الصحية والتعليمية'**
  String get health_and_education_info;

  /// No description provided for @health_section.
  ///
  /// In ar, this message translates to:
  /// **'الصحة'**
  String get health_section;

  /// No description provided for @health_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الصحية'**
  String get health_status;

  /// No description provided for @health_status_disabled.
  ///
  /// In ar, this message translates to:
  /// **'معاق'**
  String get health_status_disabled;

  /// No description provided for @health_status_healthy.
  ///
  /// In ar, this message translates to:
  /// **'سليم'**
  String get health_status_healthy;

  /// No description provided for @health_status_label.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الصحية'**
  String get health_status_label;

  /// No description provided for @health_status_sick.
  ///
  /// In ar, this message translates to:
  /// **'مريض'**
  String get health_status_sick;

  /// No description provided for @healthy.
  ///
  /// In ar, this message translates to:
  /// **'سليم'**
  String get healthy;

  /// No description provided for @id_photos.
  ///
  /// In ar, this message translates to:
  /// **'صور الهوية'**
  String get id_photos;

  /// No description provided for @image.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get image;

  /// No description provided for @importDB.
  ///
  /// In ar, this message translates to:
  /// **'استيراد بيانات الأيتام'**
  String get importDB;

  /// No description provided for @export_all_children.
  ///
  /// In ar, this message translates to:
  /// **'تصدير جميع الأيتام'**
  String get export_all_children;

  /// No description provided for @export_selected_children.
  ///
  /// In ar, this message translates to:
  /// **'تصدير أيتام محددين'**
  String get export_selected_children;

  /// No description provided for @export_orphan_data.
  ///
  /// In ar, this message translates to:
  /// **'تصدير بيانات الأيتام'**
  String get export_orphan_data;

  /// No description provided for @import_orphan_data.
  ///
  /// In ar, this message translates to:
  /// **'استيراد بيانات الأيتام'**
  String get import_orphan_data;

  /// No description provided for @select_child_first.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تحديد يتيم واحد على الأقل'**
  String get select_child_first;

  /// No description provided for @duplicate_child.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهوية مسجل مسبقًا'**
  String get duplicate_child;

  /// No description provided for @replace_child.
  ///
  /// In ar, this message translates to:
  /// **'استبدال البيانات'**
  String get replace_child;

  /// No description provided for @skip_child.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skip_child;

  /// No description provided for @import_completed.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستيراد'**
  String get import_completed;

  /// No description provided for @import_skipped.
  ///
  /// In ar, this message translates to:
  /// **'تم التخطي'**
  String get import_skipped;

  /// No description provided for @importFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد'**
  String get importFailed;

  /// No description provided for @import_db.
  ///
  /// In ar, this message translates to:
  /// **'استيراد قاعدة البيانات'**
  String get import_db;

  /// No description provided for @import_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد'**
  String get import_failed;

  /// No description provided for @inactive_status.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get inactive_status;

  /// No description provided for @is_sponsored.
  ///
  /// In ar, this message translates to:
  /// **'هل هو مكفول؟'**
  String get is_sponsored;

  /// No description provided for @is_sponsorship_ongoing.
  ///
  /// In ar, this message translates to:
  /// **'هل الكفالة مستمرة؟'**
  String get is_sponsorship_ongoing;

  /// No description provided for @label_guardian.
  ///
  /// In ar, this message translates to:
  /// **'الولي'**
  String get label_guardian;

  /// No description provided for @label_relationship.
  ///
  /// In ar, this message translates to:
  /// **'العلاقة'**
  String get label_relationship;

  /// No description provided for @language_arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get language_arabic;

  /// No description provided for @language_english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get language_english;

  /// No description provided for @language_turkish.
  ///
  /// In ar, this message translates to:
  /// **'التركية'**
  String get language_turkish;

  /// No description provided for @loading_countries.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الدول...'**
  String get loading_countries;

  /// No description provided for @male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get male;

  /// No description provided for @medical_report.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الطبي'**
  String get medical_report;

  /// No description provided for @middle_7.
  ///
  /// In ar, this message translates to:
  /// **'السابع'**
  String get middle_7;

  /// No description provided for @middle_8.
  ///
  /// In ar, this message translates to:
  /// **'الثامن'**
  String get middle_8;

  /// No description provided for @middle_9.
  ///
  /// In ar, this message translates to:
  /// **'التاسع'**
  String get middle_9;

  /// No description provided for @mobile.
  ///
  /// In ar, this message translates to:
  /// **'الجوال'**
  String get mobile;

  /// No description provided for @month_01.
  ///
  /// In ar, this message translates to:
  /// **'يناير'**
  String get month_01;

  /// No description provided for @month_02.
  ///
  /// In ar, this message translates to:
  /// **'فبراير'**
  String get month_02;

  /// No description provided for @month_03.
  ///
  /// In ar, this message translates to:
  /// **'مارس'**
  String get month_03;

  /// No description provided for @month_04.
  ///
  /// In ar, this message translates to:
  /// **'أبريل'**
  String get month_04;

  /// No description provided for @month_05.
  ///
  /// In ar, this message translates to:
  /// **'مايو'**
  String get month_05;

  /// No description provided for @month_06.
  ///
  /// In ar, this message translates to:
  /// **'يونيو'**
  String get month_06;

  /// No description provided for @month_07.
  ///
  /// In ar, this message translates to:
  /// **'يوليو'**
  String get month_07;

  /// No description provided for @month_08.
  ///
  /// In ar, this message translates to:
  /// **'أغسطس'**
  String get month_08;

  /// No description provided for @month_09.
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر'**
  String get month_09;

  /// No description provided for @month_10.
  ///
  /// In ar, this message translates to:
  /// **'أكتوبر'**
  String get month_10;

  /// No description provided for @month_11.
  ///
  /// In ar, this message translates to:
  /// **'نوفمبر'**
  String get month_11;

  /// No description provided for @month_12.
  ///
  /// In ar, this message translates to:
  /// **'ديسمبر'**
  String get month_12;

  /// No description provided for @month_label.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get month_label;

  /// No description provided for @monthly_amount_label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الشهري'**
  String get monthly_amount_label;

  /// No description provided for @monthly_label.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthly_label;

  /// No description provided for @monthly_payment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع الشهري'**
  String get monthly_payment;

  /// No description provided for @monthly_report_creation_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ إنشاء التقرير:'**
  String get monthly_report_creation_date;

  /// No description provided for @monthly_report_month_label.
  ///
  /// In ar, this message translates to:
  /// **'تقرير شهر:'**
  String get monthly_report_month_label;

  /// No description provided for @monthly_report_title.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الشهري للكفالة'**
  String get monthly_report_title;

  /// No description provided for @monthly_sponsor_payments.
  ///
  /// In ar, this message translates to:
  /// **'دفعات الكفيل الشهرية'**
  String get monthly_sponsor_payments;

  /// No description provided for @guardian_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات ولي الأمر'**
  String get guardian_info;

  /// No description provided for @total_payments_summary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص إجمالي المدفوعات'**
  String get total_payments_summary;

  /// No description provided for @detailed_payments_table.
  ///
  /// In ar, this message translates to:
  /// **'جدول المدفوعات التفصيلي'**
  String get detailed_payments_table;

  /// No description provided for @orphans_details_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة تفاصيل الأيتام'**
  String get orphans_details_list;

  /// No description provided for @personal_info.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get personal_info;

  /// No description provided for @sponsorship_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الكفالة'**
  String get sponsorship_info;

  /// No description provided for @sponsorship_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الكفالة'**
  String get sponsorship_status;

  /// No description provided for @sponsor_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الكفيل'**
  String get sponsor_info;

  /// No description provided for @select_orphan.
  ///
  /// In ar, this message translates to:
  /// **'اختر اليتيم'**
  String get select_orphan;

  /// No description provided for @select_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'اختر الكفيل'**
  String get select_sponsor;

  /// No description provided for @please_select_person_first.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار الشخص أولاً'**
  String get please_select_person_first;

  /// No description provided for @moreFields.
  ///
  /// In ar, this message translates to:
  /// **'المزيد من الحقول هنا...'**
  String get moreFields;

  /// No description provided for @mother.
  ///
  /// In ar, this message translates to:
  /// **'الأم'**
  String get mother;

  /// No description provided for @mother_death_certificate.
  ///
  /// In ar, this message translates to:
  /// **'شهادة وفاة الأم'**
  String get mother_death_certificate;

  /// No description provided for @mother_full_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأم ثلاثي'**
  String get mother_full_name;

  /// No description provided for @mother_id.
  ///
  /// In ar, this message translates to:
  /// **'هوية الأم'**
  String get mother_id;

  /// No description provided for @mother_id_photo.
  ///
  /// In ar, this message translates to:
  /// **'صورة هوية الأم'**
  String get mother_id_photo;

  /// No description provided for @mother_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الأم'**
  String get mother_information;

  /// No description provided for @mother_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأم'**
  String get mother_name;

  /// No description provided for @mother_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الأم'**
  String get mother_status;

  /// No description provided for @mother_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الأم'**
  String get mother_data;

  /// No description provided for @mother_death_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ وفاة الأم'**
  String get mother_death_date;

  /// No description provided for @mother_death_cause.
  ///
  /// In ar, this message translates to:
  /// **'سبب وفاة الأم'**
  String get mother_death_cause;

  /// No description provided for @name_label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name_label;

  /// No description provided for @national_id.
  ///
  /// In ar, this message translates to:
  /// **'الهوية الوطنية'**
  String get national_id;

  /// No description provided for @newChild.
  ///
  /// In ar, this message translates to:
  /// **'طفل جديد'**
  String get newChild;

  /// No description provided for @new_child.
  ///
  /// In ar, this message translates to:
  /// **'طفل جديد'**
  String get new_child;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @noChildrenFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على أطفال'**
  String get noChildrenFound;

  /// No description provided for @no_children_found.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على أطفال'**
  String get no_children_found;

  /// No description provided for @no_cities.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدن لهذه الدولة'**
  String get no_cities;

  /// No description provided for @no_documents_uploaded.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحميل أي مرفقات'**
  String get no_documents_uploaded;

  /// No description provided for @no_orphans_for_report.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أيتام لإنشاء التقرير'**
  String get no_orphans_for_report;

  /// No description provided for @no_payments_recorded.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تسجيل أي مدفوعات'**
  String get no_payments_recorded;

  /// No description provided for @no_photo.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صورة'**
  String get no_photo;

  /// No description provided for @no_siblings.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أخوة'**
  String get no_siblings;

  /// No description provided for @no_sponsored_children.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيتام مكفولين حالياً'**
  String get no_sponsored_children;

  /// No description provided for @no_sponsors_for_report.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد كفلاء لإنشاء التقرير'**
  String get no_sponsors_for_report;

  /// No description provided for @no_transactions_this_month.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات في هذا الشهر'**
  String get no_transactions_this_month;

  /// No description provided for @no_unsponsored_orphans.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أيتام غير مكفولين'**
  String get no_unsponsored_orphans;

  /// No description provided for @no_uploaded_files.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحميل أي ملفات'**
  String get no_uploaded_files;

  /// No description provided for @not_available_label.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get not_available_label;

  /// No description provided for @not_sponsored.
  ///
  /// In ar, this message translates to:
  /// **'غير مكفول'**
  String get not_sponsored;

  /// No description provided for @number_hash_label.
  ///
  /// In ar, this message translates to:
  /// **'#'**
  String get number_hash_label;

  /// No description provided for @number_of_children_label.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيتام'**
  String get number_of_children_label;

  /// No description provided for @number_of_payments.
  ///
  /// In ar, this message translates to:
  /// **'عدد المدفوعات'**
  String get number_of_payments;

  /// No description provided for @numbers_only.
  ///
  /// In ar, this message translates to:
  /// **'أرقام فقط'**
  String get numbers_only;

  /// No description provided for @organization_name.
  ///
  /// In ar, this message translates to:
  /// **'إحسان'**
  String get organization_name;

  /// No description provided for @orphan_documents.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات اليتيم'**
  String get orphan_documents;

  /// No description provided for @other.
  ///
  /// In ar, this message translates to:
  /// **'آخر'**
  String get other;

  /// No description provided for @other_documents.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات أخرى'**
  String get other_documents;

  /// No description provided for @parents_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الوالدين'**
  String get parents_information;

  /// No description provided for @payment_date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get payment_date;

  /// No description provided for @payment_note.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get payment_note;

  /// No description provided for @payment_records.
  ///
  /// In ar, this message translates to:
  /// **'سجلات المدفوعات'**
  String get payment_records;

  /// No description provided for @payment_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الدفع'**
  String get payment_status;

  /// No description provided for @payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get payments;

  /// No description provided for @payments_section.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get payments_section;

  /// No description provided for @pdf_generation_error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إنشاء التقرير. يرجى المحاولة مرة أخرى.'**
  String get pdf_generation_error;

  /// No description provided for @pdf_generation_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء PDF'**
  String get pdf_generation_failed;

  /// No description provided for @pdf_report.
  ///
  /// In ar, this message translates to:
  /// **'تقرير PDF'**
  String get pdf_report;

  /// No description provided for @pdf_report_generated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء تقرير PDF لـ'**
  String get pdf_report_generated;

  /// No description provided for @personal_and_family_info.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية والعائلية'**
  String get personal_and_family_info;

  /// No description provided for @please_enter_currency_name.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم العملة'**
  String get please_enter_currency_name;

  /// No description provided for @please_enter_sibling_name.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم الأخ/الأخت'**
  String get please_enter_sibling_name;

  /// No description provided for @please_enter_sponsor_name.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم الكفيل'**
  String get please_enter_sponsor_name;

  /// No description provided for @please_sponsor_unsponsored_children.
  ///
  /// In ar, this message translates to:
  /// **'يرجى العمل على كفالة الأيتام غير المكفولين'**
  String get please_sponsor_unsponsored_children;

  /// No description provided for @primary_1.
  ///
  /// In ar, this message translates to:
  /// **'الأول'**
  String get primary_1;

  /// No description provided for @primary_2.
  ///
  /// In ar, this message translates to:
  /// **'الثاني'**
  String get primary_2;

  /// No description provided for @primary_3.
  ///
  /// In ar, this message translates to:
  /// **'الثالث'**
  String get primary_3;

  /// No description provided for @primary_4.
  ///
  /// In ar, this message translates to:
  /// **'الرابع'**
  String get primary_4;

  /// No description provided for @primary_5.
  ///
  /// In ar, this message translates to:
  /// **'الخامس'**
  String get primary_5;

  /// No description provided for @primary_6.
  ///
  /// In ar, this message translates to:
  /// **'السادس'**
  String get primary_6;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @print_button.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print_button;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل'**
  String get register;

  /// No description provided for @registration_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم التسجيل'**
  String get registration_number;

  /// No description provided for @relationship.
  ///
  /// In ar, this message translates to:
  /// **'العلاقة'**
  String get relationship;

  /// No description provided for @relationship_aunt.
  ///
  /// In ar, this message translates to:
  /// **'عمة'**
  String get relationship_aunt;

  /// No description provided for @relationship_brother.
  ///
  /// In ar, this message translates to:
  /// **'أخ'**
  String get relationship_brother;

  /// No description provided for @relationship_father.
  ///
  /// In ar, this message translates to:
  /// **'أب'**
  String get relationship_father;

  /// No description provided for @relationship_grandfather.
  ///
  /// In ar, this message translates to:
  /// **'جد'**
  String get relationship_grandfather;

  /// No description provided for @relationship_grandmother.
  ///
  /// In ar, this message translates to:
  /// **'جدة'**
  String get relationship_grandmother;

  /// No description provided for @relationship_mother.
  ///
  /// In ar, this message translates to:
  /// **'أم'**
  String get relationship_mother;

  /// No description provided for @relationship_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get relationship_other;

  /// No description provided for @relationship_sister.
  ///
  /// In ar, this message translates to:
  /// **'أخت'**
  String get relationship_sister;

  /// No description provided for @relationship_uncle.
  ///
  /// In ar, this message translates to:
  /// **'عم'**
  String get relationship_uncle;

  /// No description provided for @report_active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get report_active;

  /// No description provided for @report_active_sponsors.
  ///
  /// In ar, this message translates to:
  /// **'الكفلاء النشطين'**
  String get report_active_sponsors;

  /// No description provided for @report_age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get report_age;

  /// No description provided for @report_all_orphans_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة شاملة بجميع الأيتام المسجلين'**
  String get report_all_orphans_list;

  /// No description provided for @report_child_id.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطفل'**
  String get report_child_id;

  /// No description provided for @report_all_sponsored_message.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيتام غير مكفولين - جميع الأيتام لديهم كفلاء!'**
  String get report_all_sponsored_message;

  /// No description provided for @report_all_sponsors_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة شاملة بجميع الكفلاء المسجلين'**
  String get report_all_sponsors_list;

  /// No description provided for @report_contents.
  ///
  /// In ar, this message translates to:
  /// **'محتويات التقرير'**
  String get report_contents;

  /// No description provided for @report_child_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الطفل'**
  String get report_child_name;

  /// No description provided for @report_confidential_notice.
  ///
  /// In ar, this message translates to:
  /// **'هذا التقرير سري وخاص بالكفيل'**
  String get report_confidential_notice;

  /// No description provided for @clear_all.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكل'**
  String get clear_all;

  /// No description provided for @select_all.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get select_all;

  /// No description provided for @select_columns_to_show.
  ///
  /// In ar, this message translates to:
  /// **'اختر العناصر التي تريد أن تظهر في التقرير'**
  String get select_columns_to_show;

  /// No description provided for @select_country.
  ///
  /// In ar, this message translates to:
  /// **'اختر الدولة'**
  String get select_country;

  /// No description provided for @report_country.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get report_country;

  /// No description provided for @report_created_successfully.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء التقرير بنجاح'**
  String get report_created_successfully;

  /// No description provided for @report_creation_date_colon.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنشاء:'**
  String get report_creation_date_colon;

  /// No description provided for @report_creation_date_label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنشاء:'**
  String get report_creation_date_label;

  /// No description provided for @report_end_date_colon.
  ///
  /// In ar, this message translates to:
  /// **'نهاية الكفالة:'**
  String get report_end_date_colon;

  /// No description provided for @report_financial.
  ///
  /// In ar, this message translates to:
  /// **'تقرير مالي'**
  String get report_financial;

  /// No description provided for @report_financial_description.
  ///
  /// In ar, this message translates to:
  /// **'تقرير مفصل عن المدفوعات والتبرعات والمصروفات'**
  String get report_financial_description;

  /// No description provided for @report_gender_boy.
  ///
  /// In ar, this message translates to:
  /// **'فتى'**
  String get report_gender_boy;

  /// No description provided for @report_gender_female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get report_gender_female;

  /// No description provided for @report_gender_girl.
  ///
  /// In ar, this message translates to:
  /// **'فتاة'**
  String get report_gender_girl;

  /// No description provided for @report_gender_male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get report_gender_male;

  /// No description provided for @report_generated_by_system.
  ///
  /// In ar, this message translates to:
  /// **'تقرير تم إنشاؤه بواسطة نظام إدارة الأيتام'**
  String get report_generated_by_system;

  /// No description provided for @report_health_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الصحية'**
  String get report_health_status;

  /// No description provided for @report_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التقرير'**
  String get report_info;

  /// No description provided for @report_info_title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التقرير'**
  String get report_info_title;

  /// No description provided for @report_monthly_amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الشهري'**
  String get report_monthly_amount;

  /// No description provided for @report_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get report_name;

  /// No description provided for @report_no_sponsored_orphans.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيتام مكفولين حالياً'**
  String get report_no_sponsored_orphans;

  /// No description provided for @report_none.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد'**
  String get report_none;

  /// No description provided for @report_orphan.
  ///
  /// In ar, this message translates to:
  /// **'اليتيم'**
  String get report_orphan;

  /// No description provided for @report_options.
  ///
  /// In ar, this message translates to:
  /// **'خيارات التقرير'**
  String get report_options;

  /// No description provided for @report_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get report_status;

  /// No description provided for @report_orphans_count.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيتام'**
  String get report_orphans_count;

  /// No description provided for @report_period_colon.
  ///
  /// In ar, this message translates to:
  /// **'فترة التقرير:'**
  String get report_period_colon;

  /// No description provided for @report_period_label.
  ///
  /// In ar, this message translates to:
  /// **'فترة التقرير'**
  String get report_period_label;

  /// No description provided for @report_please_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'يرجى العمل على كفالة الأيتام غير المكفولين'**
  String get report_please_sponsor;

  /// No description provided for @report_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'الكفيل'**
  String get report_sponsor;

  /// No description provided for @report_sponsor_id_colon.
  ///
  /// In ar, this message translates to:
  /// **'رقم الكفيل:'**
  String get report_sponsor_id_colon;

  /// No description provided for @report_sponsor_info.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الكفيل'**
  String get report_sponsor_info;

  /// No description provided for @report_sponsor_name_colon.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكفيل:'**
  String get report_sponsor_name_colon;

  /// No description provided for @report_sponsored.
  ///
  /// In ar, this message translates to:
  /// **'المكفولين'**
  String get report_sponsored;

  /// No description provided for @report_statistical.
  ///
  /// In ar, this message translates to:
  /// **'تقرير إحصائي'**
  String get report_statistical;

  /// No description provided for @report_stats_description.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات شاملة عن الأيتام والكفلاء والمدفوعات'**
  String get report_stats_description;

  /// No description provided for @report_stopped.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get report_stopped;

  /// No description provided for @report_summary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الاستمارة'**
  String get report_summary;

  /// No description provided for @report_title.
  ///
  /// In ar, this message translates to:
  /// **'استمارة يتيم'**
  String get report_title;

  /// No description provided for @report_total_orphans.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام'**
  String get report_total_orphans;

  /// No description provided for @report_total_sponsored_orphans.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام المكفولين'**
  String get report_total_sponsored_orphans;

  /// No description provided for @report_total_sponsors.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الكفلاء'**
  String get report_total_sponsors;

  /// No description provided for @report_total_unsponsored_orphans.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام غير المكفولين'**
  String get report_total_unsponsored_orphans;

  /// No description provided for @report_type_monthly_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الشهري للكفيل'**
  String get report_type_monthly_sponsor;

  /// No description provided for @report_type_orphans.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الأيتام'**
  String get report_type_orphans;

  /// No description provided for @report_type_single_orphan.
  ///
  /// In ar, this message translates to:
  /// **'تقرير كامل لليتيم'**
  String get report_type_single_orphan;

  /// No description provided for @report_type_single_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'تقرير كفيل محدد'**
  String get report_type_single_sponsor;

  /// No description provided for @report_type_sponsors.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الكفلاء'**
  String get report_type_sponsors;

  /// No description provided for @report_type_unsponsored.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام غير المكفولين'**
  String get report_type_unsponsored;

  /// No description provided for @report_unsponsored.
  ///
  /// In ar, this message translates to:
  /// **'غير المكفولين'**
  String get report_unsponsored;

  /// No description provided for @report_unsponsored_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأيتام غير المكفولين'**
  String get report_unsponsored_list;

  /// No description provided for @report_unsponsored_orphans_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الأيتام غير المكفولين'**
  String get report_unsponsored_orphans_title;

  /// No description provided for @report_years.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get report_years;

  /// No description provided for @reporting.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reporting;

  /// No description provided for @reporting_section.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reporting_section;

  /// No description provided for @reports_page_description.
  ///
  /// In ar, this message translates to:
  /// **'معاينة وطباعة الاستمارات والتقارير الخاصة بالأيتام والكفلاء'**
  String get reports_page_description;

  /// No description provided for @reports_page_title.
  ///
  /// In ar, this message translates to:
  /// **'الاستمارة'**
  String get reports_page_title;

  /// No description provided for @required_field.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get required_field;

  /// No description provided for @required_mark.
  ///
  /// In ar, this message translates to:
  /// **'*'**
  String get required_mark;

  /// No description provided for @review_before_submit.
  ///
  /// In ar, this message translates to:
  /// **'يرجى مراجعة جميع المعلومات قبل الإرسال.'**
  String get review_before_submit;

  /// No description provided for @review_information.
  ///
  /// In ar, this message translates to:
  /// **'راجع جميع المعلومات قبل الإرسال'**
  String get review_information;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @save_changes.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get save_changes;

  /// No description provided for @saved_successfully.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ بنجاح'**
  String get saved_successfully;

  /// No description provided for @school_class.
  ///
  /// In ar, this message translates to:
  /// **'الفصل الدراسي'**
  String get school_class;

  /// No description provided for @school_grade.
  ///
  /// In ar, this message translates to:
  /// **'درجة المدرسة'**
  String get school_grade;

  /// No description provided for @school_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم المدرسة'**
  String get school_name;

  /// No description provided for @school_score.
  ///
  /// In ar, this message translates to:
  /// **'درجة الامتحان'**
  String get school_score;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'البحث بالاسم أو المعرف أو الكفيل...'**
  String get searchHint;

  /// No description provided for @search_children_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن الأطفال بالاسم أو المعرف أو الكفيل...'**
  String get search_children_placeholder;

  /// No description provided for @search_label.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search_label;

  /// No description provided for @secondary_10.
  ///
  /// In ar, this message translates to:
  /// **'العاشر'**
  String get secondary_10;

  /// No description provided for @secondary_11.
  ///
  /// In ar, this message translates to:
  /// **'الحادي عشر'**
  String get secondary_11;

  /// No description provided for @secondary_12.
  ///
  /// In ar, this message translates to:
  /// **'الثاني عشر'**
  String get secondary_12;

  /// No description provided for @selectChildPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر يتيماً لعرض التفاصيل'**
  String get selectChildPrompt;

  /// No description provided for @select_country_first.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار الدولة أولاً'**
  String get select_country_first;

  /// No description provided for @select_database_import.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف قاعدة البيانات للاستيراد'**
  String get select_database_import;

  /// No description provided for @select_end_date.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تحديد تاريخ الانتهاء'**
  String get select_end_date;

  /// No description provided for @select_person.
  ///
  /// In ar, this message translates to:
  /// **'اختر الشخص'**
  String get select_person;

  /// No description provided for @select_report_type.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع التقرير'**
  String get select_report_type;

  /// No description provided for @settings_about_section.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get settings_about_section;

  /// No description provided for @settings_app_language.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق'**
  String get settings_app_language;

  /// No description provided for @settings_app_language_desc.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة الافتراضية للتطبيق'**
  String get settings_app_language_desc;

  /// No description provided for @settings_app_version.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get settings_app_version;

  /// No description provided for @settings_auto_backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي التلقائي'**
  String get settings_auto_backup;

  /// No description provided for @settings_auto_backup_desc.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء نسخة احتياطية تلقائية للبيانات'**
  String get settings_auto_backup_desc;

  /// No description provided for @settings_backup_interval.
  ///
  /// In ar, this message translates to:
  /// **'فترة النسخ الاحتياطي'**
  String get settings_backup_interval;

  /// No description provided for @settings_backup_interval_desc.
  ///
  /// In ar, this message translates to:
  /// **'كم مرة يتم إنشاء نسخة احتياطية'**
  String get settings_backup_interval_desc;

  /// No description provided for @settings_backup_section.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get settings_backup_section;

  /// No description provided for @settings_daily.
  ///
  /// In ar, this message translates to:
  /// **'يومياً'**
  String get settings_daily;

  /// No description provided for @settings_edit_organization.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم المنظمة'**
  String get settings_edit_organization;

  /// No description provided for @settings_language_section.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settings_language_section;

  /// No description provided for @settings_monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهرياً'**
  String get settings_monthly;

  /// No description provided for @settings_organization_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنظمة'**
  String get settings_organization_name;

  /// No description provided for @settings_organization_section.
  ///
  /// In ar, this message translates to:
  /// **'المنظمة'**
  String get settings_organization_section;

  /// No description provided for @settings_page_description.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص إعدادات التطبيق وتفضيلاتك'**
  String get settings_page_description;

  /// No description provided for @settings_page_title.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings_page_title;

  /// No description provided for @settings_report_language.
  ///
  /// In ar, this message translates to:
  /// **'لغة التقارير'**
  String get settings_report_language;

  /// No description provided for @settings_report_language_desc.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الافتراضية لإنشاء التقارير'**
  String get settings_report_language_desc;

  /// No description provided for @settings_reports_section.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get settings_reports_section;

  /// No description provided for @settings_reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين الإعدادات'**
  String get settings_reset;

  /// No description provided for @settings_reset_button.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get settings_reset_button;

  /// No description provided for @settings_reset_confirm.
  ///
  /// In ar, this message translates to:
  /// **'نعم، إعادة تعيين'**
  String get settings_reset_confirm;

  /// No description provided for @settings_reset_desc.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع جميع الإعدادات للقيم الافتراضية'**
  String get settings_reset_desc;

  /// No description provided for @settings_reset_message.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إعادة تعيين جميع الإعدادات؟ لا يمكن التراجع عن هذا الإجراء.'**
  String get settings_reset_message;

  /// No description provided for @settings_reset_success.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تعيين الإعدادات بنجاح'**
  String get settings_reset_success;

  /// No description provided for @settings_reset_title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إعادة التعيين'**
  String get settings_reset_title;

  /// No description provided for @settings_weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعياً'**
  String get settings_weekly;

  /// No description provided for @comprehensive_backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي الشامل'**
  String get comprehensive_backup;

  /// No description provided for @last_backup.
  ///
  /// In ar, this message translates to:
  /// **'آخر نسخة احتياطية'**
  String get last_backup;

  /// No description provided for @never_backed_up.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم النسخ مسبقاً'**
  String get never_backed_up;

  /// No description provided for @next_backup_date.
  ///
  /// In ar, this message translates to:
  /// **'موعد النسخ القادم'**
  String get next_backup_date;

  /// No description provided for @backup_overdue_warning.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: لقد تجاوزت موعد النسخ الاحتياطي المجدول. يرجى النسخ الآن لحماية بياناتك.'**
  String get backup_overdue_warning;

  /// No description provided for @auto_backup_desc.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بالنسخ الاحتياطي للبيانات والصور تلقائياً'**
  String get auto_backup_desc;

  /// No description provided for @cloud_backup_title.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي السحابي'**
  String get cloud_backup_title;

  /// No description provided for @cloud_backup_desc.
  ///
  /// In ar, this message translates to:
  /// **'سيتم رفع كافة البيانات إلى Firebase وكافة الصور والملفات إلى GitHub للحفاظ عليها من الضياع.'**
  String get cloud_backup_desc;

  /// No description provided for @start_cloud_backup.
  ///
  /// In ar, this message translates to:
  /// **'بدء النسخ الاحتياطي السحابي الآن'**
  String get start_cloud_backup;

  /// No description provided for @data_location_title.
  ///
  /// In ar, this message translates to:
  /// **'موقع البيانات'**
  String get data_location_title;

  /// No description provided for @backup_zip_path.
  ///
  /// In ar, this message translates to:
  /// **'مسار حفظ النسخ (ZIP)'**
  String get backup_zip_path;

  /// No description provided for @default_path_hint.
  ///
  /// In ar, this message translates to:
  /// **'المسار الافتراضي'**
  String get default_path_hint;

  /// No description provided for @change_button.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change_button;

  /// No description provided for @restore_default_backup_path.
  ///
  /// In ar, this message translates to:
  /// **'استعادة مسار النسخ الافتراضي'**
  String get restore_default_backup_path;

  /// No description provided for @db_path.
  ///
  /// In ar, this message translates to:
  /// **'مسار قاعدة البيانات'**
  String get db_path;

  /// No description provided for @shown.
  ///
  /// In ar, this message translates to:
  /// **'معروض'**
  String get shown;

  /// No description provided for @shown_count.
  ///
  /// In ar, this message translates to:
  /// **'معروض'**
  String get shown_count;

  /// No description provided for @sibling_action.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء'**
  String get sibling_action;

  /// No description provided for @sibling_age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get sibling_age;

  /// No description provided for @sibling_birth_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get sibling_birth_date;

  /// No description provided for @sibling_data_not_saved.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التأكد من حفظ بيانات الإخوة. لم يكتمل الحفظ'**
  String get sibling_data_not_saved;

  /// No description provided for @sibling_gender.
  ///
  /// In ar, this message translates to:
  /// **'جنس الأخ/الأخت'**
  String get sibling_gender;

  /// No description provided for @sibling_id.
  ///
  /// In ar, this message translates to:
  /// **'الهوية'**
  String get sibling_id;

  /// No description provided for @sibling_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get sibling_name;

  /// No description provided for @sibling_national_id_already_used.
  ///
  /// In ar, this message translates to:
  /// **'رقم هوية أحد الإخوة مسجل مسبقاً'**
  String get sibling_national_id_already_used;

  /// No description provided for @sibling_name_required_for_registration.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم كل أخ محدد للتسجيل'**
  String get sibling_name_required_for_registration;

  /// No description provided for @sibling_profile_missing_country.
  ///
  /// In ar, this message translates to:
  /// **'حدد البلد قبل تسجيل ملفات الإخوة'**
  String get sibling_profile_missing_country;

  /// No description provided for @sibling_profile_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم اليتيم في البرنامج'**
  String get sibling_profile_number;

  /// No description provided for @sibling_profile_not_saved.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التأكد من حفظ ملف أحد الإخوة'**
  String get sibling_profile_not_saved;

  /// No description provided for @sibling_profiles_created.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء ملفات الإخوة المحددين'**
  String get sibling_profiles_created;

  /// No description provided for @sibling_registration_all.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل جميع الإخوة'**
  String get sibling_registration_all;

  /// No description provided for @sibling_registration_confirmation_message.
  ///
  /// In ar, this message translates to:
  /// **'ستُحفظ بيانات الإخوة مع ملف اليتيم. اختر تسجيل المحددين أو تسجيل الجميع كملفات مستقلة.'**
  String get sibling_registration_confirmation_message;

  /// No description provided for @sibling_registration_confirmation_title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تسجيل الإخوة'**
  String get sibling_registration_confirmation_title;

  /// No description provided for @sibling_registration_save_only.
  ///
  /// In ar, this message translates to:
  /// **'حفظ بيانات الإخوة فقط'**
  String get sibling_registration_save_only;

  /// No description provided for @sibling_registration_selected.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الإخوة المحددين'**
  String get sibling_registration_selected;

  /// No description provided for @sibling_registration_selected_count.
  ///
  /// In ar, this message translates to:
  /// **'المحددون للتسجيل'**
  String get sibling_registration_selected_count;

  /// No description provided for @sibling_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get sibling_status;

  /// No description provided for @sibling_sponsorship_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة اليتيم'**
  String get sibling_sponsorship_status;

  /// No description provided for @sponsorship_candidate.
  ///
  /// In ar, this message translates to:
  /// **'مرشح للكفالة'**
  String get sponsorship_candidate;

  /// No description provided for @sibling_details_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بيانات الإخوة مع ملف اليتيم'**
  String get sibling_details_saved;

  /// No description provided for @register_all_siblings.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل جميع الإخوة في البرنامج'**
  String get register_all_siblings;

  /// No description provided for @register_sibling_as_child.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الأخ/الأخت كيتيم في البرنامج'**
  String get register_sibling_as_child;

  /// No description provided for @siblings_info.
  ///
  /// In ar, this message translates to:
  /// **'5. معلومات الأخوة'**
  String get siblings_info;

  /// No description provided for @siblings_info_header.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الأخوة'**
  String get siblings_info_header;

  /// No description provided for @siblings_information.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الأخوة'**
  String get siblings_information;

  /// No description provided for @sick.
  ///
  /// In ar, this message translates to:
  /// **'مريض'**
  String get sick;

  /// No description provided for @sidebar_cloud_sync.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة السحابية'**
  String get sidebar_cloud_sync;

  /// No description provided for @sidebar_create_profile.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ملف جديد'**
  String get sidebar_create_profile;

  /// No description provided for @sidebar_reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get sidebar_reports;

  /// No description provided for @sidebar_sponsors.
  ///
  /// In ar, this message translates to:
  /// **'الكفلاء'**
  String get sidebar_sponsors;

  /// No description provided for @sidebar_system.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get sidebar_system;

  /// No description provided for @sidebar_title.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأيتام'**
  String get sidebar_title;

  /// No description provided for @sister.
  ///
  /// In ar, this message translates to:
  /// **'الأخت'**
  String get sister;

  /// No description provided for @sponsor_actions_label.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get sponsor_actions_label;

  /// No description provided for @sponsor_added.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الكفيل'**
  String get sponsor_added;

  /// No description provided for @sponsor_amount_label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get sponsor_amount_label;

  /// No description provided for @sponsor_currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get sponsor_currency;

  /// No description provided for @sponsor_currency_label.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get sponsor_currency_label;

  /// No description provided for @sponsor_delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف الكفالة'**
  String get sponsor_delete;

  /// No description provided for @sponsor_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذفه'**
  String get sponsor_deleted;

  /// No description provided for @sponsor_edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الكفالة'**
  String get sponsor_edit;

  /// No description provided for @sponsor_edit_title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الكفيل'**
  String get sponsor_edit_title;

  /// No description provided for @sponsor_end_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء (YYYY-MM-DD)'**
  String get sponsor_end_date;

  /// No description provided for @sponsor_id_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الكفيل:'**
  String get sponsor_id_label;

  /// No description provided for @sponsor_info_title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الكفيل'**
  String get sponsor_info_title;

  /// No description provided for @sponsor_label.
  ///
  /// In ar, this message translates to:
  /// **'الكفيل'**
  String get sponsor_label;

  /// No description provided for @sponsor_monthly_amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الشهري'**
  String get sponsor_monthly_amount;

  /// No description provided for @sponsor_end_reason.
  ///
  /// In ar, this message translates to:
  /// **'سبب انتهاء الكفالة'**
  String get sponsor_end_reason;

  /// No description provided for @edit_currency_name.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم العملة'**
  String get edit_currency_name;

  /// No description provided for @sponsor_entity_type.
  ///
  /// In ar, this message translates to:
  /// **'الجهة الكافلة'**
  String get sponsor_entity_type;

  /// No description provided for @sponsor_individual.
  ///
  /// In ar, this message translates to:
  /// **'أفراد'**
  String get sponsor_individual;

  /// No description provided for @sponsor_institution.
  ///
  /// In ar, this message translates to:
  /// **'مؤسسة'**
  String get sponsor_institution;

  /// No description provided for @sponsor_institution_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم المؤسسة أو الجمعية'**
  String get sponsor_institution_name;

  /// No description provided for @sponsor_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكفيل'**
  String get sponsor_name;

  /// No description provided for @sponsor_name_field.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكفيل'**
  String get sponsor_name_field;

  /// No description provided for @sponsor_name_hint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: أحمد محمود'**
  String get sponsor_name_hint;

  /// No description provided for @sponsor_name_label.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكفيل'**
  String get sponsor_name_label;

  /// No description provided for @sponsor_new_name_dialog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كفيل جديد'**
  String get sponsor_new_name_dialog;

  /// No description provided for @sponsors_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الكفلاء'**
  String get sponsors_list;

  /// No description provided for @unknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get unknown;

  /// No description provided for @sponsor_ongoing_toggle.
  ///
  /// In ar, this message translates to:
  /// **'الكفالة مستمرة؟'**
  String get sponsor_ongoing_toggle;

  /// No description provided for @sponsor_section_title.
  ///
  /// In ar, this message translates to:
  /// **'الكفالة'**
  String get sponsor_section_title;

  /// No description provided for @sponsor_start_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get sponsor_start_date;

  /// No description provided for @sponsor_start_date_label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get sponsor_start_date_label;

  /// No description provided for @sponsor_status_ended.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الكفالة'**
  String get sponsor_status_ended;

  /// No description provided for @sponsor_status_label.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get sponsor_status_label;

  /// No description provided for @sponsor_status_ongoing.
  ///
  /// In ar, this message translates to:
  /// **'الكفالة مستمرة'**
  String get sponsor_status_ongoing;

  /// No description provided for @sponsor_table_actions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get sponsor_table_actions;

  /// No description provided for @sponsor_table_amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get sponsor_table_amount;

  /// No description provided for @sponsor_table_currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get sponsor_table_currency;

  /// No description provided for @sponsor_table_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get sponsor_table_name;

  /// No description provided for @sponsor_table_start_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get sponsor_table_start_date;

  /// No description provided for @sponsor_table_status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get sponsor_table_status;

  /// No description provided for @sponsored.
  ///
  /// In ar, this message translates to:
  /// **'مكفول'**
  String get sponsored;

  /// No description provided for @sponsored_children_title.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام المكفولون'**
  String get sponsored_children_title;

  /// No description provided for @sponsored_label.
  ///
  /// In ar, this message translates to:
  /// **'المكفولين'**
  String get sponsored_label;

  /// No description provided for @sponsored_orphans_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأيتام المكفولين'**
  String get sponsored_orphans_list;

  /// No description provided for @sponsorship_date_label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الكفالة'**
  String get sponsorship_date_label;

  /// No description provided for @sponsorship_end_date_label.
  ///
  /// In ar, this message translates to:
  /// **'نهاية الكفالة:'**
  String get sponsorship_end_date_label;

  /// No description provided for @sponsorship_report_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الكفالة'**
  String get sponsorship_report_title;

  /// No description provided for @sponsorship_section_title.
  ///
  /// In ar, this message translates to:
  /// **'قسم الكفالة'**
  String get sponsorship_section_title;

  /// No description provided for @sponsorship_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الكفالة'**
  String get sponsorship_number;

  /// No description provided for @sponsorship_end_reason.
  ///
  /// In ar, this message translates to:
  /// **'سبب انتهاء الكفالة'**
  String get sponsorship_end_reason;

  /// No description provided for @page_label.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get page_label;

  /// No description provided for @of_label.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get of_label;

  /// No description provided for @organization_full_name.
  ///
  /// In ar, this message translates to:
  /// **'جمعية إحسان للتكافل الإنساني'**
  String get organization_full_name;

  /// No description provided for @sponsorship_start_date_label.
  ///
  /// In ar, this message translates to:
  /// **'بداية الكفالة:'**
  String get sponsorship_start_date_label;

  /// No description provided for @status_label.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status_label;

  /// No description provided for @step_1_basic_family.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الأساسية والعائلة'**
  String get step_1_basic_family;

  /// No description provided for @step_2_education_health.
  ///
  /// In ar, this message translates to:
  /// **'التعليم والصحة'**
  String get step_2_education_health;

  /// No description provided for @step_3_documents.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get step_3_documents;

  /// No description provided for @step_4_sponsorship.
  ///
  /// In ar, this message translates to:
  /// **'الكفالة'**
  String get step_4_sponsorship;

  /// No description provided for @step_5_payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get step_5_payments;

  /// No description provided for @step_6_reporting.
  ///
  /// In ar, this message translates to:
  /// **'الاستمارة'**
  String get step_6_reporting;

  /// No description provided for @step_basic_info.
  ///
  /// In ar, this message translates to:
  /// **'1. المعلومات الأساسية'**
  String get step_basic_info;

  /// No description provided for @step_documents.
  ///
  /// In ar, this message translates to:
  /// **'2. التعليم'**
  String get step_documents;

  /// No description provided for @step_education_health.
  ///
  /// In ar, this message translates to:
  /// **'التعليم والصحة'**
  String get step_education_health;

  /// No description provided for @step_health_family.
  ///
  /// In ar, this message translates to:
  /// **'3. الصحة والعائلة'**
  String get step_health_family;

  /// No description provided for @step_number.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step} من {total}'**
  String step_number(Object step, Object total);

  /// No description provided for @street.
  ///
  /// In ar, this message translates to:
  /// **'العنوان التفصيلي'**
  String get street;

  /// No description provided for @total_amount_paid_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبلغ المدفوع:'**
  String get total_amount_paid_label;

  /// No description provided for @total_orphans_count.
  ///
  /// In ar, this message translates to:
  /// **'العدد الإجمالي'**
  String get total_orphans_count;

  /// No description provided for @total_orphans_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام'**
  String get total_orphans_label;

  /// No description provided for @total_sponsored_children_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام المكفولين'**
  String get total_sponsored_children_label;

  /// No description provided for @total_sponsors_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الكفلاء'**
  String get total_sponsors_label;

  /// No description provided for @total_unsponsored_children_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام غير المكفولين'**
  String get total_unsponsored_children_label;

  /// No description provided for @total_unsponsored_label.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام غير المكفولين'**
  String get total_unsponsored_label;

  /// No description provided for @town.
  ///
  /// In ar, this message translates to:
  /// **'الحي'**
  String get town;

  /// No description provided for @uncle.
  ///
  /// In ar, this message translates to:
  /// **'العم'**
  String get uncle;

  /// No description provided for @college_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الكلية'**
  String get college_name;

  /// No description provided for @specialization_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم التخصص'**
  String get specialization_name;

  /// No description provided for @university_college_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجامعة/الكلية'**
  String get university_college_name;

  /// No description provided for @university_diploma.
  ///
  /// In ar, this message translates to:
  /// **'الدبلوم'**
  String get university_diploma;

  /// No description provided for @university_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجامعة'**
  String get university_name;

  /// No description provided for @university_year.
  ///
  /// In ar, this message translates to:
  /// **'السنة الجامعية'**
  String get university_year;

  /// No description provided for @unsponsored_children_list_title.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأيتام غير المكفولين'**
  String get unsponsored_children_list_title;

  /// No description provided for @unsponsored_children_report_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الأيتام غير المكفولين'**
  String get unsponsored_children_report_title;

  /// No description provided for @unsponsored_label.
  ///
  /// In ar, this message translates to:
  /// **'غير المكفولين'**
  String get unsponsored_label;

  /// No description provided for @unsponsored_orphans_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأيتام غير المكفولين'**
  String get unsponsored_orphans_list;

  /// No description provided for @upload_button.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get upload_button;

  /// No description provided for @upload_certificate.
  ///
  /// In ar, this message translates to:
  /// **'الشهادة الدراسية'**
  String get upload_certificate;

  /// No description provided for @upload_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحميل'**
  String get upload_failed;

  /// No description provided for @upload_medical_report.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق التقرير الطبي'**
  String get upload_medical_report;

  /// No description provided for @uploaded_documents.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات المحملة'**
  String get uploaded_documents;

  /// No description provided for @uploaded_medical_reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير الطبية المرفقة'**
  String get uploaded_medical_reports;

  /// No description provided for @year_1.
  ///
  /// In ar, this message translates to:
  /// **'سنة أولى'**
  String get year_1;

  /// No description provided for @year_2.
  ///
  /// In ar, this message translates to:
  /// **'سنة ثانية'**
  String get year_2;

  /// No description provided for @year_3.
  ///
  /// In ar, this message translates to:
  /// **'سنة ثالثة'**
  String get year_3;

  /// No description provided for @year_4.
  ///
  /// In ar, this message translates to:
  /// **'سنة رابعة'**
  String get year_4;

  /// No description provided for @year_5.
  ///
  /// In ar, this message translates to:
  /// **'سنة خامسة'**
  String get year_5;

  /// No description provided for @year_6.
  ///
  /// In ar, this message translates to:
  /// **'سنة سادسة'**
  String get year_6;

  /// No description provided for @year_graduate.
  ///
  /// In ar, this message translates to:
  /// **'خريج'**
  String get year_graduate;

  /// No description provided for @year_label.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get year_label;

  /// No description provided for @years.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get years;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @report_single_orphan_category.
  ///
  /// In ar, this message translates to:
  /// **'تقرير اليتيم الفردي'**
  String get report_single_orphan_category;

  /// No description provided for @report_general_orphans_category.
  ///
  /// In ar, this message translates to:
  /// **'تقارير الأيتام'**
  String get report_general_orphans_category;

  /// No description provided for @report_registered_unsponsored.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام المسجلون بدون كفالة'**
  String get report_registered_unsponsored;

  /// No description provided for @report_unregistered_unsponsored.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام غير المسجلين بدون كفالة'**
  String get report_unregistered_unsponsored;

  /// No description provided for @report_unregistered_unsponsored_desc.
  ///
  /// In ar, this message translates to:
  /// **'معلومات عن الأيتام غير المسجلين بدون كفالة'**
  String get report_unregistered_unsponsored_desc;

  /// No description provided for @report_sponsors_category.
  ///
  /// In ar, this message translates to:
  /// **'تقارير الكفلاء'**
  String get report_sponsors_category;

  /// No description provided for @report_sponsor_summary.
  ///
  /// In ar, this message translates to:
  /// **'تقرير ملخص الكفيل'**
  String get report_sponsor_summary;

  /// No description provided for @report_sponsor_summary_desc.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الكفيل وملخص الأيتام المكفولين'**
  String get report_sponsor_summary_desc;

  /// No description provided for @report_sponsor_detailed.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الكفيل التفصيلي'**
  String get report_sponsor_detailed;

  /// No description provided for @report_sponsor_detailed_desc.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الكفيل الكاملة والمدفوعات'**
  String get report_sponsor_detailed_desc;

  /// No description provided for @report_sponsored_orphans_desc.
  ///
  /// In ar, this message translates to:
  /// **'معلومات مفصلة عن الأيتام المكفولين'**
  String get report_sponsored_orphans_desc;

  /// No description provided for @range_label.
  ///
  /// In ar, this message translates to:
  /// **'نطاق التاريخ'**
  String get range_label;

  /// No description provided for @yearly_label.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get yearly_label;

  /// No description provided for @from_label.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get from_label;

  /// No description provided for @to_label.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get to_label;

  /// No description provided for @date_placeholder.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ'**
  String get date_placeholder;

  /// No description provided for @select_button.
  ///
  /// In ar, this message translates to:
  /// **'اختر'**
  String get select_button;

  /// No description provided for @no_unsponsored_siblings_found.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على إخوة بدون كفالة'**
  String get no_unsponsored_siblings_found;

  /// No description provided for @report_start_date_colon.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية:'**
  String get report_start_date_colon;

  /// No description provided for @report_sponsored_orphans.
  ///
  /// In ar, this message translates to:
  /// **'الأيتام المكفولون'**
  String get report_sponsored_orphans;

  /// No description provided for @report_sponsorship_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الكفالة'**
  String get report_sponsorship_date;

  /// No description provided for @contact_info_title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الاتصال'**
  String get contact_info_title;

  /// No description provided for @date_end.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get date_end;

  /// No description provided for @monthly_report_info_title.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التقرير الشهري'**
  String get monthly_report_info_title;

  /// No description provided for @report_sponsorship_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الكفالة'**
  String get report_sponsorship_title;

  /// No description provided for @select_export_location.
  ///
  /// In ar, this message translates to:
  /// **'اختر مجلد التصدير'**
  String get select_export_location;

  /// No description provided for @payment_amount_label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get payment_amount_label;

  /// No description provided for @payment_currency_label.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get payment_currency_label;

  /// No description provided for @payment_date_label.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get payment_date_label;

  /// No description provided for @child_payments_table_title.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل جميع الدفعات'**
  String get child_payments_table_title;

  /// No description provided for @payment_totals_by_currency.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الدفعات حسب العملة'**
  String get payment_totals_by_currency;

  /// No description provided for @no_payments_found.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد دفعات مسجلة'**
  String get no_payments_found;

  /// No description provided for @total_label.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total_label;

  /// No description provided for @orphan_financial_report.
  ///
  /// In ar, this message translates to:
  /// **'التقرير المالي لليتيم'**
  String get orphan_financial_report;

  /// No description provided for @orphan_financial_report_desc.
  ///
  /// In ar, this message translates to:
  /// **'تقرير اليتيم مع جدول الدفعات المالية المستلمة'**
  String get orphan_financial_report_desc;

  /// No description provided for @received_payments_table.
  ///
  /// In ar, this message translates to:
  /// **'جدول الدفعات المالية المستلمة'**
  String get received_payments_table;

  /// No description provided for @report_sponsored_orphans_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الأيتام المكفولين'**
  String get report_sponsored_orphans_title;

  /// No description provided for @report_sponsored_orphans_list.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأيتام المكفولين'**
  String get report_sponsored_orphans_list;

  /// No description provided for @time_period_label.
  ///
  /// In ar, this message translates to:
  /// **'الفترة الزمنية'**
  String get time_period_label;

  /// No description provided for @total_records.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي السجلات'**
  String get total_records;

  /// No description provided for @registered_sibling.
  ///
  /// In ar, this message translates to:
  /// **'الأخ المسجل'**
  String get registered_sibling;

  /// No description provided for @amount_paid_label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get amount_paid_label;

  /// No description provided for @year.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get year;

  /// No description provided for @for_year.
  ///
  /// In ar, this message translates to:
  /// **'للسنة'**
  String get for_year;

  /// No description provided for @report_date_label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التقرير'**
  String get report_date_label;

  /// No description provided for @second_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الثاني (الأب)'**
  String get second_name;

  /// No description provided for @third_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الثالث (الجد)'**
  String get third_name;

  /// No description provided for @residence_info.
  ///
  /// In ar, this message translates to:
  /// **'بيانات السكن'**
  String get residence_info;

  /// No description provided for @birth_place_info.
  ///
  /// In ar, this message translates to:
  /// **'مكان الميلاد'**
  String get birth_place_info;

  /// No description provided for @birth_country.
  ///
  /// In ar, this message translates to:
  /// **'دولة الولادة'**
  String get birth_country;

  /// No description provided for @birth_city.
  ///
  /// In ar, this message translates to:
  /// **'مدينة الولادة'**
  String get birth_city;

  /// No description provided for @father_triple_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأب ثلاثي'**
  String get father_triple_name;

  /// No description provided for @mother_triple_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الأم ثلاثي'**
  String get mother_triple_name;

  /// No description provided for @guardian_triple_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الولي ثلاثي'**
  String get guardian_triple_name;

  /// No description provided for @auto_calculated_father_hint.
  ///
  /// In ar, this message translates to:
  /// **'يتم توليده تلقائياً من اسم الطفل'**
  String get auto_calculated_father_hint;

  /// No description provided for @financial_info.
  ///
  /// In ar, this message translates to:
  /// **'البيانات المالية'**
  String get financial_info;

  /// No description provided for @payment_method.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get payment_method;

  /// No description provided for @payment_method_bank.
  ///
  /// In ar, this message translates to:
  /// **'البنك'**
  String get payment_method_bank;

  /// No description provided for @payment_method_wallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get payment_method_wallet;

  /// No description provided for @linked_mobile_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل المرتبط بالحساب'**
  String get linked_mobile_number;

  /// No description provided for @wallet_holder_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب المحفظة'**
  String get wallet_holder_name;

  /// No description provided for @attachment_category.
  ///
  /// In ar, this message translates to:
  /// **'نوع المرفقات'**
  String get attachment_category;

  /// No description provided for @attachment_family.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات العائلة'**
  String get attachment_family;

  /// No description provided for @attachment_guardian.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات الولي'**
  String get attachment_guardian;

  /// No description provided for @attachment_education.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات الدراسية'**
  String get attachment_education;

  /// No description provided for @attachment_medical.
  ///
  /// In ar, this message translates to:
  /// **'التقارير الطبية'**
  String get attachment_medical;

  /// No description provided for @attachment_other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get attachment_other;

  /// No description provided for @other_attachments.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات أخرى'**
  String get other_attachments;

  /// No description provided for @folder_personal_photos.
  ///
  /// In ar, this message translates to:
  /// **'الصور الشخصية'**
  String get folder_personal_photos;

  /// No description provided for @folder_birth_certificates.
  ///
  /// In ar, this message translates to:
  /// **'شهادة الميلاد'**
  String get folder_birth_certificates;

  /// No description provided for @folder_guardianship_deed.
  ///
  /// In ar, this message translates to:
  /// **'حجة الولاية'**
  String get folder_guardianship_deed;

  /// No description provided for @uploaded_on.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الرفع'**
  String get uploaded_on;

  /// No description provided for @latest_photo.
  ///
  /// In ar, this message translates to:
  /// **'الصورة الأحدث'**
  String get latest_photo;

  /// No description provided for @attachment_upload_failed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر رفع المرفق'**
  String get attachment_upload_failed;

  /// No description provided for @sponsors_pyramid_title.
  ///
  /// In ar, this message translates to:
  /// **'الهيكل الهرمي لإحصائيات الكفلاء'**
  String get sponsors_pyramid_title;

  /// No description provided for @sponsors_pyramid_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'توزيع الكفلاء بين مؤسسات وأفراد مع أعداد المكفولين والمرشحين'**
  String get sponsors_pyramid_subtitle;

  /// No description provided for @clear_filter_show_all.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التصفية (عرض الكل)'**
  String get clear_filter_show_all;

  /// No description provided for @collapse_pyramid.
  ///
  /// In ar, this message translates to:
  /// **'طي الهرم'**
  String get collapse_pyramid;

  /// No description provided for @expand_pyramid.
  ///
  /// In ar, this message translates to:
  /// **'توسيع الهرم'**
  String get expand_pyramid;

  /// No description provided for @total_registered_sponsors.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الكفلاء المسجلين'**
  String get total_registered_sponsors;

  /// No description provided for @sponsored_count_label.
  ///
  /// In ar, this message translates to:
  /// **'عدد المكفولين'**
  String get sponsored_count_label;

  /// No description provided for @candidates_count_label.
  ///
  /// In ar, this message translates to:
  /// **'عدد المرشحين للكفالة'**
  String get candidates_count_label;

  /// No description provided for @sponsor_institutions.
  ///
  /// In ar, this message translates to:
  /// **'مؤسسات'**
  String get sponsor_institutions;

  /// No description provided for @sponsor_individuals.
  ///
  /// In ar, this message translates to:
  /// **'أفراد'**
  String get sponsor_individuals;

  /// No description provided for @unit_institution.
  ///
  /// In ar, this message translates to:
  /// **'مؤسسة'**
  String get unit_institution;

  /// No description provided for @unit_individual.
  ///
  /// In ar, this message translates to:
  /// **'فرد'**
  String get unit_individual;

  /// No description provided for @collapse_list.
  ///
  /// In ar, this message translates to:
  /// **'طي القائمة'**
  String get collapse_list;

  /// No description provided for @expand_list.
  ///
  /// In ar, this message translates to:
  /// **'توسيع القائمة'**
  String get expand_list;

  /// No description provided for @no_institutions_registered.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مؤسسات مسجلة حالياً'**
  String get no_institutions_registered;

  /// No description provided for @no_individuals_registered.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أفراد مسجلين حالياً'**
  String get no_individuals_registered;

  /// No description provided for @add_institution.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مؤسسة'**
  String get add_institution;

  /// No description provided for @add_individual.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فرد'**
  String get add_individual;

  /// No description provided for @view_sponsor_details.
  ///
  /// In ar, this message translates to:
  /// **'عرض تفاصيل الكفيل'**
  String get view_sponsor_details;

  /// No description provided for @candidates_label.
  ///
  /// In ar, this message translates to:
  /// **'المرشحين'**
  String get candidates_label;

  /// No description provided for @filter_institutions.
  ///
  /// In ar, this message translates to:
  /// **'تصفية: مؤسسات'**
  String get filter_institutions;

  /// No description provided for @filter_individuals.
  ///
  /// In ar, this message translates to:
  /// **'تصفية: أفراد'**
  String get filter_individuals;

  /// No description provided for @filter_by_selected_sponsor.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الكفيل المحدد'**
  String get filter_by_selected_sponsor;

  /// No description provided for @show_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get show_all;

  /// No description provided for @report_all_orphans_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الأيتام'**
  String get report_all_orphans_title;

  /// No description provided for @report_all_sponsors_title.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جميع الكفلاء'**
  String get report_all_sponsors_title;

  /// No description provided for @total_registered_orphans.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأيتام المسجلين'**
  String get total_registered_orphans;

  /// No description provided for @total_candidates_label.
  ///
  /// In ar, this message translates to:
  /// **'مرشحون للكفالة'**
  String get total_candidates_label;

  /// No description provided for @active_sponsorships_label.
  ///
  /// In ar, this message translates to:
  /// **'الكفالة مستمرة'**
  String get active_sponsorships_label;

  /// No description provided for @ended_sponsorships_label.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الكفالة'**
  String get ended_sponsorships_label;

  String get bulk_edit_selected;

  String get bulk_select_siblings;

  String get select_all_shown;

  String get clear_selection;

  String get selected_count;

  String get family_info;

  String get address_info;

  String get sponsorship_unchanged;

  String get remove_sponsorship;

  String get bulk_edit_empty_unchanged;

  String get bulk_update_success;

  String get bulk_update_failed;

  String get sponsor_not_found;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
