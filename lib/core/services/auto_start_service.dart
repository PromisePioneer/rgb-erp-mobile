import 'dart:io';
import 'package:flutter/services.dart';

/// Model untuk brand-specific auto-start settings
class AutoStartBrandConfig {
  final String brand;
  final String displayName;
  final String description;
  final List<String> steps;
  final String? settingsPackage;
  final String? intentAction;
  final String? intentData;

  const AutoStartBrandConfig({
    required this.brand,
    required this.displayName,
    required this.description,
    required this.steps,
    this.settingsPackage,
    this.intentAction,
    this.intentData,
  });
}

/// Brand configurations
class AutoStartBrandConfigs {
  static const Map<String, AutoStartBrandConfig> brands = {
    'xiaomi': AutoStartBrandConfig(
      brand: 'xiaomi',
      displayName: 'Xiaomi / Redmi / POCO',
      description: 'Di HP Xiaomi, Anda perlu mengaktifkan Izinkan Otomatis secara manual',
      steps: [
        'Buka Settings (Pengaturan)',
        'Cari "Apps" atau "Aplikasi"',
        'Pilih "Manage apps" atau "Kelola aplikasi"',
        'Cari dan pilih "RGB 86"',
        'Tekan toggle "Autostart" atau "Izinkan Otomatis"',
        'Pastikan toggle dalam posisi ON (Hijau)',
      ],
      settingsPackage: 'com.miui.securitycenter',
    ),
    'oppo': AutoStartBrandConfig(
      brand: 'oppo',
      displayName: 'OPPO / Realme / OnePlus',
      description: 'Di HP OPPO, Anda perlu mengizinkan RGB 86 berjalan di background',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "App launch" atau "Luncur aplikasi"',
        'Cari dan pilih "RGB 86"',
        'Pastikan semua options dalam posisi ON',
        'Atur ke "Manage manually" dan aktifkan semua',
      ],
      settingsPackage: 'com.coloros.safecenter',
    ),
    'vivo': AutoStartBrandConfig(
      brand: 'vivo',
      displayName: 'Vivo / iQOO',
      description: 'Di HP Vivo, Anda perlu menonaktifkan optimasi battery untuk RGB 86',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "Background power consumption"',
        'Pilih "RGB 86" dari daftar',
        'Pilih "Allow background running" atau "Izinkan berjalan di background"',
      ],
      settingsPackage: 'com.vivo.abe',
    ),
    'huawei': AutoStartBrandConfig(
      brand: 'huawei',
      displayName: 'Huawei / Honor',
      description: 'Di HP Huawei, Anda perlu mengizinkan RGB 86 berjalan otomatis',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "App launch" atau "Peluncur aplikasi"',
        'Cari dan pilih "RGB 86"',
        'Matikan toggle "Manage automatically"',
        'Aktifkan semua options secara manual',
      ],
      settingsPackage: 'com.huawei.systemmanager',
    ),
    'samsung': AutoStartBrandConfig(
      brand: 'samsung',
      displayName: 'Samsung',
      description: 'Di HP Samsung, Anda perlu memastikan RGB 86 tidak dioptimalkan',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Apps" atau "Aplikasi"',
        'Cari dan pilih "RGB 86"',
        'Pilih "Battery" atau "Baterai"',
        'Pilih "Unrestricted" atau "Tidak dibatasi"',
        'Aktifkan "Allow background activity"',
      ],
      settingsPackage: 'com.samsung.android.lool',
    ),
    'asus': AutoStartBrandConfig(
      brand: 'asus',
      displayName: 'ASUS',
      description: 'Di HP ASUS, Anda perlu mengaktifkan auto-start untuk RGB 86',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Power Management" atau "Pengelolaan Daya"',
        'Cari "Auto-start manager" atau "Manajer Mulai Otomatis"',
        'Temukan dan aktifkan "RGB 86"',
      ],
      settingsPackage: 'com.asus.mobilemanager',
    ),
    'lenovo': AutoStartBrandConfig(
      brand: 'lenovo',
      displayName: 'Lenovo / Motorola',
      description: 'Di HP Lenovo/Motorola, Anda perlu menonaktifkan battery optimization',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "Background restriction" atau "Pembatasan background"',
        'Pilih "RGB 86"',
        'Pilih "Don\'t optimize" atau "Jangan optimalkan"',
      ],
      settingsPackage: 'com.motorola.motocare',
    ),
    'realme': AutoStartBrandConfig(
      brand: 'realme',
      displayName: 'Realme',
      description: 'Di HP Realme, Anda perlu mengizinkan RGB 86 berjalan di background',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "Power consumption optimizer" atau "Pengoptimal konsumsi daya"',
        'Pilih "App manager" atau "Manajer aplikasi"',
        'Cari "RGB 86" dan aktifkan semua permissions',
      ],
      settingsPackage: 'com.coloros.safecenter',
    ),
    'infinix': AutoStartBrandConfig(
      brand: 'infinix',
      displayName: 'Infinix / Tecno / Itel',
      description: 'Di HP Infinix, Anda perlu mengaktifkan auto-start untuk RGB 86',
      steps: [
        'Buka Settings (Pengaturan)',
        'Cari "Apps" atau "Aplikasi"',
        'Pilih "Permissions" atau "Izin"',
        'Cari "Auto-start" atau "Mulai otomatis"',
        'Aktifkan toggle untuk "RGB 86"',
      ],
      settingsPackage: 'com.transsion.phonemanager',
    ),
    'sony': AutoStartBrandConfig(
      brand: 'sony',
      displayName: 'Sony',
      description: 'Di HP Sony, Anda perlu menonaktifkan STAMINA mode untuk RGB 86',
      steps: [
        'Buka Settings (Pengaturan)',
        'Pilih "Battery" atau "Baterai"',
        'Cari "STAMINA mode" atau "Mode STAMINA"',
        'Pilih "App standby" atau "Siaga aplikasi"',
        'Cari "RGB 86" dan nonaktifkan restrictions',
      ],
      settingsPackage: 'com.sonymobile.cta',
    ),
  };

  /// Get config by brand name (case insensitive)
  static AutoStartBrandConfig? getConfig(String brand) {
    final lowerBrand = brand.toLowerCase();
    for (final entry in brands.entries) {
      if (lowerBrand.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Get all supported brands
  static List<AutoStartBrandConfig> get allBrands => brands.values.toList();
}

/// Service untuk detect device brand dan manage auto-start
class AutoStartService {
  static String? _cachedBrand;

  /// Get current device brand
  static String getDeviceBrand() {
    if (_cachedBrand != null) return _cachedBrand!;

    if (!Platform.isAndroid) {
      _cachedBrand = 'unknown';
      return _cachedBrand!;
    }

    try {
      // Get manufacturer from Android
      _cachedBrand = _getAndroidBrand();
      return _cachedBrand!;
    } catch (e) {
      _cachedBrand = 'unknown';
      return _cachedBrand!;
    }
  }

  static String _getAndroidBrand() {
    try {
      const channel = MethodChannel('flutter/platform');
      final result = channel.invokeMethod<Map>('getAndroidInfo');

      // If we can't get it, try to get from device
      // Common device identifiers
      final manufacturer = androidDeviceInfo?.manufacturer ?? '';
      final brand = androidDeviceInfo?.brand ?? '';
      final device = androidDeviceInfo?.device ?? '';

      if (manufacturer.isNotEmpty) return manufacturer;
      if (brand.isNotEmpty) return brand;
      if (device.isNotEmpty) return device;

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  static AndroidDeviceInfo? androidDeviceInfo;

  /// Try to open auto-start settings directly
  static Future<bool> openAutoStartSettings() async {
    final brand = getDeviceBrand();
    final config = AutoStartBrandConfigs.getConfig(brand);

    if (config?.settingsPackage != null) {
      try {
        // Try to open manufacturer-specific settings
        final result = await _tryOpenManufacturerSettings(brand);
        if (result) return true;
      } catch (e) {
        // Continue to fallback
      }
    }

    // Fallback to app settings
    return await openAppSettings();
  }

  static Future<bool> _tryOpenManufacturerSettings(String brand) async {
    final brandLower = brand.toLowerCase();

    // Xiaomi / MIUI
    if (brandLower.contains('xiaomi') || brandLower.contains('redmi') || brandLower.contains('poco')) {
      return await _openMiuiAutoStart();
    }

    // OPPO / ColorOS
    if (brandLower.contains('oppo') || brandLower.contains('realme')) {
      return await _openColorOSAutoStart();
    }

    // Vivo / Funtouch
    if (brandLower.contains('vivo')) {
      return await _openVivoAutoStart();
    }

    // Huawei / EMUI
    if (brandLower.contains('huawei') || brandLower.contains('honor')) {
      return await _openHuaweiAutoStart();
    }

    // Samsung
    if (brandLower.contains('samsung')) {
      return await _openSamsungAutoStart();
    }

    return false;
  }

  static Future<bool> _openMiuiAutoStart() async {
    try {
      const package = 'com.miui.securitycenter';
      const activity = 'com.miui.permcenter.autostart.AutoStartManagementActivity';

      await const MethodChannel('plugins.flutter.io/path_provider')
          .invokeMethod('openApp', {
        'package': package,
        'activity': activity,
      });
      return true;
    } catch (e) {
      // Fallback to generic
      try {
        await openAppSettings();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> _openColorOSAutoStart() async {
    try {
      const package = 'com.coloros.safecenter';
      const activity = 'com.coloros.safecenter.permission.startup.StartupAppListActivity';

      await const MethodChannel('plugins.flutter.io/path_provider')
          .invokeMethod('openApp', {
        'package': package,
        'activity': activity,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _openVivoAutoStart() async {
    try {
      const package = 'com.vivo.abe';
      const activity = 'com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity';

      await const MethodChannel('plugins.flutter.io/path_provider')
          .invokeMethod('openApp', {
        'package': package,
        'activity': activity,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _openHuaweiAutoStart() async {
    try {
      const package = 'com.huawei.systemmanager';
      const activity = 'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity';

      await const MethodChannel('plugins.flutter.io/path_provider')
          .invokeMethod('openApp', {
        'package': package,
        'activity': activity,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _openSamsungAutoStart() async {
    try {
      const package = 'com.samsung.android.lool';
      const activity = 'com.samsung.android.sm.ui.battery.BatteryActivity';

      await const MethodChannel('plugins.flutter.io/path_provider')
          .invokeMethod('openApp', {
        'package': package,
        'activity': activity,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings page
  static Future<bool> openAppSettings() async {
    try {
      await const MethodChannel('flutter/platform')
          .invokeMethod('openAppSettings');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if auto-start is likely enabled
  /// This is a heuristic check - if battery optimization is ignored, auto-start is likely working
  static Future<bool> isAutoStartLikelyEnabled() async {
    // This is a simplified check
    // In production, you might want to use shared_preferences to remember
    // if the user has set up auto-start
    return false; // Always return false to show the guide
  }
}

/// Android device info holder
class AndroidDeviceInfo {
  final String? manufacturer;
  final String? brand;
  final String? device;
  final String? model;

  AndroidDeviceInfo({
    this.manufacturer,
    this.brand,
    this.device,
    this.model,
  });
}
