import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App environment types
enum AppEnvironment {
  development,
  staging,
  production;

  String get displayName {
    switch (this) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}

/// Helper class for environment configuration
class EnvironmentConfig {
  EnvironmentConfig._();

  static AppEnvironment? _currentEnvironment;

  /// Initialize environment from .env file
  /// Call this in main() before runApp()
  static Future<void> init() async {
    // Determine which .env file to load based on environment
    final envName = dotenv.env['ENVIRONMENT'] ?? 'dev';

    switch (envName.toLowerCase()) {
      case 'production':
        _currentEnvironment = AppEnvironment.production;
        break;
      case 'staging':
        _currentEnvironment = AppEnvironment.staging;
        break;
      default:
        _currentEnvironment = AppEnvironment.development;
    }

    if (kDebugMode) {
      debugPrint('🌍 App Environment: ${_currentEnvironment!.displayName}');
      debugPrint('📡 API Base URL: $apiBaseUrl');
    }
  }

  /// Get current environment
  static AppEnvironment get currentEnvironment {
    if (_currentEnvironment == null) {
      // Default to development if not initialized
      return AppEnvironment.development;
    }
    return _currentEnvironment!;
  }

  /// Get API base URL from environment
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://api.dev-erp-ges.tech/api';
  }

  /// Get API timeout in seconds
  static int get apiTimeout {
    return int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
  }

  /// Check if current environment is debug mode
  static bool get isDebug {
    return kDebugMode;
  }

  /// Check if current environment is release mode
  static bool get isRelease {
    return kReleaseMode;
  }
}
