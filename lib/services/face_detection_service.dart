import 'package:flutter/foundation.dart';
import 'dart:io' show File, Platform;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FaceDetectionService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  /// Detects a face in the given image file and crops it with some padding.
  /// Returns the cropped face image file, or null if no face is detected or platform not supported.
  static Future<File?> detectAndCropFace(File imageFile) async {
    if (kIsWeb) return null; // Not supported on web
    // google_mlkit_face_detection only supports Android and iOS
    if (!(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('Face detection is not supported on this platform.');
      return null;
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return null; // Return null if no face is found
      }

      // We'll take the largest face if multiple faces are detected
      faces.sort(
        (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
          a.boundingBox.width * a.boundingBox.height,
        ),
      );

      final face = faces.first;
      final boundingBox = face.boundingBox;

      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      // Define cropping area with some padding to show the head properly
      // Padding is relative to the face width
      final paddingW = (boundingBox.width * 0.4).toInt();
      final paddingH = (boundingBox.height * 0.6).toInt();

      int left = (boundingBox.left - paddingW).toInt();
      int top = (boundingBox.top - paddingH).toInt();
      int width = (boundingBox.width + paddingW * 2).toInt();
      int height = (boundingBox.height + paddingH * 1.5).toInt();

      // Clamp values to ensure they are within image boundaries
      left = left.clamp(0, originalImage.width - 1);
      top = top.clamp(0, originalImage.height - 1);

      if (left + width > originalImage.width) {
        width = originalImage.width - left;
      }
      if (top + height > originalImage.height) {
        height = originalImage.height - top;
      }

      // Crop the image using the 'image' package
      final croppedImage = img.copyCrop(
        originalImage,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      // Save the cropped face to a temporary file
      final tempDir = await getTemporaryDirectory();
      final extension =
          p.extension(imageFile.path).isEmpty
              ? '.jpg'
              : p.extension(imageFile.path);
      final fileName =
          'face_${DateTime.now().millisecondsSinceEpoch}$extension';
      final tempPath = p.join(tempDir.path, fileName);

      final croppedFile = File(tempPath);

      // Encode back to the appropriate format (default to JPG)
      if (extension.toLowerCase() == '.png') {
        await croppedFile.writeAsBytes(img.encodePng(croppedImage));
      } else {
        await croppedFile.writeAsBytes(
          img.encodeJpg(croppedImage, quality: 90),
        );
      }

      return croppedFile;
    } catch (e) {
      print('Error in face detection/cropping: $e');
      return null;
    }
  }

  static void dispose() {
    _faceDetector.close();
  }
}
