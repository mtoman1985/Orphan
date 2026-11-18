import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:pdf/widgets.dart' as pw;
import 'package:arabic_reshaper/arabic_reshaper.dart';

/// مساعد لتحميل الخطوط العربية للتقارير PDF
class ArabicFontLoader {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;
  static Uint8List? _cachedLogoBytes;
  static bool _isLoading = false;

  /// تحميل الخطوط من Assets المحلية
  static Future<Map<String, pw.Font>> loadFromAssets() async {
    // إرجاع من الكاش إذا كان متوفراً
    if (_cachedRegularFont != null && _cachedBoldFont != null) {
      print('✅ Using cached fonts');
      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    }

    // محاولة تحميل NotoSansArabic
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSansArabic-Regular.ttf',
      );
      final boldData = await rootBundle.load(
        'assets/fonts/NotoSansArabic-Bold.ttf',
      );
      _cachedRegularFont = pw.Font.ttf(fontData);
      _cachedBoldFont = pw.Font.ttf(boldData);
      print('✅ NotoSansArabic fonts loaded successfully');
      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    } catch (e) {
      print('❌ Error loading NotoSansArabic fonts: $e');
    }

    // Fallback إلى Amiri
    try {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      _cachedRegularFont = pw.Font.ttf(fontData);
      _cachedBoldFont = pw.Font.ttf(boldData);
      print('✅ Amiri fonts loaded as fallback');
      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    } catch (e) {
      print('❌ Error loading Amiri fonts: $e');
    }

    // Fallback إلى Cairo
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _cachedRegularFont = pw.Font.ttf(fontData);
      _cachedBoldFont = pw.Font.ttf(boldData);
      print('✅ Cairo fonts loaded as fallback');
      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    } catch (e) {
      print('❌ Error loading Cairo fonts: $e');
    }

    // آخر خيار: Helvetica
    print('⚠️ Using Helvetica as last fallback');
    return {'regular': pw.Font.helvetica(), 'bold': pw.Font.helveticaBold()};
  }

  /// تحميل Noto Sans Arabic من Google Fonts مباشرة
  static Future<Map<String, pw.Font>> loadFromGoogle() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) {
      print('✅ Using cached Google Fonts');
      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    }

    try {
      print('🌐 Downloading Noto Sans Arabic from Google Fonts...');

      // URLs مباشرة لـ Noto Sans Arabic
      const regularUrl =
          'https://github.com/google/fonts/raw/main/ofl/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf';
      const boldUrl =
          'https://github.com/google/fonts/raw/main/ofl/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf';

      // تحميل Regular
      final regularResponse = await http
          .get(Uri.parse(regularUrl))
          .timeout(const Duration(seconds: 30));
      if (regularResponse.statusCode != 200) {
        throw Exception(
          'Failed to download regular font: ${regularResponse.statusCode}',
        );
      }

      // تحميل Bold (نفس الملف لأنه Variable Font)
      final boldResponse = await http
          .get(Uri.parse(boldUrl))
          .timeout(const Duration(seconds: 30));
      if (boldResponse.statusCode != 200) {
        throw Exception(
          'Failed to download bold font: ${boldResponse.statusCode}',
        );
      }

      // تحويل إلى Font objects
      _cachedRegularFont = pw.Font.ttf(
        ByteData.view(regularResponse.bodyBytes.buffer),
      );
      _cachedBoldFont = pw.Font.ttf(
        ByteData.view(boldResponse.bodyBytes.buffer),
      );

      print('✅ Successfully downloaded Google Fonts');

      return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
    } catch (e) {
      print('❌ Failed to download fonts from Google: $e');
      rethrow;
    }
  }

  /// تحميل مع fallback تلقائي - الطريقة الموصى بها
  static Future<Map<String, pw.Font>> loadWithFallback() async {
    // منع التحميل المتزامن المتعدد
    if (_isLoading) {
      // انتظر حتى ينتهي التحميل الحالي
      await Future.delayed(const Duration(milliseconds: 100));
      if (_cachedRegularFont != null && _cachedBoldFont != null) {
        return {'regular': _cachedRegularFont!, 'bold': _cachedBoldFont!};
      }
    }

    _isLoading = true;

    try {
      // محاولة 1: من Assets المحلية
      try {
        final fonts = await loadFromAssets();
        _isLoading = false;
        return fonts;
      } catch (e) {
        print('⚠️ Local fonts failed, trying online...');
      }

      // محاولة 2: من الإنترنت
      try {
        final fonts = await loadFromGoogle();
        _isLoading = false;
        return fonts;
      } catch (e) {
        print('⚠️ Online fonts failed, using system fallback');
      }

      // آخر خيار: Helvetica
      _isLoading = false;
      return {'regular': pw.Font.helvetica(), 'bold': pw.Font.helveticaBold()};
    } catch (e) {
      _isLoading = false;
      return {'regular': pw.Font.helvetica(), 'bold': pw.Font.helveticaBold()};
    }
  }

  /// مسح الكاش (مفيد عند تغيير الخطوط)
  static void clearCache() {
    _cachedRegularFont = null;
    _cachedBoldFont = null;
    _cachedLogoBytes = null;
    print('🗑️ Font and logo cache cleared');
  }

  /// تحميل الشعار وتخزينه مؤقتاً
  static Future<pw.MemoryImage> loadLogo() async {
    if (_cachedLogoBytes != null) {
      return pw.MemoryImage(_cachedLogoBytes!);
    }
    final data = await rootBundle.load('assets/images/ihsan_report.png');
    _cachedLogoBytes = data.buffer.asUint8List();
    return pw.MemoryImage(_cachedLogoBytes!);
  }

  /// التحقق من توفر الكاش
  static bool get isCached =>
      _cachedRegularFont != null && _cachedBoldFont != null;

  static final ArabicReshaper _reshaper = ArabicReshaper();

  /// معالجة النص العربي للعرض الصحيح في PDF
  /// يستخدم arabic_reshaper لتحويل الحروف المنفصلة إلى أشكالها المتصلة
  static String processArabicText(String text) {
    if (text.isEmpty) return text;

    // التحقق إذا كان النص يحتوي على عربي
    final arabicRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    if (!arabicRegex.hasMatch(text)) {
      return text;
    }

    // استخدام النسخة المخزنة من arabic_reshaper لمعالجة النص العربي
    // ثم عكس النص للعرض الصحيح في PDF
    final reshaped = _reshaper.reshape(text);
    return _reverseArabicText(reshaped);
  }

  /// عكس النص العربي مع الحفاظ على الأرقام والنص الإنجليزي
  static String _reverseArabicText(String text) {
    // تقسيم النص إلى أجزاء
    final buffer = StringBuffer();
    final segments = <_TextSegment>[];

    int i = 0;
    while (i < text.length) {
      final char = text[i];
      final isArabic = _isArabicChar(char);

      // جمع الحروف المتشابهة
      int j = i + 1;
      while (j < text.length && _isArabicChar(text[j]) == isArabic) {
        j++;
      }

      segments.add(_TextSegment(text.substring(i, j), isArabic));
      i = j;
    }

    // عكس ترتيب الأجزاء العربية
    for (final segment in segments.reversed) {
      if (segment.isArabic) {
        buffer.write(segment.text);
      } else {
        buffer.write(segment.text);
      }
    }

    return buffer.toString();
  }

  /// التحقق إذا كان الحرف عربي
  static bool _isArabicChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 0x0600 && code <= 0x06FF) || // Arabic
        (code >= 0x0750 && code <= 0x077F) || // Arabic Supplement
        (code >= 0x08A0 && code <= 0x08FF) || // Arabic Extended-A
        (code >= 0xFB50 && code <= 0xFDFF) || // Arabic Presentation Forms-A
        (code >= 0xFE70 && code <= 0xFEFF); // Arabic Presentation Forms-B
  }

  /// إنشاء نص PDF مع دعم العربية الكامل
  static pw.Text createArabicText(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.right,
    pw.TextDirection textDirection = pw.TextDirection.rtl,
  }) {
    return pw.Text(
      processArabicText(text),
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }

  /// إنشاء RichText للنصوص المعقدة
  static pw.RichText createArabicRichText(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.RichText(
      text: pw.TextSpan(text: processArabicText(text), style: style),
      textAlign: textAlign,
      textDirection: pw.TextDirection.rtl,
    );
  }
}

/// كلاس مساعد لتقسيم النص
class _TextSegment {
  final String text;
  final bool isArabic;

  _TextSegment(this.text, this.isArabic);
}
