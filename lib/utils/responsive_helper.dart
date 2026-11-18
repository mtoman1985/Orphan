import 'package:flutter/material.dart';

/// فئة للمساعدة في التصميم الاستجابي
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// الحصول على عرض الشاشة
  double get screenWidth => MediaQuery.of(context).size.width;

  /// الحصول على ارتفاع الشاشة
  double get screenHeight => MediaQuery.of(context).size.height;

  /// الحصول على نسبة العرض إلى الارتفاع
  double get screenRatio => screenWidth / screenHeight;

  /// التحقق من كون الشاشة بتوجيه أفقي (Landscape)
  bool get isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// التحقق من كون الشاشة بتوجيه عمودي (Portrait)
  bool get isPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// التحقق من كون الجهاز صغيراً (الهواتف)
  bool get isSmallScreen => screenWidth < 600;

  /// التحقق من كون الجهاز متوسطاً (الأجهزة اللوحية الصغيرة)
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1024;

  /// التحقق من كون الجهاز كبيراً (الأجهزة اللوحية والشاشات)
  bool get isLargeScreen => screenWidth >= 1024;

  /// الحصول على حجم الخط المتجاوب
  double fontSizeSmall() =>
      isSmallScreen
          ? 12
          : isLargeScreen
          ? 14
          : 13;
  double fontSizeRegular() =>
      isSmallScreen
          ? 14
          : isLargeScreen
          ? 16
          : 15;
  double fontSizeMedium() =>
      isSmallScreen
          ? 16
          : isLargeScreen
          ? 18
          : 17;
  double fontSizeLarge() =>
      isSmallScreen
          ? 18
          : isLargeScreen
          ? 20
          : 19;
  double fontSizeXLarge() =>
      isSmallScreen
          ? 20
          : isLargeScreen
          ? 24
          : 22;

  /// الحصول على padding متجاوب
  EdgeInsets paddingSmall() => EdgeInsets.all(
    isSmallScreen
        ? 8
        : isLargeScreen
        ? 12
        : 10,
  );
  EdgeInsets paddingRegular() => EdgeInsets.all(
    isSmallScreen
        ? 12
        : isLargeScreen
        ? 16
        : 14,
  );
  EdgeInsets paddingLarge() => EdgeInsets.all(
    isSmallScreen
        ? 16
        : isLargeScreen
        ? 24
        : 20,
  );

  /// الحصول على width متجاوب للعناصر
  double getResponsiveWidth(
    double smallWidth,
    double mediumWidth,
    double largeWidth,
  ) {
    if (isSmallScreen) return smallWidth;
    if (isMediumScreen) return mediumWidth;
    return largeWidth;
  }

  /// الحصول على height متجاوب للعناصر
  double getResponsiveHeight(
    double smallHeight,
    double mediumHeight,
    double largeHeight,
  ) {
    if (isSmallScreen) return smallHeight;
    if (isMediumScreen) return mediumHeight;
    return largeHeight;
  }

  /// الحصول على نسبة مئوية من عرض الشاشة
  double widthPercent(double percent) => screenWidth * (percent / 100);

  /// الحصول على نسبة مئوية من ارتفاع الشاشة
  double heightPercent(double percent) => screenHeight * (percent / 100);
}

/// Extension للتسهيل الوصول إلى ResponsiveHelper
extension ResponsiveExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

// تحديد حجم الشاشة
// isSmallScreen   // < 600px (هواتف)
// isMediumScreen  // 600-1024px (أجهزة لوحية صغيرة)
// isLargeScreen   // >= 1024px (شاشات كبيرة)

// حجم الخطوط المتجاوبة
// fontSizeSmall(), fontSizeRegular(), fontSizeMedium(), etc.

// Padding متجاوب
// paddingSmall(), paddingRegular(), paddingLarge()

// نسب مئوية من حجم الشاشة
// widthPercent(40)  // 40% من عرض الشاشة
// heightPercent(50) // 50% من ارتفاع الشاشة
