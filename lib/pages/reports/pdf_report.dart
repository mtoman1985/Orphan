import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart' as material;
import '../../models/child.dart';
import '../../models/payment.dart';
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';
import 'report_shared_widgets.dart';
import 'package:orphan/services/arabic_font_loader.dart';
import 'package:orphan/services/settings_service.dart';
import 'package:orphan/services/sqlite_service.dart';
import '../../services/github_storage_service.dart';
import '../../services/multilang_transliterator.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class OrphanReportPDF {
  Future<void> inti() async {
    // Intentionally left blank helper to avoid removing experimental code.
  }

  static Future<void> generateAndOpen(
    Child child, {
    BuildContext? context,
    required material.Locale locale,
    String filterMode = 'none',
    int selectedYear = 0,
    int selectedMonth = 0,
    DateTime? startDate,
    DateTime? endDate,
    bool includePaymentsTable = false,
    String? reportTitleKey,
    bool onlyFinancial = false,
  }) async {
    try {
      // الحصول على اسم المنظمة من الإعدادات
      final organizationName = await SettingsService.getOrganizationName();
      final report = OrphanPdfReport(
        child: child,
        locale: locale,
        organizationName: organizationName,
        filterMode: filterMode,
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
        startDate: startDate,
        endDate: endDate,
        includePaymentsTable: includePaymentsTable,
        reportTitleKey: reportTitleKey ?? 'orphan_form',
        onlyFinancial: onlyFinancial,
      );

      final pdfBytes = await report.generatePdfBytes(locale);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Report_${child.firstName}_${child.lastName}.pdf',
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

class OrphanPdfReport {
  final Child child;
  final material.Locale locale;
  final String organizationName;
  final String filterMode;
  final int selectedYear;
  final int selectedMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includePaymentsTable;
  final String reportTitleKey;
  final bool onlyFinancial;

  OrphanPdfReport({
    required this.child,
    required this.locale,
    this.organizationName = 'برنامج كفالة الأيتام',
    this.filterMode = 'none',
    this.selectedYear = 0,
    this.selectedMonth = 0,
    this.startDate,
    this.endDate,
    this.includePaymentsTable = false,
    this.reportTitleKey = 'orphan_form',
    this.onlyFinancial = false,
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
    final logo = await ArabicFontLoader.loadLogo();

    // تحميل الخطوط باستخدام المساعد
    final fonts = await ArabicFontLoader.loadWithFallback();
    final pw.Font arabicFont = fonts['regular']!;
    final pw.Font arabicBoldFont = fonts['bold']!;

    try {
      final circularImage = await _buildCircularImage(
        child.childPhotoPath ?? '',
        l,
      );

      // جلب بيانات الدفعات من قاعدة البيانات
      final paymentRows = await _getFilteredPayments();
      final filteredPaymentsList = await _getFilteredPaymentsList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(4),
          textDirection: _getTextDirection(),
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
          // Header - يتكرر في كل صفحة
          header: (context) {
            return pw.Column(
              children: [
                ReportSharedWidgets.buildHeader(
                  l,
                  logo,
                  reportTitleKey,
                  overrideOrganizationName: 'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
                ),
                pw.SizedBox(height: 2),
                ReportSharedWidgets.buildThickLine(),
                pw.SizedBox(height: 10),
              ],
            );
          },

          // Footer - يتكرر في كل صفحة
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: pw.EdgeInsets.only(top: 2),
              padding: pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
              ),
              child: pw.Text(
                '${l.getKey('page_label')} ${context.pageNumber} ${l.getKey('of_label')} ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },

          // Build - قائمة بالعناصر تتوزع تلقائياً
          build: (context) {
            if (onlyFinancial) {
              return [
                pw.Container(
                  padding: pw.EdgeInsets.all(2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            child.getFullNameByLanguage(locale.languageCode),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${l.getKey('child_id_label')}: ${child.childIdNumber}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                if (child.sponsor != null) ...[
                  pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    child: _buildSponsorshipPaymentsTable(
                      l,
                      paymentRows,
                      context,
                    ),
                  ),
                  if (filteredPaymentsList.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    _buildPaymentTotalsTable(l, filteredPaymentsList, context),
                  ],
                ],
              ];
            }
            return [
              // Wrapper with border for all content
              pw.Container(
                padding: pw.EdgeInsets.all(2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Main Profile Section - Image and Two Tables in One Row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Child Photo
                        pw.Column(
                          children: [
                            circularImage,
                            pw.SizedBox(height: 4),
                            pw.Text(
                              child.childIdNumber,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue700,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 3),
                        // Personal Information Table
                        pw.Expanded(child: _buildDetailedPersonalInfo(l)),
                        pw.SizedBox(width: 5),
                        // Sponsorship Information Table
                        pw.Expanded(child: _buildSponsorshipInfo(l)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              // Second Row - Family Information (Father and Mother)
              pw.Container(
                padding: pw.EdgeInsets.all(1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _buildFatherInfo(l)),
                    pw.SizedBox(width: 3),
                    pw.Expanded(child: _buildMotherInfo(l)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              // Siblings Info - directly after Father/Mother
              pw.Container(
                padding: pw.EdgeInsets.all(1),
                child: _buildSiblingsInfo(l, context),
              ),
              pw.SizedBox(height: 3),
              // Third row: Health and Education tables side by side
              pw.Container(
                padding: pw.EdgeInsets.all(1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _buildHealthTable(l)),
                    pw.SizedBox(width: 3),
                    pw.Expanded(child: _buildEducationTable(l)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              // Fourth row: Bank and Contact Info tables side by side
              pw.Container(
                padding: pw.EdgeInsets.all(1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _buildContactInfoTable(l)),
                    pw.SizedBox(width: 3),
                    pw.Expanded(child: _buildBankInfoTable(l)),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              // Fifth row: Sponsorship Payments Table
              if ((filterMode != 'none' || includePaymentsTable) &&
                  child.sponsor != null)
                pw.Container(
                  padding: pw.EdgeInsets.all(2),
                  child: _buildSponsorshipPaymentsTable(
                    l,
                    paymentRows,
                    context,
                  ),
                ),
            ];
          },
        ),
      );
    } catch (e, st) {
      debugPrint('PDF page build failed: $e\n$st');
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          textDirection: _getTextDirection(),
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBoldFont),
          build: (context) {
            return pw.Center(child: pw.Text(l.getKey('pdf_generation_error')));
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<File?> generatePdf(material.Locale locale) async {
    if (kIsWeb) return null;
    final bytes = await generatePdfBytes(locale);
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/Child_${child.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    savePDFFile(bytes, 'REPORT_CHILD_${child.id}.pdf');
    return file;
  }

  Future<void> printPdf() async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/Child_${child.id}.pdf');
    if (!await file.exists()) {
      throw Exception('PDF file not found: ${file.path}');
    }
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> sharePdf() async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/Child_${child.id}.pdf');
    if (!await file.exists()) {
      throw Exception('PDF file not found: ${file.path}');
    }
    final bytes = await file.readAsBytes();
    final tmp = Directory.systemTemp;
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${tmp.path}/report_${child.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<Uint8List?> resizeImageToSquare(
    String imagePath,
    int size, {
    String? childId,
  }) async {
    try {
      Uint8List imageBytes;
      if (imagePath.startsWith('assets/')) {
        final data = await rootBundle.load(imagePath);
        imageBytes = data.buffer.asUint8List();
      } else if (imagePath.startsWith('http') ||
          imagePath.startsWith('https')) {
        try {
          // Use the dedicated download method which handles web/CORS better
          final downloaded = await GitHubStorageService.downloadImage(
            imagePath,
          );
          if (downloaded == null || downloaded.isEmpty) return null;
          imageBytes = downloaded;
        } catch (e) {
          debugPrint('Error loading image from URL: $e');
          return null;
        }
      } else {
        if (kIsWeb) return null; // File access not supported on web
        final file = File(imagePath);
        if (!await file.exists()) return null;
        imageBytes = await file.readAsBytes();
      }

      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      int cropSize =
          originalImage.width < originalImage.height
              ? originalImage.width
              : originalImage.height;
      int offsetX = (originalImage.width - cropSize) ~/ 2;
      int offsetY = (originalImage.height - cropSize) ~/ 2;

      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: offsetX,
        y: offsetY,
        width: cropSize,
        height: cropSize,
      );
      img.Image resizedImage = img.copyResize(
        croppedImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.linear,
      );
      List<int> encodedBytes = img.encodePng(resizedImage);
      return Uint8List.fromList(encodedBytes);
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return null;
    }
  }

  Future<pw.Widget> _buildCircularImage(
    String filepath,
    AppLocalizations l,
  ) async {
    List<String> potentialPaths = [];

    final profilePhotos =
        child.documents.where((document) => document.type == 'Profile').toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    if (profilePhotos.isNotEmpty && profilePhotos.first.filePath.isNotEmpty) {
      potentialPaths.add(profilePhotos.first.filePath);
    }

    // 1. إضافة مسار الصورة الأساسي إذا وجد
    if (child.childPhotoPath != null && child.childPhotoPath!.isNotEmpty) {
      if (!potentialPaths.contains(child.childPhotoPath!)) {
        potentialPaths.add(child.childPhotoPath!);
      }
    }

    // 2. إضافة المسار الممرر إذا كان مختلفاً وجديداً
    if (filepath.isNotEmpty && !potentialPaths.contains(filepath)) {
      potentialPaths.add(filepath);
    }

    // 3. إضافة أي صور موجودة في المستندات
    if (child.documents.isNotEmpty) {
      for (final d in child.documents) {
        final path = d.filePath;
        if (path.isNotEmpty && (d.type == 'photo' || _isImageFile(path))) {
          if (!potentialPaths.contains(path)) {
            potentialPaths.add(path);
          }
        }
      }
    }

    const double imageSize = 100.0;

    // محاولة تحميل كل المسارات المتاحة واحداً تلو الآخر
    for (String path in potentialPaths) {
      try {
        final squareBytes = await resizeImageToSquare(
          path,
          100,
          childId: child.childIdNumber,
        );
        if (squareBytes != null && squareBytes.isNotEmpty) {
          final image = pw.MemoryImage(squareBytes);
          return pw.Container(
            width: imageSize,
            height: imageSize,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
            ),
            child: pw.ClipOval(
              child: pw.Image(
                image,
                fit: pw.BoxFit.cover,
                width: imageSize,
                height: imageSize,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading image from $path: $e');
      }
    }

    // Use gender-specific placeholder avatars if no photo is available
    String placeholderAsset = 'assets/images/avatar_boy.png';
    PdfColor backgroundColor = PdfColors.blue100;

    if (child.gender != null) {
      final gender = child.gender!.toUpperCase();
      if (gender == 'F' || gender == 'FEMALE' || gender == 'أنثى') {
        placeholderAsset = 'assets/images/avatar_girl.png';
        backgroundColor = const PdfColor.fromInt(0xFFF3E5F5); // Light purple
      } else {
        placeholderAsset = 'assets/images/avatar_boy.png';
        backgroundColor = PdfColors.blue100;
      }
    }

    try {
      final avatarData = await rootBundle.load(placeholderAsset);
      final imageBytes = avatarData.buffer.asUint8List();
      final image = pw.MemoryImage(imageBytes);

      return pw.Container(
        width: imageSize,
        height: imageSize,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: backgroundColor,
          border: pw.Border.all(color: PdfColors.blue800, width: 2),
        ),
        child: pw.ClipOval(
          child: pw.Image(
            image,
            width: imageSize,
            height: imageSize,
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      // Fallback if image loading fails
      return pw.Container(
        width: imageSize,
        height: imageSize,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: PdfColors.grey300,
          border: pw.Border.all(color: PdfColors.blue800, width: 2),
        ),
        child: pw.Center(
          child: pw.Text(
            child.gender != null
                ? (child.gender!.toUpperCase() == 'F'
                    ? l.getKey('report_gender_girl')
                    : l.getKey('report_gender_boy'))
                : l.getKey('no_photo'),
            style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }
  }

  bool _isImageFile(String? name) {
    if (name == null) return false;
    final n = name.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.bmp') ||
        n.endsWith('.webp');
  }

  String _translateDeathCause(String cause, AppLocalizations l) {
    final keyMap = {
      'Disease': 'death_cause_disease',
      'War': 'death_cause_war',
      'Natural Death': 'death_cause_natural',
      'Accident': 'death_cause_accident',
      'Other': 'death_cause_other',
    };
    final key = keyMap[cause];
    if (key != null) return l.getKey(key);
    return cause;
  }

  pw.Widget _buildFatherInfo(AppLocalizations l) {
    String fatherStatusDisplay = child.getFatherStatusByLanguage(
      locale.languageCode,
    );
    String fatherDeathDate = '';
    if (child.fatherDeathDate != null) {
      fatherDeathDate =
          child.fatherDeathDate!.toLocal().toIso8601String().split('T').first;
    }

    List<List<String>> rows = [];
    if (child.fatherName.isNotEmpty) {
      rows.add([
        l.getKey('father_triple_name'),
        child.getFatherNameByLanguage(locale.languageCode),
      ]);
    }
    if (fatherStatusDisplay.isNotEmpty) {
      rows.add([l.getKey('father_status'), fatherStatusDisplay]);
    }
    if (fatherDeathDate.isNotEmpty) {
      rows.add([l.getKey('father_death_date_colon'), fatherDeathDate]);
    }
    if (child.fatherDeathCause != null && child.fatherDeathCause!.isNotEmpty) {
      rows.add([
        l.getKey('father_death_cause_colon'),
        _translateDeathCause(child.fatherDeathCause!, l),
      ]);
    }

    return _buildTableSection(l.getKey('father_data'), rows);
  }

  pw.Widget _buildMotherInfo(AppLocalizations l) {
    String motherStatusDisplay = child.getMotherStatusByLanguage(
      locale.languageCode,
    );
    String motherDeathDate = '';
    if (child.motherDeathDate != null) {
      motherDeathDate =
          child.motherDeathDate!.toLocal().toIso8601String().split('T').first;
    }

    List<List<String>> rows = [];
    if (child.motherName.isNotEmpty) {
      rows.add([
        l.getKey('mother_triple_name'),
        child.getMotherNameByLanguage(locale.languageCode),
      ]);
    }
    if (motherStatusDisplay.isNotEmpty) {
      rows.add([l.getKey('mother_status'), motherStatusDisplay]);
    }
    if (motherDeathDate.isNotEmpty) {
      rows.add([l.getKey('mother_death_date_colon'), motherDeathDate]);
    }
    if (child.motherDeathCause != null && child.motherDeathCause!.isNotEmpty) {
      rows.add([
        l.getKey('mother_death_cause_colon'),
        _translateDeathCause(child.motherDeathCause!, l),
      ]);
    }

    return _buildTableSection(l.getKey('mother_data'), rows);
  }

  pw.Widget _buildSiblingsInfo(AppLocalizations l, pw.Context context) {
    List<dynamic> siblings = child.siblings;
    final isRtl = locale.languageCode == 'ar';
    // Table columns - LTR: #,Name,BirthDate,Sponsored,ID  RTL: reversed
    List<String> headers =
        isRtl
            ? [
              l.getKey('child_id_label'),
              l.getKey('is_sponsored'),
              l.getKey('birth_date'),
              l.getKey('name_label'),
              l.getKey('number_hash_label'),
            ]
            : [
              l.getKey('number_hash_label'),
              l.getKey('name_label'),
              l.getKey('birth_date'),
              l.getKey('is_sponsored'),
              l.getKey('child_id_label'),
            ];

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ─── شريط العنوان ───
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0D47A1),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  l.getKey('siblings_data'),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ],
            ),
          ),
          // ─── جدول البيانات ───
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.TableHelper.fromTextArray(
              context: context,
              headers: headers,
              data:
                  siblings.isEmpty
                      ? [
                        List.generate(
                          headers.length,
                          (index) =>
                              index == (isRtl ? 4 : 0)
                                  ? l.getKey('no_siblings')
                                  : '',
                        ),
                      ]
                      : siblings.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        var sib = entry.value;

                        // تحويل التاريخ إلى صيغة dd/mm/yyyy
                        String birth =
                            (sib['birthDate'] ?? sib['birth'])?.toString() ??
                            '';
                        if (birth.isNotEmpty) {
                          try {
                            final dateObj = DateTime.parse(birth);
                            birth =
                                '${dateObj.day.toString().padLeft(2, '0')}/${dateObj.month.toString().padLeft(2, '0')}/${dateObj.year}';
                          } catch (e) {
                            // Keep original format if parsing fails
                          }
                        }

                        // الحالة: مكفول أو غير مكفول
                        bool isSponsored = sib['isSponsored'] ?? false;
                        String status =
                            isSponsored
                                ? l.getKey('sponsored')
                                : l.getKey('not_sponsored');

                        String siblingName = sib['name']?.toString() ?? '';
                        if (locale.languageCode == 'en') {
                          siblingName = MultiLangTransliterator.toEnglish(
                            siblingName,
                          );
                        } else if (locale.languageCode == 'tr') {
                          siblingName = MultiLangTransliterator.toTurkish(
                            siblingName,
                          );
                        }

                        if (isRtl) {
                          return [
                            sib['id']?.toString() ?? '',
                            status,
                            birth,
                            siblingName,
                            index.toString(),
                          ];
                        } else {
                          return [
                            index.toString(),
                            siblingName,
                            birth,
                            status,
                            sib['id']?.toString() ?? '',
                          ];
                        }
                      }).toList(),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.blueGrey100,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(50),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FixedColumnWidth(75),
                3: const pw.FixedColumnWidth(65),
                4: const pw.FixedColumnWidth(70),
              },
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHealthTable(AppLocalizations l) {
    final healthProblem =
        (child.healthStatus.isNotEmpty &&
                child.healthStatus.toLowerCase() != 'healthy')
            ? l.getKey('yes')
            : l.getKey('no');
    String disabilityDisplay = child.disabilityType ?? '';
    if (disabilityDisplay.isNotEmpty) {
      if (locale.languageCode == 'en') {
        disabilityDisplay = MultiLangTransliterator.toEnglish(
          disabilityDisplay,
        );
      } else if (locale.languageCode == 'tr') {
        disabilityDisplay = MultiLangTransliterator.toTurkish(
          disabilityDisplay,
        );
      }
    }

    final healthStatusDisplay = child.getHealthStatusByLanguage(
      locale.languageCode,
    );
    return _buildTableSection(l.getKey('health_info_title'), [
      [l.getKey('any_health_problem'), healthProblem],
      [l.getKey('health_problem_description'), disabilityDisplay],
      [l.getKey('health_status_label'), healthStatusDisplay],
    ]);
  }

  pw.Widget _buildEducationTable(AppLocalizations l) {
    String educationLevelDisplay =
        child.getEducationLevelByLanguage(locale.languageCode) ?? '';
    String gradeDisplay =
        child.getGradeByLanguage(locale.languageCode) ?? child.grade ?? '';
    if (child.educationLevel == 'University' ||
        child.educationLevel == 'جامعي' ||
        child.educationLevel == 'education_level_university') {
      gradeDisplay =
          child.getUniversityYearByLanguage(locale.languageCode) ??
          child.universityYear ??
          '';
    }

    return _buildTableSection(l.getKey('education_info_title'), [
      [l.getKey('education_level_colon'), educationLevelDisplay],
      [l.getKey('school_name_colon'), child.schoolName ?? ''],
      [l.getKey('grade_colon'), gradeDisplay],
    ]);
  }

  pw.Widget _buildBankInfoTable(AppLocalizations l) {
    // Financial Info Table data -- branch on paymentMethod
    final bool isWallet = child.paymentMethod == 'wallet';
    List<List<String>> bankRows;
    if (isWallet) {
      bankRows = [
        [l.getKey('wallet_holder_name'), child.walletHolderName ?? ''],
        [l.getKey('linked_mobile_number'), child.walletNumber ?? ''],
      ];
    } else {
      bankRows = [
        [l.getKey('bank_name'), child.bankName ?? ''],
        [l.getKey('linked_mobile_number'), child.walletNumber ?? ''],
        [l.getKey('iban'), child.bankIban ?? ''],
        [l.getKey('account_holder'), child.bankAccountHolderName ?? ''],
      ];
    }

    // عكس ترتيب الأعمدة للغات RTL
    List<List<String>> displayRows = bankRows;
    if (locale.languageCode == 'ar') {
      displayRows = bankRows.map((row) => [row[1], row[0]]).toList();
    }

    // تعديل عرض الأعمدة حسب اتجاه اللغة
    Map<int, pw.FlexColumnWidth> columnWidths;
    if (locale.languageCode == 'ar') {
      columnWidths = {0: pw.FlexColumnWidth(70), 1: pw.FlexColumnWidth(30)};
    } else {
      columnWidths = {0: pw.FlexColumnWidth(30), 1: pw.FlexColumnWidth(70)};
    }

    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              l.getKey('financial_info'),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: _getTextAlign(),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: columnWidths,
              children: [
                for (var row in displayRows)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          row[0],
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          row[1],
                          style: pw.TextStyle(fontSize: 8),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContactInfoTable(AppLocalizations l) {
    // Contact Info Table data
    List<List<String>> contactRows = [
      [
        l.getKey('guardian_relationship'),
        child.getGuardianRelationshipByLanguage(locale.languageCode) ??
            child.guardianRelationship ??
            '',
      ],
      [
        l.getKey('country_label'),
        child.getCountryByLanguage(locale.languageCode) ?? child.country ?? '',
      ],
      [l.getKey('address'), child.street ?? ''],
      [l.getKey('phone'), child.guardianPhone ?? ''],
    ];

    // عكس ترتيب الأعمدة للغات RTL
    List<List<String>> displayRows = contactRows;
    if (locale.languageCode == 'ar') {
      displayRows = contactRows.map((row) => [row[1], row[0]]).toList();
    }

    // تعديل عرض الأعمدة حسب اتجاه اللغة
    Map<int, pw.FlexColumnWidth> columnWidths;
    if (locale.languageCode == 'ar') {
      columnWidths = {0: pw.FlexColumnWidth(70), 1: pw.FlexColumnWidth(30)};
    } else {
      columnWidths = {0: pw.FlexColumnWidth(30), 1: pw.FlexColumnWidth(70)};
    }

    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              l.getKey('contact_information'),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: _getTextAlign(),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: columnWidths,
              children: [
                for (var row in displayRows)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          row[0],
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          row[1],
                          style: pw.TextStyle(fontSize: 8),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableSection(
    String title,
    List<List<String>> rows, {
    int columnCount = 2,
  }) {
    // عكس ترتيب الأعمدة للغات RTL
    List<List<String>> displayRows = rows;
    if (locale.languageCode == 'ar') {
      displayRows = rows.map((row) => [row[1], row[0]]).toList();
    }

    // تعديل عرض الأعمدة حسب اتجاه اللغة
    Map<int, pw.FlexColumnWidth> columnWidths;
    if (locale.languageCode == 'ar') {
      columnWidths = {0: pw.FlexColumnWidth(70), 1: pw.FlexColumnWidth(30)};
    } else {
      columnWidths = {0: pw.FlexColumnWidth(30), 1: pw.FlexColumnWidth(70)};
    }

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: _getTextAlign(),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: columnWidths,
              children: [
                for (var row in displayRows)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          row[0],
                          style: pw.TextStyle(fontSize: 8),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          row[1],
                          style: pw.TextStyle(fontSize: 8),
                          textAlign: _getTextAlign(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 2),
      padding: pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
              textAlign: _getTextAlign(),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8),
              textAlign: _getTextAlign(),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailedPersonalInfo(AppLocalizations l) {
    String dob = '';
    if (child.dateOfBirth != null) {
      dob = child.dateOfBirth!.toLocal().toIso8601String().split('T').first;
    }
    String genderDisplay = '';
    if (child.gender != null) {
      genderDisplay =
          child.gender!.toUpperCase() == 'F'
              ? l.getKey('report_gender_female')
              : l.getKey('report_gender_male');
    }
    final countryDisplay =
        child.getCountryByLanguage(locale.languageCode) ?? child.country;

    final birthCountryDisplay =
        child.getBirthCountryByLanguage(locale.languageCode) ??
        child.birthCountry;
    final birthCityDisplay =
        child.getBirthCityByLanguage(locale.languageCode) ?? child.birthCity;

    List<List<String>> infoRows = [];
    infoRows.add([
      l.getKey('child_name'),
      child.getFullNameByLanguage(locale.languageCode),
    ]);
    if (dob.isNotEmpty) infoRows.add([l.getKey('birth_date'), dob]);
    if (genderDisplay.isNotEmpty)
      infoRows.add([l.getKey('gender'), genderDisplay]);
    if (birthCountryDisplay != null && birthCountryDisplay.isNotEmpty)
      infoRows.add([l.getKey('birth_country'), birthCountryDisplay]);
    if (birthCityDisplay != null && birthCityDisplay.isNotEmpty)
      infoRows.add([l.getKey('birth_city'), birthCityDisplay]);
    if (countryDisplay != null && countryDisplay.isNotEmpty)
      infoRows.add([l.getKey('country'), countryDisplay]);
    if (child.nationalId != null && child.nationalId!.isNotEmpty)
      infoRows.add([l.getKey('national_id'), child.nationalId!]);
    return _buildTableSection(
      locale.languageCode == 'ar'
          ? 'المعلومات الشخصية'
          : 'Personal Information',
      infoRows,
    );
  }

  pw.Widget _buildSponsorshipInfo(AppLocalizations l) {
    // Determine sponsorship status
    final isSponsored = child.sponsor != null && child.sponsor!.isOngoing;
    final statusText =
        isSponsored
            ? (locale.languageCode == 'ar' ? 'مكفول' : 'Sponsored')
            : (locale.languageCode == 'ar' ? 'غير مكفول' : 'Not Sponsored');
    final sponsorName =
        isSponsored
            ? child.sponsor!.getNameByLanguage(locale.languageCode)
            : (locale.languageCode == 'ar' ? 'لا يوجد كفيل' : 'No Sponsor');
    String startDate = '';
    if (child.sponsor?.startDate != null) {
      startDate =
          child.sponsor!.startDate.toLocal().toIso8601String().split('T').first;
    }
    String endDate = '';
    if (child.sponsor?.endDate != null) {
      endDate =
          child.sponsor!.endDate!.toLocal().toIso8601String().split('T').first;
    }
    String endReason = '';
    if (!isSponsored &&
        child.sponsor?.endReason != null &&
        child.sponsor!.endReason!.isNotEmpty) {
      endReason = child.sponsor!.endReason!;
    }
    List<List<String>> sponsorRows = [];
    sponsorRows.add([
      (locale.languageCode == 'ar' ? 'الحالة' : 'Status'),
      statusText,
    ]);
    sponsorRows.add([
      (locale.languageCode == 'ar' ? 'اسم الكفيل' : 'Sponsor Name'),
      sponsorName,
    ]);
    if (isSponsored && startDate.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar' ? 'بداية الكفالة' : 'Sponsorship Start'),
        startDate,
      ]);
    if (isSponsored && endDate.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar'
            ? 'تاريخ نهاية الكفالة'
            : 'Sponsorship End'),
        endDate,
      ]);
    if (!isSponsored && startDate.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar' ? 'بداية الكفالة' : 'Sponsorship Start'),
        startDate,
      ]);
    if (!isSponsored && endDate.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar'
            ? 'تاريخ نهاية الكفالة'
            : 'Sponsorship End'),
        endDate,
      ]);
    if (!isSponsored && endReason.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar' ? 'سبب انتهاء الكفالة' : 'End Reason'),
        endReason,
      ]);
    if (child.sponsor?.organizationName != null &&
        child.sponsor!.organizationName!.isNotEmpty)
      sponsorRows.add([
        (locale.languageCode == 'ar' ? 'اسم المنظمة' : 'Organization Name'),
        child.sponsor!.organizationName!,
      ]);
    return _buildTableSection(
      locale.languageCode == 'ar'
          ? 'معلومات الكفالة'
          : 'Sponsorship Information',
      sponsorRows,
    );
  }

  pw.Widget _buildSponsorshipPaymentsTable(
    AppLocalizations l,
    List<List<String>> paymentRows,
    pw.Context context,
  ) {
    final isRtl = locale.languageCode == 'ar';
    final title = l.getKey('detailed_payments_table');
    if (paymentRows.isEmpty) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(
          l.getKey('no_transactions_this_month'),
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          textAlign: _getTextAlign(),
        ),
      );
    }
    final headers =
        isRtl
            ? [
              l.getKey('sponsor_currency_label'),
              l.getKey('amount_label'),
              l.getKey('payment_date'),
            ]
            : [
              l.getKey('payment_date'),
              l.getKey('amount_label'),
              l.getKey('sponsor_currency_label'),
            ];
    final data =
        paymentRows.map((row) {
          final displayRow = [row[0], row[1], row[2]];
          return isRtl ? displayRow.reversed.toList() : displayRow;
        }).toList();
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: _getTextAlign(),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.TableHelper.fromTextArray(
              context: context,
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.center,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
              },
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentTotalsTable(
    AppLocalizations l,
    List<Payment> payments,
    pw.Context context,
  ) {
    final totals = <String, double>{};
    for (final p in payments) {
      final currency =
          child.sponsor?.getCurrencyByLanguage(locale.languageCode) ??
          _getCurrencyLabel(p.currency);
      totals[currency] = (totals[currency] ?? 0) + p.amount;
    }

    final isRtl = _getTextDirection() == pw.TextDirection.rtl;
    final headers =
        isRtl
            ? [l.getKey('total_label'), l.getKey('payment_currency_label')]
            : [l.getKey('payment_currency_label'), l.getKey('total_label')];

    final data =
        totals.entries.map((e) {
          final row = [e.key, e.value.toStringAsFixed(2)];
          return isRtl ? row.reversed.toList() : row;
        }).toList();

    return pw.Align(
      alignment: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Container(
        width: 250,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l.getKey('payment_totals_by_currency'),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.center,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Payment>> _getFilteredPaymentsList() async {
    if (child.sponsor == null) return [];
    try {
      final sqliteService = SqliteService();
      final payments = await sqliteService.listPayments(childId: child.id);
      if (includePaymentsTable && filterMode == 'none') {
        return payments;
      }
      return _filterPaymentsByDateRange(payments);
    } catch (e) {
      debugPrint('Error getting filtered payments list: $e');
      return [];
    }
  }

  Future<List<List<String>>> _getFilteredPayments() async {
    final filteredPayments = await _getFilteredPaymentsList();
    return filteredPayments.map((payment) {
        final dateStr =
            payment.paidAt.toLocal().toIso8601String().split('T').first;
        final amountStr = payment.amount.toStringAsFixed(2);
        String currencyStr = _getCurrencyLabel(payment.currency);
        if (child.sponsor != null) {
          currencyStr = child.sponsor!.getCurrencyByLanguage(
            locale.languageCode,
          );
        }
        return [dateStr, amountStr, currencyStr];
      }).toList()
      ..sort((a, b) => b[0].compareTo(a[0]));
  }

  List<Payment> _filterPaymentsByDateRange(List<Payment> payments) {
    switch (filterMode) {
      case 'monthly':
        // فرز حسب الشهر والسنة
        return payments.where((p) {
          final date = p.paidAt.toLocal();
          return date.year == selectedYear && date.month == selectedMonth;
        }).toList();

      case 'yearly':
        // فرز حسب السنة فقط
        return payments.where((p) {
          return p.paidAt.toLocal().year == selectedYear;
        }).toList();

      case 'range':
        // فرز حسب نطاق التاريخ من - إلى
        if (startDate == null || endDate == null) return [];
        return payments.where((p) {
          final date = p.paidAt.toLocal();
          final start = startDate!.toLocal();
          final end = endDate!.toLocal();
          return !date.isBefore(start) && !date.isAfter(end);
        }).toList();

      default:
        return [];
    }
  }

  String _getCurrencyLabel(String? currency) {
    final currencyMap = {
      'شيكل': 'ILS',
      'ILS': 'ILS',
      'دولار': 'USD',
      'USD': 'USD',
      '\$': 'USD',
      'يورو': 'EUR',
      'EUR': 'EUR',
      '€': 'EUR',
      'دينار': 'JOD',
      'JOD': 'JOD',
      'ريال': 'SAR',
      'SAR': 'SAR',
      'ليرة': 'TRY',
      'TRY': 'TRY',
      'TL': 'TRY',
    };

    return currencyMap[currency] ?? currency ?? 'ILS';
  }
}

Future<void> savePDFFile(List<int> bytes, String fileName) async {
  if (kIsWeb) return;
  try {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open('${output.path}/$fileName');
  } catch (e) {
    debugPrint('Error saving PDF locally: $e');
  }
}
