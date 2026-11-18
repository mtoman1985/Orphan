import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/github_storage_service.dart';
// Conditional import for File support
import 'universal_image_io.dart'
    if (dart.library.html) 'universal_image_web.dart';

class UniversalImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool isCircle;

  const UniversalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (path.isEmpty) {
      imageWidget = _buildErrorWidget(context);
    } else if (path.startsWith('http')) {
      // GitHub or other URL
      imageWidget = CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        httpHeaders: GitHubStorageService.getHeaders(),
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) {
          debugPrint('Image Load Error: $error for $url');
          return errorWidget ?? _buildErrorWidget(context);
        },
      );
    } else if (path.startsWith('assets/')) {
      // Asset images work on all platforms
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder:
            (ctx, err, stack) => errorWidget ?? _buildErrorWidget(context),
      );
    } else if (kIsWeb) {
      // Local file paths don't work on web
      imageWidget = errorWidget ?? _buildErrorWidget(context);
    } else {
      // Local File - use platform-specific implementation
      imageWidget = buildLocalFileImage(
        path: path,
        width: width,
        height: height,
        fit: fit,
        errorWidget: errorWidget ?? _buildErrorWidget(context),
      );
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey[400],
          size: (width != null && width! < 40) ? 16 : 24,
        ),
      ),
    );
  }
}
