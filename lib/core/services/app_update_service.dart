import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateService {
  // API URL - sesuaikan dengan backend kamu
  static const String _versionUrl = 'https://api-admin-erp.rgb86groups.com/api/app/version';

  // Local version dari pubspec.yaml (hardcoded untuk perbandingan)
  // Bisa juga diambil dari PackageInfo
  static const String _currentVersion = '1.0.0';
  static const int _currentVersionCode = 10000;

  /// Check if update is available
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_versionUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final updateInfo = AppUpdateInfo.fromJson(data['data']);

          // Compare version
          if (_compareVersions(updateInfo.version, _currentVersion) > 0) {
            return updateInfo;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return null;
    }
  }

  /// Download and install APK
  static Future<bool> downloadAndInstall(AppUpdateInfo updateInfo) async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manage external storage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            debugPrint('Storage permission denied');
            return false;
          }
        }
      }

      // Download APK
      final file = await _downloadFile(updateInfo.apkUrl, updateInfo.filename);

      if (file != null) {
        // Open installer
        await OpenFilex.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return false;
    }
  }

  static Future<File?> _downloadFile(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }

      return null;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Compare version strings (e.g., "1.0.1" vs "1.0.2")
  /// Returns: positive if v1 > v2, negative if v1 < v2, 0 if equal
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }
}

class AppUpdateInfo {
  final String version;
  final int versionCode;
  final String apkUrl;
  final String filename;
  final int fileSize;
  final bool forceUpdate;
  final String? releaseNotes;
  final int? build;
  final String? branch;
  final DateTime? releasedAt;

  AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.apkUrl,
    required this.filename,
    required this.fileSize,
    required this.forceUpdate,
    this.releaseNotes,
    this.build,
    this.branch,
    this.releasedAt,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] ?? '0.0.0',
      versionCode: json['version_code'] ?? 0,
      apkUrl: json['apk_url'] ?? '',
      filename: json['filename'] ?? 'app.apk',
      fileSize: json['file_size'] ?? 0,
      forceUpdate: json['force_update'] ?? false,
      releaseNotes: json['release_notes'],
      build: json['build'],
      branch: json['branch'],
      releasedAt: json['released_at'] != null
          ? DateTime.tryParse(json['released_at'])
          : null,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
