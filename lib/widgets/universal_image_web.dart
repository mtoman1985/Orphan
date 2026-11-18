// Platform-specific implementation for web (no dart:io)
import 'package:flutter/material.dart';

Widget buildLocalFileImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget errorWidget,
}) {
  // Local files don't work on web, return error widget
  debugPrint('Local file paths are not supported on web: $path');
  return errorWidget;
}
