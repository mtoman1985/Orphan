import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/child.dart';

class PdfService {
  // Define Brand Colors
  static const PdfColor primaryColor = PdfColor.fromInt(
    0xFFD32F2F,
  ); // Red 700 (TESTING)
  static const PdfColor accentColor = PdfColor.fromInt(0xFFE3F2FD); // Blue 50
  static const PdfColor headerBgColor = PdfColor.fromInt(
    0xFFBBDEFB,
  ); // Blue 100
  static const PdfColor borderColor = PdfColor.fromInt(0xFF90CAF9); // Blue 200
  static const PdfColor textColor = PdfColor.fromInt(0xFF212121); // Grey 900
  static const PdfColor labelColor = PdfColor.fromInt(0xFF616161); // Grey 700

  static Future<Uint8List> generateOrphanReport(Child child) async {
    final pdf = pw.Document();

    // Load Fonts
    final fontRegularData = await rootBundle.load(
      "assets/fonts/Cairo-Regular.ttf",
    );
    debugPrint('Printing Orphan Report v3.0 - NEW LAYOUT');
    final fontBoldData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final ttfRegular = pw.Font.ttf(fontRegularData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    // Load Logo
    pw.MemoryImage? logo;
    try {
      final logoImage = await rootBundle.load('assets/logo.png');
      logo = pw.MemoryImage(logoImage.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    // Basic Theme
    final theme = pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold);

    // Load Child Photo if available
    Uint8List? childPhotoBytes;
    final profilePhotos =
        child.documents.where((document) => document.type == 'Profile').toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final latestPhotoPath =
        profilePhotos.isNotEmpty
            ? profilePhotos.first.filePath
            : child.childPhotoPath;
    if (latestPhotoPath != null) {
      try {
        if (!kIsWeb) {
          final file = File(latestPhotoPath);
          if (await file.exists()) {
            childPhotoBytes = await file.readAsBytes();
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }

    // Load Avatars (PNG)
    Uint8List? avatarBoyBytes;
    Uint8List? avatarGirlBytes;
    try {
      final boyData = await rootBundle.load('assets/images/avatar_boy.png');
      avatarBoyBytes = boyData.buffer.asUint8List();

      final girlData = await rootBundle.load('assets/images/avatar_girl.png');
      avatarGirlBytes = girlData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading avatars: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ========================
                // Header
                // ========================
                _buildHeader(logo),
                pw.SizedBox(height: 10),

                // ========================
                // Main Section: Photo + Sponsorship + Personal Info
                // ========================
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Sponsorship Info (Right in RTL)
                    pw.Expanded(
                      flex: 3,
                      child: _buildSectionBox(
                        title: 'أولاً: معلومات الكفالة',
                        child: pw.Column(
                          children: [
                            _buildDataRow(
                              'رقم الكفالة:',
                              child.childIdNumber ?? '',
                            ),
                            _buildDataRow(
                              'تاريخ بداية الكفالة:',
                              _formatDate(child.sponsorLinkedAt),
                            ),
                            _buildDataRow('تاريخ نهاية الكفالة:', ''),
                            _buildDataRow('سبب انتهاء الكفالة:', ''),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    // Personal Info (Middle in RTL)
                    pw.Expanded(
                      flex: 4,
                      child: _buildSectionBox(
                        title: 'ثانياً: المعلومات الشخصية لليتيم',
                        child: pw.Column(
                          children: [
                            _buildDataRow('الاسم:', child.firstName ?? ''),
                            _buildDataRow('الكنية:', child.lastName ?? ''),
                            _buildDataRow(
                              'تاريخ الميلاد:',
                              _formatDate(child.dateOfBirth),
                            ),
                            _buildDataRow(
                              'مكان الميلاد:',
                              '${child.city ?? ''} ${child.country ?? ''}',
                            ),
                            _buildDataRow(
                              'الجنس:',
                              child.gender == 'M' || child.gender == 'Male'
                                  ? 'ذكر'
                                  : 'أنثى',
                            ),
                            _buildDataRow(
                              'الجنسية:',
                              child.country ?? 'فلسطيني',
                            ),
                            _buildDataRow(
                              'رقم الوثيقة الشخصية:',
                              child.nationalId ?? '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    // Photo (Left)
                    _buildPhotoBox(
                      childPhotoBytes,
                      child.gender,
                      avatarBoyBytes,
                      avatarGirlBytes,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // ========================
                // Family Data (Father + Mother side by side)
                // ========================
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Father Info (Right - First in RTL)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'بيانات الأب',
                        child: pw.Column(
                          children: [
                            _buildDataRow('اسم الأب:', child.fatherName ?? ''),
                            _buildDataRow('هل الأب على قيد الحياة؟', 'لا'),
                            _buildDataRow(
                              'تاريخ وفاة الأب:',
                              _formatDate(child.fatherDeathDate),
                            ),
                            _buildDataRow(
                              'سبب الوفاة:',
                              child.fatherDeathCause ?? '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    // Mother Info (Left - Second in RTL)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'بيانات الأم',
                        child: pw.Column(
                          children: [
                            _buildDataRow(
                              'اسم وكنية الأم:',
                              child.motherName ?? '',
                            ),
                            _buildDataRow(
                              'هل الأم على قيد الحياة؟',
                              child.motherStatus == 'Deceased' ? 'لا' : 'نعم',
                            ),
                            _buildDataRow(
                              'تاريخ وفاة الأم:',
                              child.motherDeathDate != null
                                  ? _formatDate(child.motherDeathDate)
                                  : '—',
                            ),
                            _buildDataRow(
                              'سبب وفاة الأم:',
                              child.motherDeathCause != null &&
                                      child.motherDeathCause!.isNotEmpty
                                  ? child.motherDeathCause!
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // ========================
                // Siblings Table
                // ========================
                _buildSectionBox(
                  title: 'بيانات الأخوة',
                  padding: pw.EdgeInsets.zero, // Table handles its own padding
                  child: pw.Table(
                    border: pw.TableBorder.all(color: borderColor, width: 0.5),
                    columnWidths: {
                      0: pw.FlexColumnWidth(3), // Name
                      1: pw.FlexColumnWidth(2), // DOB
                      2: pw.FlexColumnWidth(1), // Gender
                      3: pw.FlexColumnWidth(2), // School
                      4: pw.FlexColumnWidth(1.5), // Grade
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: headerBgColor),
                        children: [
                          _cellText('الاسم', isHeader: true),
                          _cellText('تاريخ الميلاد', isHeader: true),
                          _cellText('الجنس', isHeader: true),
                          _cellText('المدرسة', isHeader: true),
                          _cellText('الصف', isHeader: true),
                        ],
                      ),
                      // Data Rows
                      if (child.siblings.isNotEmpty)
                        ...child.siblings.map((sib) {
                          String genderStr = sib['gender']?.toString() ?? '';
                          if (genderStr == 'M' || genderStr == 'Male')
                            genderStr = 'ذكر';
                          else if (genderStr == 'F' || genderStr == 'Female')
                            genderStr = 'أنثى';

                          return pw.TableRow(
                            children: [
                              _cellText(sib['name']?.toString() ?? ''),
                              _cellText(sib['birthDate']?.toString() ?? ''),
                              _cellText(genderStr),
                              _cellText(sib['school']?.toString() ?? ''),
                              _cellText(sib['grade']?.toString() ?? ''),
                            ],
                          );
                        })
                      else
                        ...List.generate(
                          3,
                          (index) => pw.TableRow(
                            children: [
                              _cellText(' ', height: 15),
                              _cellText(' '),
                              _cellText(' '),
                              _cellText(' '),
                              _cellText(' '),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // ========================
                // Education + Health (side by side)
                // ========================
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Health Info (Right)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'المعلومات الصحية',
                        child: pw.Column(
                          children: [
                            _buildDataRow(
                              'مشاكل صحية:',
                              child.healthStatus == 'Healthy' ? 'لا' : 'نعم',
                            ),
                            _buildDataRow(
                              'الوصف:',
                              child.healthStatus != 'Healthy'
                                  ? (child.disabilityType ?? '')
                                  : '',
                            ),
                            _buildDataRow('الطول:', ''),
                            _buildDataRow('الوزن:', ''),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    // Education Info (Left)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'معلومات التعليم',
                        child: pw.Column(
                          children: [
                            _buildDataRow(
                              'المستوى:',
                              child.educationLevel ?? '',
                            ),
                            _buildDataRow('المدرسة:', ''),
                            _buildDataRow('الصف:', child.grade ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // ========================
                // Contact + Bank (side by side)
                // ========================
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Financial Info (Right)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'البيانات المالية',
                        child: pw.Column(
                          children:
                              child.paymentMethod == 'wallet'
                                  ? [
                                    _buildDataRow(
                                      'اسم صاحب المحفظة:',
                                      child.walletHolderName ?? '',
                                    ),
                                    _buildDataRow(
                                      'رقم الموبايل:',
                                      child.walletNumber ?? '',
                                    ),
                                  ]
                                  : [
                                    _buildDataRow(
                                      'البنك:',
                                      child.bankName ?? '',
                                    ),
                                    _buildDataRow(
                                      'الموبايل:',
                                      child.walletNumber ?? '',
                                    ),
                                    _buildDataRow(
                                      'IBAN:',
                                      child.bankIban ?? '',
                                    ),
                                    _buildDataRow(
                                      'صاحب الحساب:',
                                      child.bankAccountHolderName ?? '',
                                    ),
                                  ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    // Contact Info (Left)
                    pw.Expanded(
                      child: _buildSectionBox(
                        title: 'معلومات التواصل',
                        child: pw.Column(
                          children: [
                            _buildDataRow('البلد:', child.country ?? ''),
                            _buildDataRow(
                              'العنوان:',
                              "${child.city ?? ''} ${child.street ?? ''}",
                            ),
                            _buildDataRow('الهاتف:', child.guardianPhone ?? ''),
                            _buildDataRow('الإيميل:', ''),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Footer
                pw.Spacer(),
                pw.Container(
                  padding: pw.EdgeInsets.only(top: 5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: borderColor)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'IHSAN Charity System',
                        style: pw.TextStyle(fontSize: 8, color: labelColor),
                      ),
                      pw.Text(
                        'تاريخ التقرير: ${_formatDate(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 8, color: labelColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ========================
  // Styles & Helpers
  // ========================

  static pw.Widget _buildSectionBox({
    required String title,
    required pw.Widget child,
    pw.EdgeInsetsGeometry? padding,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF9C4), // Yellow 100
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(12),
                topRight: pw.Radius.circular(12),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          // Content
          pw.Padding(
            padding: padding ?? const pw.EdgeInsets.all(6),
            child: child,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Container(height: 3, color: primaryColor),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Logo side
            pw.Row(
              children: [
                if (logo != null) pw.Image(logo, width: 50, height: 50),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IHSAN İNSANİ YARDIMLAŞMA DERNEĞİ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      '(جمعية إحسان للمساعدات الإنسانية) - v3.9 YELLOW TEST',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
            // Title side
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'برنامج كفالة الأيتام',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    'استمارة يتيم',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 1, color: borderColor),
      ],
    );
  }

  static pw.Widget _buildPhotoBox(
    Uint8List? photoBytes,
    String? gender,
    Uint8List? boyBytes,
    Uint8List? girlBytes,
  ) {
    return pw.Container(
      width: 90,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.white,
      ),
      child: pw.AspectRatio(
        aspectRatio: 3 / 4,
        child:
            photoBytes != null
                ? pw.ClipRRect(
                  horizontalRadius: 3,
                  verticalRadius: 3,
                  child: pw.Image(
                    pw.MemoryImage(photoBytes),
                    fit: pw.BoxFit.cover,
                  ),
                )
                : _buildAvatar(gender, boyBytes, girlBytes),
      ),
    );
  }

  static pw.Widget _buildAvatar(
    String? gender,
    Uint8List? boyBytes,
    Uint8List? girlBytes,
  ) {
    Uint8List? targetBytes;
    if (gender == 'M' || gender == 'Male' || gender == 'ذكر') {
      targetBytes = boyBytes;
    } else if (gender == 'F' || gender == 'Female' || gender == 'أنثى') {
      targetBytes = girlBytes;
    }

    // Default to boy if gender unknown
    targetBytes ??= boyBytes;

    if (targetBytes != null) {
      return pw.ClipRRect(
        horizontalRadius: 3,
        verticalRadius: 3,
        child: pw.Image(pw.MemoryImage(targetBytes), fit: pw.BoxFit.contain),
      );
    }

    // Fallback if no Image available
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 40,
          height: 40,
          decoration: const pw.BoxDecoration(
            color: accentColor,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'صورة اليتيم',
          style: pw.TextStyle(fontSize: 8, color: labelColor),
        ),
      ],
    );
  }

  static pw.Widget _buildDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: labelColor)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.5,
                    style: pw.BorderStyle.dotted,
                  ),
                ),
              ),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cellText(
    String text, {
    bool isHeader = false,
    double? height,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: height,
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: isHeader ? primaryColor : textColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}/${date.month}/${date.year}";
  }
}
