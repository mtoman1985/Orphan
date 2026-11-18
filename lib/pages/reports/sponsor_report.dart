import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart' as material;
import '../../models/sponsor.dart';
import '../../models/child.dart';
import '../../models/payment.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';
import 'package:orphan/services/arabic_font_loader.dart';
import 'package:orphan/services/multilang_transliterator.dart';
import 'package:intl/intl.dart' as intl;
import 'report_shared_widgets.dart';

class SponsorReportPDF {
  static Future<void> generateMonthlyReport(
    Sponsor sponsor,
    List<Child> children,
    DateTime month, {
    BuildContext? context,
    required material.Locale locale,
    String reportType = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
    Map<String, List<Payment>>? paymentsMap,
  }) async {
    try {
      final report = MonthlySponsorReport(
        sponsor: sponsor,
        children: children,
        month: month,
        locale: locale,
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        paymentsMap: paymentsMap,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Monthly_Report_${sponsor.name}.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateSponsorshipReport(
    Sponsor sponsor,
    List<Child> children, {
    BuildContext? context,
    required material.Locale locale,
    String reportType = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
    DateTime? month,
    Map<String, List<Payment>>? paymentsMap,
  }) async {
    try {
      final report = SponsorshipDetailReport(
        sponsor: sponsor,
        children: children,
        locale: locale,
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        month: month,
        paymentsMap: paymentsMap,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Sponsorship_Report_${sponsor.name}.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateUnSponsoredChildrenReport(
    List<Child> children,
    DateTime reportDate, {
    BuildContext? context,
    required material.Locale locale,
    List<String>? selectedColumns,
  }) async {
    try {
      final report = UnSponsoredChildrenReport(
        children: children,
        reportDate: reportDate,
        locale: locale,
        selectedColumns: selectedColumns,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Unsponsored_Children_Report.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateAllOrphansReport(
    List<Child> children,
    DateTime reportDate, {
    BuildContext? context,
    required material.Locale locale,
    List<String>? selectedColumns,
  }) async {
    try {
      final report = AllOrphansReport(
        children: children,
        reportDate: reportDate,
        locale: locale,
        selectedColumns: selectedColumns,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'All_Orphans_Report.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateAllSponsorsReport(
    List<Sponsor> sponsors,
    List<Child> children,
    DateTime reportDate, {
    BuildContext? context,
    required material.Locale locale,
  }) async {
    try {
      final report = AllSponsorsReport(
        sponsors: sponsors,
        children: children,
        reportDate: reportDate,
        locale: locale,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'All_Sponsors_Report.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateSponsoredOrphansReport(
    List<Child> children,
    DateTime reportDate, {
    BuildContext? context,
    required material.Locale locale,
    List<String>? selectedColumns,
  }) async {
    try {
      final report = SponsoredOrphansReport(
        children: children,
        reportDate: reportDate,
        locale: locale,
        selectedColumns: selectedColumns,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Sponsored_Orphans_Report.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }

  static Future<void> generateUnregisteredUnsponsoredReport(
    List<Map<String, dynamic>> unregisteredSiblings,
    DateTime reportDate, {
    BuildContext? context,
    required material.Locale locale,
  }) async {
    try {
      final report = UnregisteredUnsponsoredSiblingsReport(
        unregisteredSiblings: unregisteredSiblings,
        reportDate: reportDate,
        locale: locale,
      );
      final bytes = await report.generatePdfBytes(locale);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Unregistered_Unsponsored_Report.pdf',
      );
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (context != null && context.mounted) {
        final l = lookupAppLocalizations(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.getKey('pdf_generation_failed')}: $e')),
        );
      }
    }
  }
}

/// Monthly sponsorship payment report
class MonthlySponsorReport {
  /// التحقق من أن تاريخ الدفع يقع ضمن نطاق التقرير
  bool _isPaymentInDateRange(DateTime paymentDate) {
    if (reportType == 'monthly') {
      // تحقق من أن الدفع في نفس الشهر والسنة
      return paymentDate.year == month.year && paymentDate.month == month.month;
    } else if (reportType == 'yearly') {
      // تحقق من أن الدفع في نفس السنة
      return paymentDate.year == month.year;
    } else if (reportType == 'range' && startDate != null && endDate != null) {
      // تحقق من أن الدفع بين startDate و endDate
      return paymentDate.isAfter(startDate!) &&
          paymentDate.isBefore(endDate!.add(Duration(days: 1)));
    }
    return true;
  }

  /// جدول شامل لجميع الدفعات مع اسم الطفل والتاريخ والمبلغ والعملة
  List<pw.Widget> _buildAllPaymentsTable(
    AppLocalizations l,
    pw.Context context,
  ) {
    final widgets = <pw.Widget>[];

    // جمع جميع الدفعات من جميع الأطفال وتصفيتها حسب النطاق الزمني
    final allPayments = <Map<String, dynamic>>[];

    if (paymentsMap != null) {
      for (final child in children) {
        final payments = paymentsMap![child.id] ?? [];
        for (final payment in payments) {
          // تصفية الدفعات حسب النطاق الزمني المحدد
          if (_isPaymentInDateRange(payment.paidAt)) {
            allPayments.add({
              'childName': child.getFullNameByLanguage(locale.languageCode),
              'childId': child.childIdNumber,
              'amount': payment.amount,
              'currency': payment.currency ?? 'شيكل',
              'date': payment.paidAt,
            });
          }
        }
      }
    }

    if (allPayments.isEmpty) {
      widgets.add(
        pw.Text(
          l.getKey('no_payments_found') ?? 'لا يوجد دفعات مسجلة.',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            font: arabicFont,
          ),
        ),
      );
      return widgets;
    }

    // ترتيب الدفعات: أولاً حسب اسم الطفل، ثم حسب التاريخ
    allPayments.sort((a, b) {
      final nameComparison = (a['childName'] as String).compareTo(
        b['childName'] as String,
      );
      if (nameComparison != 0) return nameComparison;
      return (b['date'] as DateTime).compareTo(a['date'] as DateTime);
    });

    final isRtl = locale.languageCode == 'ar';
    // Build ordered columns based on direction
    List<String> orderedColumns;
    final headersMap = {
      'child': l.getKey('child_name_label') ?? 'اسم الطفل',
      'date': l.getKey('payment_date_label') ?? 'التاريخ',
      'currency': l.getKey('payment_currency_label') ?? 'العملة',
      'amount': l.getKey('payment_amount_label') ?? 'المبلغ',
    };

    // عنوان الجدول
    widgets.add(
      pw.Text(
        l.getKey('child_payments_table_title') ?? 'تفاصيل جميع الدفعات:',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
          font: arabicBoldFont,
          color: PdfColors.blue900,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    if (isRtl) {
      orderedColumns = ['amount', 'currency', 'date', 'child'];
    } else {
      orderedColumns = ['child', 'date', 'currency', 'amount'];
    }

    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < orderedColumns.length; i++) {
      columnWidths[i] = const pw.FlexColumnWidth(1.0);
    }

    // Build headers list (RTL order already applied via orderedColumns)
    final headers = orderedColumns.map((key) => headersMap[key]!).toList();

    // Build data rows as string lists
    String? lastChildName;
    final List<List<String>> data = [];
    for (final p in allPayments) {
      final childName = p['childName'] as String;
      final displayName = childName == lastChildName ? '' : childName;
      lastChildName = childName;

      final currencyCode = p['currency'] as String;
      final sponsorModel = Sponsor(
        id: sponsor.id,
        name: sponsor.name,
        amount: 0,
        startDate: sponsor.startDate,
        currency: currencyCode,
      );
      final currencyDisplay = sponsorModel.getCurrencyByLanguage(
        locale.languageCode,
      );

      data.add(
        orderedColumns.map((key) {
          switch (key) {
            case 'child':
              return displayName;
            case 'date':
              return _formatDate(p['date'] as DateTime, l);
            case 'currency':
              return currencyDisplay;
            case 'amount':
              return (p['amount'] as double).toStringAsFixed(2);
            default:
              return '';
          }
        }).toList(),
      );
    }

    // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
    widgets.add(
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
        columnWidths: columnWidths,
      ),
    );

    return widgets;
  }

  final Sponsor sponsor;
  final List<Child> children;
  final DateTime month;
  final material.Locale locale;
  final String reportType; // 'monthly', 'yearly', 'range'
  final DateTime? startDate;
  final DateTime? endDate;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  final Map<String, List<Payment>>? paymentsMap;

  MonthlySponsorReport({
    required this.sponsor,
    required this.children,
    required this.month,
    required this.locale,
    this.reportType = 'monthly',
    this.startDate,
    this.endDate,
    this.paymentsMap,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  /// الحصول على محاذاة النص بناءً على اللغة
  pw.TextAlign _getTextAlign() {
    return locale.languageCode == 'ar' ? pw.TextAlign.right : pw.TextAlign.left;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    // Load logo
    final logo = await ArabicFontLoader.loadLogo();

    // Calculate monthly data
    final monthlyData = _calculateMonthlyData();
    final currencyTotals = monthlyData['currencyTotals'] as Map<String, double>;
    final hasMixedCurrencies = monthlyData['hasMixedCurrencies'] as bool;
    final entries = monthlyData['entries'] as List<Map<String, dynamic>>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'monthly_report_title',
                overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
              ),
              pw.SizedBox(height: 2),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (context) {
          return [
            pw.SizedBox(height: 5),
            _buildMonthlyInfo(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 15),
            _buildSponsorInfo(l, arabicFont, arabicBoldFont),
            /*             pw.SizedBox(height: 15),
            ..._buildMonthlyTransactions(
              l,
              entries,
              arabicFont,
              arabicBoldFont,
            ), */
            pw.SizedBox(height: 15),
            //// جدول الدفعات الشامل لجميع الأطفال
            ..._buildAllPaymentsTable(l, context),
            pw.SizedBox(height: 15),
            ..._buildMonthlyTotalByCurrency(
              l,
              currencyTotals,
              hasMixedCurrencies,
              arabicFont,
              arabicBoldFont,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Helper to match child to sponsor with robust checks
  bool _isSponsoredByThisSponsor(Child child) {
    if (child.sponsor == null) return false;

    final childSponsor = child.sponsor!;

    // Match by ID (primary method - most reliable)
    if (childSponsor.id != null &&
        sponsor.id != null &&
        childSponsor.id!.isNotEmpty &&
        sponsor.id!.isNotEmpty) {
      if (childSponsor.id == sponsor.id) return true;
    }

    // Match by name (case-insensitive fallback for reliability)
    if (childSponsor.name.isNotEmpty && sponsor.name.isNotEmpty) {
      if (childSponsor.name.trim().toLowerCase() ==
          sponsor.name.trim().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  Map<String, dynamic> _calculateMonthlyData() {
    List<Map<String, dynamic>> entries = [];
    // Group amounts by currency to avoid mixing different currencies
    Map<String, double> currencyTotals = {};

    // Calculate totals from actual payments (filtered by date range)
    if (paymentsMap != null) {
      for (var child in children) {
        if (_isSponsoredByThisSponsor(child)) {
          final payments = paymentsMap![child.id] ?? [];

          for (final payment in payments) {
            // تطبيق معايير الفلترة الزمنية (شهري/سنوي/نطاق)
            if (_isPaymentInDateRange(payment.paidAt)) {
              final currency = payment.currency ?? 'شيكل';
              currencyTotals[currency] =
                  (currencyTotals[currency] ?? 0) + payment.amount;
            }
          }
        }
      }
    } else {
      // Fallback to old method if paymentsMap is not available
      for (var child in children) {
        if (_isSponsoredByThisSponsor(child)) {
          final amount = child.sponsor?.amount ?? 0;
          final currency = child.sponsor?.currency ?? 'شيكل';

          // Add to currency-specific total (don't mix currencies)
          currencyTotals[currency] = (currencyTotals[currency] ?? 0) + amount;
        }
      }
    }

    // Build entries list for display (from sponsor amount as before)
    for (var child in children) {
      if (_isSponsoredByThisSponsor(child)) {
        final amount = child.sponsor?.amount ?? 0;
        final currency = child.sponsor?.currency ?? 'شيكل';

        entries.add({
          'childName': child.getFullNameByLanguage(locale.languageCode),
          'childId': child.childIdNumber,
          'amount': amount,
          'currency': currency,
        });
      }
    }

    return {
      'entries': entries,
      'currencyTotals': currencyTotals,
      'hasMixedCurrencies': currencyTotals.length > 1,
    };
  }

  pw.Widget _buildMonthlyInfo(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    final isRtl = locale.languageCode == 'ar';

    String timePeriodText = '';
    if (reportType == 'yearly') {
      // سنة [2026] / Year [2026]
      timePeriodText = '${l.getKey('year')} [${month.year}]';
    } else if (reportType == 'range' && startDate != null && endDate != null) {
      // من [start_date] إلى [end_date] / From [start_date] to [end_date]
      final startStr = _formatDate(startDate!, l);
      final endStr = _formatDate(endDate!, l);
      timePeriodText =
          '${l.getKey('from_label')} $startStr ${l.getKey('to_label')} $endStr';
    } else {
      // شهر [2] لعام [2026] (شهر February 2026) / Month [2] for Year [2026]
      final monthName = _getMonthName(month, l);
      timePeriodText = '$monthName ${month.year}';
    }

    final createdDate = DateTime.now().toString().split(' ')[0];

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment:
            isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${l.getKey('time_period_label')}: $timePeriodText',
                  style: pw.TextStyle(fontSize: 11, font: arabicFont),
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${l.getKey('monthly_report_creation_date')} $createdDate',
                  style: pw.TextStyle(fontSize: 11, font: arabicFont),
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSponsorInfo(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l.getKey('sponsor_info_title'),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
              font: arabicBoldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  l.getKey('report_sponsor_name_colon'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: arabicBoldFont,
                  ),
                  textAlign: _getTextAlign(),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  sponsor.getNameByLanguage(locale.languageCode),
                  style: pw.TextStyle(font: arabicFont),
                  textAlign: _getTextAlign(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  l.getKey('monthly_report_creation_date'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: arabicBoldFont,
                  ),
                  textAlign: _getTextAlign(),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  sponsor.createdAt.toString().split(' ')[0],
                  style: pw.TextStyle(font: arabicFont),
                  textAlign: _getTextAlign(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildMonthlyTransactions(
    AppLocalizations l,
    List<Map<String, dynamic>> entries,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';

    final headers =
        isRtl
            ? [
              l.getKey('amount_paid_label'),
              l.getKey('child_name_label'),
              l.getKey('child_id_label'),
            ]
            : [
              l.getKey('child_id_label'),
              l.getKey('child_name_label'),
              l.getKey('amount_paid_label'),
            ];

    // Build data rows with currency from each entry
    final data =
        entries.map((entry) {
          final currency = entry['currency'] as String? ?? 'شيكل';
          final sponsorModel = Sponsor(
            id: sponsor.id,
            name: sponsor.name,
            amount: 0,
            startDate: sponsor.startDate,
            currency: currency,
          );
          final row = [
            entry['childId'] as String,
            entry['childName'] as String,
            '${(entry['amount'] as double).toStringAsFixed(2)} ${sponsorModel.getCurrencyByLanguage(locale.languageCode)}',
          ];
          return isRtl ? row.reversed.toList() : row;
        }).toList();

    return [
      pw.Text(
        l.getKey('children_and_amounts_title'),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
          font: arabicBoldFont,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: arabicBoldFont,
          fontSize: 10,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
        cellAlignments:
            isRtl
                ? {
                  0: pw.Alignment.centerRight,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.center,
                }
                : {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                },
      ),
      if (entries.isEmpty)
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Text(
            l.getKey('no_transactions_this_month'),
            style: pw.TextStyle(color: PdfColors.grey600),
          ),
        ),
    ];
  }

  /// Build total amounts grouped by currency to prevent mixing different currencies
  List<pw.Widget> _buildMonthlyTotalByCurrency(
    AppLocalizations l,
    Map<String, double> currencyTotals,
    bool hasMixedCurrencies,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    if (currencyTotals.isEmpty) {
      return [];
    }

    final widgets = <pw.Widget>[];

    // Display total for each currency separately
    for (var currency in currencyTotals.keys) {
      final amount = currencyTotals[currency]!;
      final sponsorModel = Sponsor(
        id: sponsor.id,
        name: sponsor.name,
        amount: amount,
        startDate: sponsor.startDate,
        currency: currency,
      );

      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          margin: pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green400, width: 2),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                l.getKey('total_amount_paid_label'),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                  font: arabicFont,
                ),
              ),
              pw.Text(
                '${amount.toStringAsFixed(2)} ${sponsorModel.getCurrencyByLanguage(locale.languageCode)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                  font: arabicFont,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _getMonthName(DateTime date, AppLocalizations l) {
    final monthKey = 'month_${date.month.toString().padLeft(2, '0')}';
    return l.getKey(monthKey);
  }

  String _formatDate(DateTime date, AppLocalizations l) {
    final monthKey = 'month_${date.month.toString().padLeft(2, '0')}';
    return '${date.day} ${l.getKey(monthKey)} ${date.year}';
  }
}

/// Detailed sponsorship information report
class SponsorshipDetailReport {
  final Sponsor sponsor;
  final List<Child> children;
  final material.Locale locale;
  final String reportType; // 'monthly', 'yearly', 'range'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? month;
  final Map<String, List<Payment>>? paymentsMap;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  SponsorshipDetailReport({
    required this.sponsor,
    required this.children,
    required this.locale,
    this.reportType = 'monthly',
    this.startDate,
    this.endDate,
    this.month,
    this.paymentsMap,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  /// الحصول على محاذاة النص بناءً على اللغة
  pw.TextAlign _getTextAlign() {
    return locale.languageCode == 'ar' ? pw.TextAlign.right : pw.TextAlign.left;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    // Load logo
    final logo = await ArabicFontLoader.loadLogo();

    // Get sponsored children
    final sponsoredChildren =
        children.where((child) => child.sponsor?.id == sponsor.id).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'sponsorship_report_title',
                overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
              ),
              pw.SizedBox(height: 2),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (context) {
          return [
            _buildTimePeriodInfo(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 15),
            _buildSponsorMainInfo(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 15),
            ..._buildSponsoredChildrenList(
              l,
              sponsoredChildren,
              arabicFont,
              arabicBoldFont,
              context,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTimePeriodInfo(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    final isRtl = locale.languageCode == 'ar';

    String timePeriodText = '';
    if (reportType == 'yearly' && month != null) {
      timePeriodText = '${l.getKey('year')} [${month!.year}]';
    } else if (reportType == 'range' && startDate != null && endDate != null) {
      final startStr = _formatDate(startDate!, l);
      final endStr = _formatDate(endDate!, l);
      timePeriodText =
          '${l.getKey('from_label')} $startStr ${l.getKey('to_label')} $endStr';
    } else if (month != null) {
      final monthName = _getMonthName(month!, l);
      timePeriodText = '$monthName ${month!.year}';
    }

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment:
            isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${l.getKey('time_period_label')}: $timePeriodText',
                  style: pw.TextStyle(fontSize: 11, font: arabicFont),
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSponsorMainInfo(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300, width: 2),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l.getKey('report_sponsor_info'),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
              font: arabicBoldFont,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(
                  l.getKey('report_sponsor_name_colon'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: arabicBoldFont,
                  ),
                  textAlign: _getTextAlign(),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  sponsor.getNameByLanguage(locale.languageCode),
                  style: pw.TextStyle(fontSize: 12, font: arabicFont),
                  textAlign: _getTextAlign(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(
                  l.getKey('monthly_report_creation_date'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: arabicBoldFont,
                  ),
                  textAlign: _getTextAlign(),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _formatDate(sponsor.createdAt, l),
                  style: pw.TextStyle(fontSize: 12, font: arabicFont),
                  textAlign: _getTextAlign(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(
                  l.getKey('report_start_date_colon'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    font: arabicBoldFont,
                  ),
                  textAlign: _getTextAlign(),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _formatDate(sponsor.startDate, l),
                  style: pw.TextStyle(fontSize: 12, font: arabicFont),
                  textAlign: _getTextAlign(),
                ),
              ),
            ],
          ),
          if (sponsor.endDate != null)
            pw.Column(
              children: [
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        l.getKey('report_end_date_colon'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: arabicBoldFont,
                        ),
                        textAlign: _getTextAlign(),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _formatDate(sponsor.endDate!, l),
                        style: pw.TextStyle(fontSize: 12, font: arabicFont),
                        textAlign: _getTextAlign(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildSponsoredChildrenList(
    AppLocalizations l,
    List<Child> sponsoredChildren,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    if (sponsoredChildren.isEmpty) {
      return [
        pw.Text(
          l.getKey('report_no_sponsored_orphans'),
          style: pw.TextStyle(
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
            font: arabicFont,
          ),
        ),
      ];
    }

    final bool isRtl = locale.languageCode == 'ar';

    // Build ordered columns based on direction
    List<String> orderedColumns;
    final headersMap = {
      'name': l.getKey('report_child_name') ?? 'اسم اليتيم',
      'id': l.getKey('report_child_id') ?? 'رقم اليتيم',
      'amount': l.getKey('amount_paid_label') ?? 'المبلغ المدفوع',
    };

    if (isRtl) {
      orderedColumns = ['amount', 'id', 'name'];
    } else {
      orderedColumns = ['name', 'id', 'amount'];
    }

    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(2.0),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.5),
    };

    // Build headers list (RTL order already applied via orderedColumns)
    final headers = orderedColumns.map((key) => headersMap[key]!).toList();

    // حساب مجموع الدفعات لكل طفل وبناء البيانات كـ string lists
    final List<List<String>> data = [];
    final currencyTotals = <String, double>{};

    for (final child in sponsoredChildren) {
      double childTotal = 0;
      String displayCurrency = 'شيكل';

      if (paymentsMap != null) {
        final payments = paymentsMap![child.id] ?? [];
        for (final payment in payments) {
          if (_isPaymentInDateRange(payment.paidAt)) {
            childTotal += payment.amount;
            displayCurrency = payment.currency ?? 'شيكل';
            final currency = payment.currency ?? 'شيكل';
            currencyTotals[currency] =
                (currencyTotals[currency] ?? 0) + payment.amount;
          }
        }
      }

      final sponsorModel = Sponsor(
        id: sponsor.id,
        name: sponsor.name,
        amount: 0,
        startDate: sponsor.startDate,
        currency: displayCurrency,
      );
      final currencyDisplay = sponsorModel.getCurrencyByLanguage(
        locale.languageCode,
      );

      data.add(
        orderedColumns.map((key) {
          switch (key) {
            case 'name':
              return child.getFullNameByLanguage(locale.languageCode);
            case 'id':
              return child.childIdNumber;
            case 'amount':
              return '${childTotal.toStringAsFixed(2)} $currencyDisplay';
            default:
              return '';
          }
        }).toList(),
      );
    }
    final widgets = <pw.Widget>[
      pw.Text(
        l.getKey('report_sponsored_orphans'),
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
          font: arabicBoldFont,
        ),
      ),
      pw.SizedBox(height: 12),
      // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
        columnWidths: columnWidths,
      ),
      pw.SizedBox(height: 15),
    ];

    // إضافة الإجمالي حسب العملة
    if (currencyTotals.isNotEmpty) {
      widgets.add(
        pw.Text(
          l.getKey('payment_totals_by_currency') ??
              'إجمالي الدفعات حسب العملة:',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
            font: arabicBoldFont,
            color: PdfColors.green900,
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));

      for (final currency in currencyTotals.keys) {
        final total = currencyTotals[currency] ?? 0;
        widgets.add(
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green400, width: 2),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  l.getKey('total_label') ?? 'الإجمالي',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                    font: arabicBoldFont,
                  ),
                ),
                pw.Text(
                  '${total.toStringAsFixed(2)} $currency',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                    font: arabicBoldFont,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  bool _isPaymentInDateRange(DateTime paymentDate) {
    if (reportType == 'monthly' && month != null) {
      return paymentDate.year == month!.year &&
          paymentDate.month == month!.month;
    } else if (reportType == 'yearly' && month != null) {
      return paymentDate.year == month!.year;
    } else if (reportType == 'range' && startDate != null && endDate != null) {
      return paymentDate.isAfter(startDate!) &&
          paymentDate.isBefore(endDate!.add(Duration(days: 1)));
    }
    return true;
  }

  String _getMonthName(DateTime date, AppLocalizations l) {
    final monthKey = 'month_${date.month.toString().padLeft(2, '0')}';
    return l.getKey(monthKey);
  }

  String _formatDate(DateTime date, AppLocalizations l) {
    final monthKey = 'month_${date.month.toString().padLeft(2, '0')}';
    return '${date.day} ${l.getKey(monthKey)} ${date.year}';
  }
}

/// Unsponsored Children Report
class UnSponsoredChildrenReport {
  final List<Child> children;
  final DateTime reportDate;
  final material.Locale locale;

  final List<String>? selectedColumns;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  UnSponsoredChildrenReport({
    required this.children,
    required this.reportDate,
    required this.locale,
    this.selectedColumns,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    // Load logo
    final logo = await ArabicFontLoader.loadLogo();

    // Get unsponsored children
    final unSponsoredChildren =
        children.where((child) => child.isUnsponsored).toList();

    final bool useLandscape = (selectedColumns?.length ?? 4) > 6;
    final PdfPageFormat format =
        useLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'unsponsored_children_report_title',
                overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
              ),
              pw.SizedBox(height: 2),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (context) {
          return [
            ..._buildUnSponsoredChildrenList(
              l,
              unSponsoredChildren,
              arabicFont,
              arabicBoldFont,
              context,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildUnSponsoredChildrenList(
    AppLocalizations l,
    List<Child> unSponsoredChildren,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';

    // Section title
    final sectionTitle = pw.Text(
      l.report_unsponsored_list,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
        font: arabicBoldFont,
      ),
    );

    // Empty state
    if (unSponsoredChildren.isEmpty) {
      return [
        sectionTitle,
        pw.SizedBox(height: 8),
        pw.Text(
          l.report_all_sponsored_message,
          style: pw.TextStyle(
            color: PdfColors.green600,
            fontStyle: pw.FontStyle.italic,
            fontSize: 12,
            font: arabicFont,
          ),
        ),
      ];
    }

    // Build column headers (LTR or RTL order)
    // Default columns if none selected
    final List<String> columns =
        selectedColumns ??
        ['child_name', 'child_id_label', 'age_label', 'country_label'];

    // Map of column keys to their headers
    final Map<String, String> headerMap = {
      'child_name': l.report_child_name,
      'child_id_label': l.report_child_id,
      'national_id': l.national_id,
      'age_label': l.report_age,
      'gender': l.gender,
      'father_status': l.father_status,
      'mother_status': l.mother_status,
      'country_label': l.report_country,
      'city': l.city,
      'education_level_colon': l.education_level,
      'health_status_label': l.report_health_status,
      'report_sponsor': l.report_sponsor,
    };

    // Map of column keys to their flex widths
    final Map<String, double> widthMap = {
      'child_name': 2.0,
      'child_id_label': 1.2,
      'national_id': 1.2,
      'age_label': 1.0,
      'gender': 0.8,
      'father_status': 1.0,
      'mother_status': 1.0,
      'country_label': 1.2,
      'city': 1.0,
      'education_level_colon': 1.5,
      'health_status_label': 1.2,
      'report_sponsor': 1.8,
    };

    // Build ordered columns based on direction
    List<String> orderedColumns;
    if (isRtl) {
      orderedColumns = [...columns.reversed, '#'];
    } else {
      orderedColumns = ['#', ...columns];
    }

    // Build column widths mapping
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < orderedColumns.length; i++) {
      final key = orderedColumns[i];
      columnWidths[i] =
          key == '#'
              ? const pw.FlexColumnWidth(0.5)
              : pw.FlexColumnWidth(widthMap[key] ?? 1.0);
    }

    // Adaptive font sizes based on column count
    final int totalCols = orderedColumns.length;
    final double headerFontSize =
        totalCols <= 6
            ? 8.0
            : totalCols <= 10
            ? 7.0
            : 6.0;
    final double cellFontSize =
        totalCols <= 6
            ? 7.5
            : totalCols <= 10
            ? 6.5
            : 5.5;

    // Build headers list (RTL order already applied via orderedColumns)
    final headers =
        orderedColumns
            .map((key) => key == '#' ? '#' : (headerMap[key] ?? key))
            .toList();

    // Data Rows as string lists
    final now = DateTime.now();
    final data =
        unSponsoredChildren.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final child = entry.value;
          final age = _calculateAge(child.dateOfBirth, l, now);
          return orderedColumns
              .map(
                (key) =>
                    key == '#' ? '$index' : _getColumnValue(child, key, age, l),
              )
              .toList();
        }).toList();

    return [
      sectionTitle,
      pw.SizedBox(height: 8),
      // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: headerFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: cellFontSize),
        columnWidths: columnWidths,
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.red50,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          '${l.report_total_unsponsored_orphans}: ${unSponsoredChildren.length}',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 11,
            color: PdfColors.red700,
            font: arabicBoldFont,
          ),
        ),
      ),
    ];
  }

  String _calculateAge(
    DateTime? dateOfBirth,
    AppLocalizations l,
    DateTime now,
  ) {
    if (dateOfBirth == null) return '-';
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return '$age ${l.report_years}';
  }

  String _getColumnValue(
    Child child,
    String key,
    String age,
    AppLocalizations l,
  ) {
    switch (key) {
      case 'child_name':
        return child.getFullNameByLanguage(locale.languageCode);
      case 'child_id_label':
        return child.childIdNumber;
      case 'national_id':
        return child.nationalId ?? '-';
      case 'age_label':
        return age;
      case 'gender':
        return child.gender == 'M' ? l.gender_male : l.gender_female;
      case 'father_status':
        return child.getFatherStatusByLanguage(locale.languageCode);
      case 'mother_status':
        return child.getMotherStatusByLanguage(locale.languageCode);
      case 'country_label':
        return child.getCountryByLanguage(locale.languageCode) ?? '-';
      case 'city':
        return child.getCityByLanguage(locale.languageCode) ?? '-';
      case 'education_level_colon':
        return child.getEducationLevelByLanguage(locale.languageCode) ?? '-';
      case 'health_status_label':
        return child.getHealthStatusByLanguage(locale.languageCode);
      case 'report_sponsor':
        return child.sponsor?.getNameByLanguage(locale.languageCode) ??
            l.report_none;
      default:
        return '-';
    }
  }
}

/// All Orphans Report
class AllOrphansReport {
  final List<Child> children;
  final DateTime reportDate;
  final material.Locale locale;

  final List<String>? selectedColumns;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  AllOrphansReport({
    required this.children,
    required this.reportDate,
    required this.locale,
    this.selectedColumns,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    final logo = await ArabicFontLoader.loadLogo();

    final bool useLandscape = (selectedColumns?.length ?? 5) > 6;
    final PdfPageFormat format =
        useLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'all_orphans_report_title',
                overrideOrganizationName:
                    lookupAppLocalizations(
                      const material.Locale('tr'),
                    ).organization_full_name,
              ),
              pw.SizedBox(height: 5),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          final dateStr =
              '${l.report_creation_date_colon} ${intl.DateFormat.yMd(locale.languageCode).format(reportDate)}';
          return [
            _buildTitle(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 20),
            _buildSummary(l, arabicFont),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(fontSize: 10, font: arabicFont),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            ..._buildChildrenTable(l, arabicFont, arabicBoldFont, context),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTitle(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          l.report_all_orphans_list,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: arabicBoldFont,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSummary(AppLocalizations l, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          _buildSummaryItem(
            l.report_total_orphans,
            '${children.length}',
            PdfColors.blue,
            arabicFont,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor color,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 12, font: arabicFont)),
      ],
    );
  }

  List<pw.Widget> _buildChildrenTable(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';
    final now = DateTime.now();

    // Default columns if none selected
    final List<String> columns =
        selectedColumns ??
        [
          'child_name',
          'child_id_label',
          'age_label',
          'health_status_label',
          'report_sponsor',
        ];

    // Map of column keys to their headers
    final Map<String, String> headerMap = {
      'child_name': l.report_name,
      'child_id_label': l.child_id_code,
      'national_id': l.national_id,
      'age_label': l.report_age,
      'gender': l.gender,
      'father_status': l.father_status,
      'mother_status': l.mother_status,
      'country_label': l.report_country,
      'city': l.city,
      'education_level_colon': l.education_level,
      'health_status_label': l.report_health_status,
      'report_sponsor': l.report_sponsor,
    };

    // Map of column keys to their flex widths
    final Map<String, double> widthMap = {
      'child_name': 2.2,
      'child_id_label': 1.2,
      'national_id': 1.2,
      'age_label': 0.8,
      'gender': 0.8,
      'father_status': 1.0,
      'mother_status': 1.0,
      'country_label': 1.2,
      'city': 1.0,
      'education_level_colon': 1.5,
      'health_status_label': 1.2,
      'report_sponsor': 1.8,
    };

    // Build ordered columns based on direction
    List<String> orderedColumns;
    if (isRtl) {
      // RTL: Columns are reversed then # is added at the end (leftmost in logical order for RTL display)
      orderedColumns = [...columns.reversed, '#'];
    } else {
      // LTR: # leftmost, then columns in order
      orderedColumns = ['#', ...columns];
    }

    // Build column widths mapping
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < orderedColumns.length; i++) {
      final key = orderedColumns[i];
      columnWidths[i] =
          key == '#'
              ? const pw.FlexColumnWidth(0.5)
              : pw.FlexColumnWidth(widthMap[key] ?? 1.0);
    }

    // Adaptive font sizes based on column count
    final int totalCols = orderedColumns.length;
    final double headerFontSize =
        totalCols <= 6
            ? 8.0
            : totalCols <= 10
            ? 7.0
            : 6.0;
    final double cellFontSize =
        totalCols <= 6
            ? 7.5
            : totalCols <= 10
            ? 6.5
            : 5.5;

    // Build headers list (RTL order already applied via orderedColumns)
    final headers =
        orderedColumns
            .map((key) => key == '#' ? '#' : (headerMap[key] ?? key))
            .toList();

    // Data Rows as string lists
    final data =
        children.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final child = entry.value;
          final age = _calculateAge(child.dateOfBirth, l, now);
          return orderedColumns
              .map(
                (key) =>
                    key == '#' ? '$index' : _getColumnValue(child, key, age, l),
              )
              .toList();
        }).toList();

    return [
      // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: headerFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: cellFontSize),
        columnWidths: columnWidths,
      ),
    ];
  }

  String _calculateAge(
    DateTime? dateOfBirth,
    AppLocalizations l,
    DateTime now,
  ) {
    if (dateOfBirth == null) return '-';
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return '$age ${l.report_years}';
  }

  String _getColumnValue(
    Child child,
    String key,
    String age,
    AppLocalizations l,
  ) {
    switch (key) {
      case 'child_name':
        return child.getFullNameByLanguage(locale.languageCode);
      case 'child_id_label':
        return child.childIdNumber;
      case 'national_id':
        return child.nationalId ?? '-';
      case 'age_label':
        return age;
      case 'gender':
        return child.gender == 'M' ? l.gender_male : l.gender_female;
      case 'father_status':
        return child.getFatherStatusByLanguage(locale.languageCode);
      case 'mother_status':
        return child.getMotherStatusByLanguage(locale.languageCode);
      case 'country_label':
        return child.getCountryByLanguage(locale.languageCode) ?? '-';
      case 'city':
        return child.getCityByLanguage(locale.languageCode) ?? '-';
      case 'education_level_colon':
        return child.getEducationLevelByLanguage(locale.languageCode) ?? '-';
      case 'health_status_label':
        return child.getHealthStatusByLanguage(locale.languageCode);
      case 'report_sponsor':
        return child.sponsor?.getNameByLanguage(locale.languageCode) ??
            l.report_none;
      default:
        return '-';
    }
  }
}

/// Sponsored Orphans Report
class SponsoredOrphansReport {
  final List<Child> children;
  final DateTime reportDate;
  final material.Locale locale;

  final List<String>? selectedColumns;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  SponsoredOrphansReport({
    required this.children,
    required this.reportDate,
    required this.locale,
    this.selectedColumns,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    final logo = await ArabicFontLoader.loadLogo();

    final bool useLandscape = (selectedColumns?.length ?? 5) > 6;
    final PdfPageFormat format =
        useLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'report_sponsored_orphans_title',
                overrideOrganizationName:
                    lookupAppLocalizations(
                      const material.Locale('tr'),
                    ).organization_full_name,
              ),
              pw.SizedBox(height: 5),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          final dateStr =
              '${l.report_creation_date_colon} ${intl.DateFormat.yMd(locale.languageCode).format(reportDate)}';
          return [
            _buildTitle(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 20),
            _buildSummary(l, arabicFont),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(fontSize: 10, font: arabicFont),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            ..._buildChildrenTable(l, arabicFont, arabicBoldFont, context),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTitle(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          l.report_sponsored_orphans_list,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: arabicBoldFont,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSummary(AppLocalizations l, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          _buildSummaryItem(
            l.report_total_sponsored_orphans,
            '${children.length}',
            PdfColors.blue,
            arabicFont,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor color,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 12, font: arabicFont)),
      ],
    );
  }

  List<pw.Widget> _buildChildrenTable(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';
    final now = DateTime.now();

    // Default columns if none selected
    final List<String> columns =
        selectedColumns ??
        [
          'child_name',
          'child_id_label',
          'age_label',
          'health_status_label',
          'report_sponsor',
        ];

    // Map of column keys to their headers
    final Map<String, String> headerMap = {
      'child_name': l.report_name,
      'child_id_label': l.child_id_code,
      'national_id': l.national_id,
      'age_label': l.report_age,
      'gender': l.gender,
      'father_status': l.father_status,
      'mother_status': l.mother_status,
      'country_label': l.report_country,
      'city': l.city,
      'education_level_colon': l.education_level,
      'health_status_label': l.report_health_status,
      'report_sponsor': l.report_sponsor,
    };

    // Map of column keys to their flex widths
    final Map<String, double> widthMap = {
      'child_name': 2.2,
      'child_id_label': 1.2,
      'national_id': 1.2,
      'age_label': 0.8,
      'gender': 0.8,
      'father_status': 1.0,
      'mother_status': 1.0,
      'country_label': 1.2,
      'city': 1.0,
      'education_level_colon': 1.5,
      'health_status_label': 1.2,
      'report_sponsor': 1.8,
    };

    // Build ordered columns based on direction
    List<String> orderedColumns;
    if (isRtl) {
      orderedColumns = [...columns.reversed, '#'];
    } else {
      orderedColumns = ['#', ...columns];
    }

    // Build column widths mapping
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < orderedColumns.length; i++) {
      final key = orderedColumns[i];
      columnWidths[i] =
          key == '#'
              ? const pw.FlexColumnWidth(0.5)
              : pw.FlexColumnWidth(widthMap[key] ?? 1.0);
    }

    // Adaptive font sizes based on column count
    final int totalCols = orderedColumns.length;
    final double headerFontSize =
        totalCols <= 6
            ? 8.0
            : totalCols <= 10
            ? 7.0
            : 6.0;
    final double cellFontSize =
        totalCols <= 6
            ? 7.5
            : totalCols <= 10
            ? 6.5
            : 5.5;

    // Build headers list (RTL order already applied via orderedColumns)
    final headers =
        orderedColumns
            .map((key) => key == '#' ? '#' : (headerMap[key] ?? key))
            .toList();

    // Data Rows as string lists
    final data =
        children.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final child = entry.value;
          final age = _calculateAge(child.dateOfBirth, l, now);
          return orderedColumns
              .map(
                (key) =>
                    key == '#' ? '$index' : _getColumnValue(child, key, age, l),
              )
              .toList();
        }).toList();

    return [
      // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: headerFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: cellFontSize),
        columnWidths: columnWidths,
      ),
    ];
  }

  String _calculateAge(
    DateTime? dateOfBirth,
    AppLocalizations l,
    DateTime now,
  ) {
    if (dateOfBirth == null) return '-';
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return '$age ${l.report_years}';
  }

  String _getColumnValue(
    Child child,
    String key,
    String age,
    AppLocalizations l,
  ) {
    switch (key) {
      case 'child_name':
        return child.getFullNameByLanguage(locale.languageCode);
      case 'child_id_label':
        return child.childIdNumber;
      case 'national_id':
        return child.nationalId ?? '-';
      case 'age_label':
        return age;
      case 'gender':
        return child.gender == 'M' ? l.gender_male : l.gender_female;
      case 'father_status':
        return child.getFatherStatusByLanguage(locale.languageCode);
      case 'mother_status':
        return child.getMotherStatusByLanguage(locale.languageCode);
      case 'country_label':
        return child.getCountryByLanguage(locale.languageCode) ?? '-';
      case 'city':
        return child.getCityByLanguage(locale.languageCode) ?? '-';
      case 'education_level_colon':
        return child.getEducationLevelByLanguage(locale.languageCode) ?? '-';
      case 'health_status_label':
        return child.getHealthStatusByLanguage(locale.languageCode);
      case 'report_sponsor':
        return child.sponsor?.getNameByLanguage(locale.languageCode) ??
            l.report_none;
      default:
        return '-';
    }
  }
}

/// All Sponsors Report
class AllSponsorsReport {
  final List<Sponsor> sponsors;
  final List<Child> children;
  final DateTime reportDate;
  final material.Locale locale;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  AllSponsorsReport({
    required this.sponsors,
    required this.children,
    required this.reportDate,
    required this.locale,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts using helper
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    final logo = await ArabicFontLoader.loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'all_sponsors_report_title',
                overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
              ),
              pw.SizedBox(height: 5),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            _buildTitle(l, arabicFont, arabicBoldFont),
            pw.SizedBox(height: 20),
            _buildSummary(l, arabicFont),
            ..._buildSponsorsTable(l, arabicFont, arabicBoldFont, context),
            // pw.SizedBox(height: 20),
            // _buildFooter(l, arabicFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTitle(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          l.report_all_sponsors_list,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: arabicBoldFont,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSummary(AppLocalizations l, pw.Font arabicFont) {
    final totalAmount = sponsors.fold<double>(0, (sum, s) => sum + s.amount);
    final activeSponsors = sponsors.where((s) => s.isOngoing).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            l.report_total_sponsors,
            '${sponsors.length}',
            PdfColors.green,
            arabicFont,
          ),
          _buildSummaryItem(
            l.report_active_sponsors,
            '$activeSponsors',
            PdfColors.blue,
            arabicFont,
          ),
          _buildSummaryItem(
            l.report_monthly_amount,
            totalAmount.toStringAsFixed(0),
            PdfColors.orange,
            arabicFont,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor color,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 12, font: arabicFont)),
      ],
    );
  }

  List<pw.Widget> _buildSponsorsTable(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';

    // Build ordered columns based on direction
    List<String> orderedColumns;
    final headersMap = {
      'status': l.report_status,
      'count': l.report_orphans_count,
      'amount': l.report_monthly_amount,
      'name': l.report_name,
      '#': '#',
    };

    if (isRtl) {
      orderedColumns = ['status', 'count', 'amount', 'name', '#'];
    } else {
      orderedColumns = ['#', 'name', 'amount', 'count', 'status'];
    }

    final Map<int, pw.TableColumnWidth> columnWidths = {
      for (int i = 0; i < orderedColumns.length; i++)
        i:
            orderedColumns[i] == '#'
                ? const pw.FlexColumnWidth(0.6)
                : orderedColumns[i] == 'name'
                ? const pw.FlexColumnWidth(2.5)
                : const pw.FlexColumnWidth(1.5),
    };

    // Build headers list (RTL order already applied via orderedColumns)
    final headers = orderedColumns.map((key) => headersMap[key]!).toList();

    // Data Rows as string lists
    final data =
        sponsors.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final sponsor = entry.value;
          final sponsoredChildrenCount =
              children
                  .where(
                    (c) =>
                        c.sponsor?.name == sponsor.name ||
                        c.sponsor?.id == sponsor.id,
                  )
                  .length;

          return orderedColumns.map((key) {
            switch (key) {
              case '#':
                return '$index';
              case 'name':
                return sponsor.getNameByLanguage(locale.languageCode);
              case 'amount':
                return '${sponsor.amount.toStringAsFixed(0)} ${sponsor.getCurrencyByLanguage(locale.languageCode)}';
              case 'count':
                return '$sponsoredChildrenCount';
              case 'status':
                return sponsor.isOngoing ? l.report_active : l.report_stopped;
              default:
                return '';
            }
          }).toList();
        }).toList();

    return [
      // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
        columnWidths: columnWidths,
      ),
    ];
  }

  pw.Widget _buildFooter(AppLocalizations l, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey200,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            l.report_generated_by_system,
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
          ),
        ],
      ),
    );
  }
}

/// Report for unregistered unsponsored siblings
class UnregisteredUnsponsoredSiblingsReport {
  final List<Map<String, dynamic>> unregisteredSiblings;
  final DateTime reportDate;
  final material.Locale locale;

  pw.Font arabicFont = pw.Font.helvetica();
  pw.Font arabicBoldFont = pw.Font.helveticaBold();

  UnregisteredUnsponsoredSiblingsReport({
    required this.unregisteredSiblings,
    required this.reportDate,
    required this.locale,
  });

  /// الحصول على اتجاه النص بناءً على اللغة
  pw.TextDirection _getTextDirection() {
    return locale.languageCode == 'ar'
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  /// الحصول على محاذاة النص بناءً على اللغة
  pw.TextAlign _getTextAlign() {
    return locale.languageCode == 'ar' ? pw.TextAlign.right : pw.TextAlign.left;
  }

  Future<Uint8List> generatePdfBytes(material.Locale locale) async {
    final pdf = pw.Document();
    final l = lookupAppLocalizations(locale);

    // Load fonts
    final fonts = await ArabicFontLoader.loadWithFallback();
    arabicFont = fonts['regular']!;
    arabicBoldFont = fonts['bold']!;

    // Load logo
    final logo = await ArabicFontLoader.loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        textDirection: _getTextDirection(),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
        header: (context) {
          return pw.Column(
            children: [
              ReportSharedWidgets.buildHeader(
                l,
                logo,
                'report_unregistered_unsponsored',
                overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
              ),
              ReportSharedWidgets.buildThickLine(),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                font: arabicFont,
              ),
            ),
          );
        },
        build: (context) {
          return [
            ..._buildReportContent(l, arabicFont, arabicBoldFont, context),
          ];
        },
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildReportContent(
    AppLocalizations l,
    pw.Font arabicFont,
    pw.Font arabicBoldFont,
    pw.Context context,
  ) {
    final bool isRtl = locale.languageCode == 'ar';
    final widgets = <pw.Widget>[];

    // Report info box
    widgets.add(
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue300),
          borderRadius: pw.BorderRadius.circular(5),
          color: PdfColors.blue50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${l.report_date_label}: ${reportDate.toString().split(' ')[0]}',
              style: pw.TextStyle(fontSize: 11, font: arabicFont),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l.total_records}: ${unregisteredSiblings.length}',
              style: pw.TextStyle(fontSize: 11, font: arabicFont),
            ),
          ],
        ),
      ),
    );

    widgets.add(pw.SizedBox(height: 15));

    // Section title
    widgets.add(
      pw.Text(
        l.get('report_unregistered_unsponsored'),
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
          font: arabicBoldFont,
        ),
      ),
    );

    widgets.add(pw.SizedBox(height: 8));

    // Empty state check
    if (unregisteredSiblings.isEmpty) {
      widgets.add(
        pw.Text(
          l.get('no_unsponsored_siblings_found'),
          style: pw.TextStyle(
            color: PdfColors.green600,
            fontStyle: pw.FontStyle.italic,
            fontSize: 12,
            font: arabicFont,
          ),
        ),
      );
      return widgets;
    }

    // Build ordered columns based on direction
    List<String> orderedColumns;
    final headersMap = {
      '#': '#',
      'id': l.sibling_id,
      'name': l.sibling_name,
      'age': l.report_age,
      'registered': l.registered_sibling,
    };

    if (isRtl) {
      orderedColumns = ['registered', 'age', 'name', 'id', '#'];
    } else {
      orderedColumns = ['#', 'id', 'name', 'age', 'registered'];
    }

    final Map<int, pw.TableColumnWidth> columnWidths = {
      for (int i = 0; i < orderedColumns.length; i++)
        i:
            orderedColumns[i] == '#'
                ? const pw.FlexColumnWidth(0.5)
                : orderedColumns[i] == 'name' ||
                    orderedColumns[i] == 'registered'
                ? const pw.FlexColumnWidth(2.0)
                : const pw.FlexColumnWidth(1.0),
    };

    // Build headers list (RTL order already applied via orderedColumns)
    final headers = orderedColumns.map((key) => headersMap[key]!).toList();

    // Calculate age helper
    String calculateAge(DateTime? birthDate) {
      if (birthDate == null) return '-';
      final now = DateTime.now();
      final age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        return '${age - 1}';
      }
      return '$age';
    }

    // Data Rows as string lists
    final data =
        unregisteredSiblings.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final sibling = entry.value;

          final siblingName = _getTranslatedText(
            sibling['name'] as String? ?? '-',
            locale.languageCode,
          );
          final siblingId = sibling['id'] as String? ?? '-';
          final parentChild = _getTranslatedText(
            sibling['parentChild'] as String? ?? '-',
            locale.languageCode,
          );
          final birthDate = sibling['dateOfBirth'] as DateTime?;
          final ageStr = calculateAge(birthDate);

          return orderedColumns.map((key) {
            switch (key) {
              case '#':
                return '$index';
              case 'id':
                return siblingId;
              case 'name':
                return siblingName;
              case 'age':
                return ageStr;
              case 'registered':
                return parentChild;
              default:
                return '';
            }
          }).toList();
        }).toList();

    // TableHelper يكرر headers تلقائياً في كل صفحة جديدة ضمن MultiPage
    widgets.add(
      pw.TableHelper.fromTextArray(
        context: context,
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.blue300, width: 0.5),
        headerStyle: pw.TextStyle(
          font: arabicBoldFont,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
        columnWidths: columnWidths,
      ),
    );

    widgets.add(pw.SizedBox(height: 20));
    widgets.add(_buildFooter(l, arabicFont));

    return widgets;
  }

  pw.Widget _buildFooter(AppLocalizations l, pw.Font arabicFont) {
    return pw.SizedBox.shrink();
  }

  /// ترجمة النص حسب اللغة المختارة
  String _getTranslatedText(String text, String languageCode) {
    if (text.isEmpty || text == '-') return text;

    switch (languageCode) {
      case 'en':
        return MultiLangTransliterator.toEnglish(text);
      case 'tr':
        return MultiLangTransliterator.toTurkish(text);
      default:
        return text; // العربية كما هي
    }
  }
}
