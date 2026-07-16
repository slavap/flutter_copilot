import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the current widget tree as a screenshot image.
class ScreenshotCapture {
  /// Captures the current render tree as a base64-encoded PNG string.
  ///
  /// Returns `null` if no rendering context is available or capture fails.
  Future<String?> captureAsBase64() async {
    final binding = WidgetsBinding.instance;
    final renderViews = binding.renderViews;
    if (renderViews.isEmpty) return null;

    final renderView = renderViews.first;
    // ignore: invalid_use_of_protected_member
    final layer = renderView.layer;
    if (layer == null || layer is! OffsetLayer) return null;

    try {
      final view = binding.platformDispatcher.views.first;
      final size = view.physicalSize;
      if (size.isEmpty) return null;

      final image = await layer.toImage(
        Offset.zero & size,
        pixelRatio: view.devicePixelRatio,
      );

      try {
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;
        return base64Encode(byteData.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    } catch (_) {
      return null;
    }
  }
}
