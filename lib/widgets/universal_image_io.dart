// Platform-specific implementation for non-web (uses dart:io)
import 'dart:io';
import 'package:flutter/material.dart';

Widget buildLocalFileImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget errorWidget,
}) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      return errorWidget;
    }
  } catch (e) {
    debugPrint('Error loading local file: $e');
    return errorWidget;
  }
}
