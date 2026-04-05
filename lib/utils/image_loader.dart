import 'package:flutter/material.dart';

class ImageLoader {
  static Widget network(String url, {double? height, double? width, BoxFit? fit}) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );
  }

  static Widget asset(String path, {double? height, double? width, BoxFit? fit}) {
    return Image.asset(
      path,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $path');
        return const Icon(Icons.image_not_supported);
      },
    );
  }
}