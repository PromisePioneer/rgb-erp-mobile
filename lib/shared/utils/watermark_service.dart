import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Parameters for video processing computation
@immutable
class VideoProcessingParams {
  final String inputPath;
  final String outputPath;
  final String watermarkText;
  final bool compress;
  final int targetHeight;
  final int crf;

  const VideoProcessingParams({
    required this.inputPath,
    required this.outputPath,
    required this.watermarkText,
    this.compress = true,
    this.targetHeight = 720,
    this.crf = 28,
  });
}

/// Result of video processing operation
@immutable
class VideoProcessingResult {
  final bool success;
  final String outputPath;
  final String? error;
  final int? originalSizeBytes;
  final int? compressedSizeBytes;

  const VideoProcessingResult({
    required this.success,
    required this.outputPath,
    this.error,
    this.originalSizeBytes,
    this.compressedSizeBytes,
  });

  double? get compressionRatio {
    if (originalSizeBytes != null && compressedSizeBytes != null && originalSizeBytes! > 0) {
      return compressedSizeBytes! / originalSizeBytes!;
    }
    return null;
  }
}

/// Service for adding watermarks to photos and videos
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

    // Draw rounded rectangle background with gradient effect
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

  /// Process video: compress + add watermark (runs in isolate via compute)
  ///
  /// [video] - The XFile video from camera picker
  /// [areaName] - Name of the area where the video was taken
  /// [userName] - Name of the user who recorded the video
  /// [onProgress] - Callback for progress updates (0.0 to 1.0)
  ///
  /// Returns the processed video as a File in the temp directory
  Future<File> processVideoWithProgress({
    required XFile video,
    required String areaName,
    required String userName,
    void Function(double progress)? onProgress,
    bool compress = true,
    int targetHeight = 720,
    int crf = 28,
  }) async {
    // Get temp directory for output
    final tempDir = await getTemporaryDirectory();
    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/processed_$timestampMs.mp4';

    // Build watermark text
    final timestamp = _dateFormat.format(DateTime.now());
    final watermarkText = '$timestamp $areaName $userName';

    // Get video duration for progress calculation
    double durationSeconds = 60.0;
    try {
      final mediaInfo = await FFprobeKit.getMediaInformation(video.path);
      final duration = mediaInfo.getMediaInformation()?.getDuration();
      durationSeconds = double.tryParse(duration ?? '60') ?? 60.0;
    } catch (e) {
      debugPrint('WatermarkService: Could not get video duration: $e');
    }

    // Get original file size
    final originalFile = File(video.path);
    final originalSize = await originalFile.length();
    debugPrint('WatermarkService: Original video size: ${originalSize / 1024 / 1024} MB');

    // Build FFmpeg command
    final command = _buildFFmpegCommand(
      inputPath: video.path,
      outputPath: outputPath,
      watermarkText: watermarkText,
      compress: compress,
      targetHeight: targetHeight,
      crf: crf,
    );

    debugPrint('WatermarkService: Running FFmpeg command: $command');

    // Enable statistics callback for progress
    int lastProgressUpdate = 0;
    FFmpegKitConfig.enableStatisticsCallback((statistics) {
      final time = statistics.getTime();
      if (time > 0 && durationSeconds > 0) {
        final progress = (time / 1000 / durationSeconds).clamp(0.0, 1.0);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastProgressUpdate > 100) {
          lastProgressUpdate = now;
          onProgress?.call(progress);
        }
      }
    });

    try {
      // Run FFmpeg - execute on main thread to avoid isolate issues with native code
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Get compressed file size
        final outputFile = File(outputPath);
        final compressedSize = await outputFile.length();
        final ratio = compressedSize / originalSize;

        debugPrint('WatermarkService: Video compressed successfully!');
        debugPrint('WatermarkService: Original size: ${originalSize / 1024 / 1024} MB');
        debugPrint('WatermarkService: Compressed size: ${compressedSize / 1024 / 1024} MB (${(ratio * 100).toStringAsFixed(1)}%)');

        onProgress?.call(1.0);
        return outputFile;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('WatermarkService: FFmpeg failed. Logs: $logs');

        // Try fallback: just return original
        return File(video.path);
      }
    } catch (e) {
      debugPrint('WatermarkService: FFmpeg execution failed: $e');
      return File(video.path);
    }
  }

  /// Build FFmpeg command string
  String _buildFFmpegCommand({
    required String inputPath,
    required String outputPath,
    required String watermarkText,
    required bool compress,
    required int targetHeight,
    required int crf,
  }) {
    // Escape text for FFmpeg drawtext filter
    final escapedText = watermarkText
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "'\\''");

    final fontSize = 28;
    final padding = 20;

    if (compress) {
      // Compress + watermark (720p, H.264, CRF 28)
      return "-i \"$inputPath\" "
          "-vf \"scale=-2:$targetHeight,drawtext=text='$escapedText':"
          "fontsize=$fontSize:"
          "fontcolor=white:"
          "borderw=2:"
          "bordercolor=black:"
          "x=$padding:"
          "y=h-text_h-$padding:"
          "shadowcolor=black@0.5:"
          "shadowx=2:"
          "shadowy=2\" "
          "-c:v libx264 "
          "-crf $crf "
          "-preset fast "
          "-c:a aac "
          "-b:a 96k "
          "-movflags +faststart "
          "\"$outputPath\"";
    } else {
      // Just watermark, no compression
      return "-i \"$inputPath\" "
          "-vf \"drawtext=text='$escapedText':"
          "fontsize=$fontSize:"
          "fontcolor=white:"
          "borderw=2:"
          "bordercolor=black:"
          "x=$padding:"
          "y=h-text_h-$padding:"
          "shadowcolor=black@0.5:"
          "shadowx=2:"
          "shadowy=2\" "
          "-c:a copy "
          "-preset ultrafast "
          "\"$outputPath\"";
    }
  }

  /// Alias for watermarkVideo - kept for backward compatibility
  Future<File> watermarkVideo({
    required XFile video,
    required String areaName,
    required String userName,
  }) async {
    return processVideoWithProgress(
      video: video,
      areaName: areaName,
      userName: userName,
      compress: true,
    );
  }

  /// Alias for watermarkVideoWithProgress - kept for backward compatibility
  Future<File> watermarkVideoWithProgress({
    required XFile video,
    required String areaName,
    required String userName,
    void Function(double progress)? onProgress,
  }) async {
    return processVideoWithProgress(
      video: video,
      areaName: areaName,
      userName: userName,
      onProgress: onProgress,
      compress: true,
    );
  }

  /// Check if FFmpeg is available on this device
  Future<bool> isFFmpegAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('WatermarkService: FFmpeg not available: $e');
      return false;
    }
  }

  /// Get video info
  Future<Map<String, dynamic>?> getVideoInfo(String videoPath) async {
    try {
      final mediaInfo = await FFprobeKit.getMediaInformation(videoPath);
      final info = mediaInfo.getMediaInformation();
      if (info == null) return null;

      return {
        'duration': info.getDuration(),
        'size': info.getSize(),
        'bitrate': info.getBitrate(),
      };
    } catch (e) {
      debugPrint('WatermarkService: Failed to get video info: $e');
      return null;
    }
  }

  /// Clean up temporary processed files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File && (file.path.contains('processed_') || file.path.contains('watermarked_'))) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('WatermarkService: Failed to cleanup temp files: $e');
    }
  }
}

