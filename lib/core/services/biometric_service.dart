import 'package:local_auth/local_auth.dart';

/// Biometric authentication result
class BiometricResult {
  final bool success;
  final String? error;

  const BiometricResult({
    required this.success,
    this.error,
  });
}

/// Biometric availability info
class BiometricInfo {
  final bool available;
  final String? biometryType;
  final List<BiometricType> availableTypes;

  const BiometricInfo({
    required this.available,
    this.biometryType,
    this.availableTypes = const [],
  });
}

/// Service for biometric authentication using local_auth
class BiometricService {
  final LocalAuthentication _localAuth;

  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Check if biometric authentication is available on device
  Future<BiometricInfo> checkAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return const BiometricInfo(available: false);
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      String? biometryType;
      if (availableBiometrics.contains(BiometricType.face)) {
        biometryType = 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometryType = 'Touch ID';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        biometryType = 'Biometric';
      }

      return BiometricInfo(
        available: true,
        biometryType: biometryType,
        availableTypes: availableBiometrics,
      );
    } catch (e) {
      return const BiometricInfo(available: false);
    }
  }

  /// Authenticate user with biometrics
  Future<BiometricResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );

      return BiometricResult(success: didAuthenticate);
    } catch (e) {
      return BiometricResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  /// Get display name for biometry type
  static String getBiometryDisplayName(String? biometryType) {
    switch (biometryType) {
      case 'Face ID':
        return 'Face ID';
      case 'Touch ID':
        return 'Touch ID';
      case 'Fingerprint':
        return 'Fingerprint';
      default:
        return 'Biometric';
    }
  }
}
