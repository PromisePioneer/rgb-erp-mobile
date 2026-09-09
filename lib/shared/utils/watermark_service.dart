import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Service for adding watermarks to photos
/// Watermark format: "{dd-MM-yyyy} {HH:mm}\n{areaName}\n{namaUserLogin}"
class WatermarkService {
  /// Singleton instance
  static final WatermarkService _instance = WatermarkService._internal();
  factory WatermarkService() => _instance;
  WatermarkService._internal();

  /// Date format for watermark text
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy HH:mm');

  /// Add watermark to an image taken from camera
  ///
  /// [image] - The XFile image from camera picker
  /// [areaName] - Name of the area where the photo was taken
  /// [userName] - Name of the user who took the photo
  ///
  /// Returns the watermarked image as PNG bytes
  Future<Uint8List> watermarkImage({
    required XFile image,
    required String areaName,
    required String userName,
  }) async {
    // Read the original image bytes
    final originalBytes = await image.readAsBytes();

    // Decode the image
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    // Get image dimensions
    final width = originalImage.width.toDouble();
    final height = originalImage.height.toDouble();

    // Create a picture recorder to capture the watermarked image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Calculate font size based on image dimensions
    // Use smaller font for smaller images, but cap at reasonable size
    final baseFontSize = (width * 0.035).clamp(24.0, 48.0);

    // Build watermark text
    final timestamp = _dateFormat.format(DateTime.now());
    final watermarkText = '$timestamp\n$areaName\n$userName';

    // Create text style
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: baseFontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(
          offset: Offset(2, 2),
          blurRadius: 4,
          color: Colors.black54,
        ),
        Shadow(
          offset: Offset(-1, -1),
          blurRadius: 2,
          color: Colors.black54,
        ),
      ],
    );

    // Measure text to calculate background size
    final textPainter = TextPainter(
      text: TextSpan(text: watermarkText, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width * 0.45);

    // Position at bottom-left with padding
    final padding = width * 0.03;
    final bgPadding = padding * 0.5;
    final textX = padding + bgPadding;
    final textY = height - padding - bgPadding - textPainter.height;

    // Draw semi-transparent background for better readability
    final bgRect = Rect.fromLTWH(
      padding,
      textY - bgPadding,
      textPainter.width + bgPadding * 2,
      textPainter.height + bgPadding * 2,
    );

    // Draw rounded rectangle background
    final bgPaint = Paint()
      ..color = Colors.black.withAlpha(153); // 60% opacity
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      bgPaint,
    );

    // Draw the watermark text
    textPainter.paint(canvas, Offset(textX, textY));

    // Convert to image
    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to render watermarked image');
    }

    return byteData.buffer.asUint8List();
  }

  /// Clean up temporary watermarked files
  Future<void> cleanupTempFiles() async {
    // No temp files for images - they are in memory
  }
}