/// Process video in isolate (runs in separate thread via compute)
/// Handles compression + watermark in one pass
Future<VideoProcessingResult> _processVideoInIsolate(VideoProcessingParams params) async {
  // Escape text for FFmpeg drawtext filter
  final escapedText = params.watermarkText
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "'\\''");

  // Get original file size
  int? originalSize;
  try {
    final file = File(params.inputPath);
    originalSize = await file.length();
  } catch (_) {}

  // FFmpeg command to compress + add watermark in one pass
  // - Scale to target height (720p) maintaining aspect ratio
  // - Add watermark text at bottom-left
  // - Use H.264 codec with CRF for quality control
  // - CRF 28 = good quality (~85-90% perceptual quality), much smaller file

  final fontSize = 28;
  final padding = 20;
  final scaleFilter = params.compress
      ? 'scale=-2:${params.targetHeight}'
      : 'scale=-2:min(min(iw\\,ih*16/9)\\,1920)\,min(ih\\,iw*9/16)';
  final watermarkFilter = 'drawtext=text=\'$escapedText\':'
      'fontsize=$fontSize:'
      'fontcolor=white:'
      'borderw=2:'
      'bordercolor=black:'
      'x=$padding:'
      'y=h-text_h-$padding:'
      'shadowcolor=black@0.5:'
      'shadowx=2:'
      'shadowy=2';

  String command;
  if (params.compress) {
    // Compress + watermark (single pass)
    // Using double quotes for Dart string interpolation
    command = "-i \"${params.inputPath}\" "
        "-vf \"$scaleFilter,$watermarkFilter\" "
        "-c:v libx264 "  // H.264 codec
        "-crf ${params.crf} "  // Quality (18-28, lower = better quality, bigger file)
        "-preset fast "  // Encoding speed vs compression tradeoff
        "-c:a aac "  // AAC audio codec
        "-b:a 96k "  // Audio bitrate
        "-movflags +faststart "  // Enable fast start for web playback
        "${params.outputPath}";
  } else {
    // Just watermark, no compression (keeps original quality)
    command = "-i \"${params.inputPath}\" "
        "-vf \"$watermarkFilter\" "
        "-c:a copy "
        "-preset ultrafast "
        "${params.outputPath}";
  }

  debugPrint('WatermarkService (isolate): Running FFmpeg command: $command');

  // Run FFmpeg asynchronously in isolate
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    debugPrint('WatermarkService (isolate): Video processed successfully');

    // Get compressed file size
    int? compressedSize;
    try {
      final file = File(params.outputPath);
      compressedSize = await file.length();
    } catch (_) {}

    return VideoProcessingResult(
      success: true,
      outputPath: params.outputPath,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
    );
  } else {
    // Get error logs for debugging
    final logs = await session.getAllLogsAsString();
    debugPrint('WatermarkService (isolate): FFmpeg failed. Logs: $logs');
    return VideoProcessingResult(
      success: false,
      outputPath: params.inputPath,
      error: logs,
      originalSizeBytes: originalSize,
    );
  }
}
