import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:orphan/l10n/app_localizations.dart';
import 'package:orphan/l10n/app_localizations_extension.dart';

class ReportSharedWidgets {
  /// Builds the unified header for PDF reports
  static pw.Widget buildHeader(
    AppLocalizations l,
    pw.ImageProvider logo,
    String? reportTitleKey, {
    String? overrideOrganizationName,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'برنامج كفالة الأيتام',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              if (reportTitleKey != null)
                pw.Text(
                  l.getKey(reportTitleKey),
                  style: pw.TextStyle(
                    fontSize: 14, // Slightly smaller than program title
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Image(logo, height: 60),
              pw.Text(
                overrideOrganizationName ?? 'جمعية إحسان للإغاثة الإنسانية',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a thick gradient line
  static pw.Widget buildThickLine() {
    return pw.Container(
      height: 3,
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue400, PdfColors.blue800],
        ),
      ),
    );
  }
}
