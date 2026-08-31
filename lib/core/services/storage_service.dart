import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure storage service using flutter_secure_storage
/// Mimics AsyncStorage behavior from React Native
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  // Auth Token
  Future<String?> get authToken async {
    return _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<void> removeAuthToken() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
  }

  // Auth User
  Future<String?> get authUser async {
    return _storage.read(key: AppConstants.keyAuthUser);
  }

  Future<void> setAuthUser(String userJson) async {
    await _storage.write(key: AppConstants.keyAuthUser, value: userJson);
  }

  Future<void> removeAuthUser() async {
    await _storage.delete(key: AppConstants.keyAuthUser);
  }

  // Saved NIK (persists after logout for convenience)
  Future<String?> get savedNik async {
    return _storage.read(key: AppConstants.keySavedNik);
  }

  Future<void> setSavedNik(String nik) async {
    await _storage.write(key: AppConstants.keySavedNik, value: nik);
  }

  Future<void> removeSavedNik() async {
    await _storage.delete(key: AppConstants.keySavedNik);
  }

  // Biometric Settings
  Future<bool> get biometricEnabled async {
    final value = await _storage.read(key: AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<void> removeBiometricEnabled() async {
    await _storage.delete(key: AppConstants.keyBiometricEnabled);
  }

  // Biometric Code (encrypted NIK for biometric login)
  Future<String?> get biometricCode async {
    return _storage.read(key: AppConstants.keyBiometricCode);
  }

  Future<void> setBiometricCode(String code) async {
    await _storage.write(key: AppConstants.keyBiometricCode, value: code);
  }

  Future<void> removeBiometricCode() async {
    await _storage.delete(key: AppConstants.keyBiometricCode);
  }

  // Locale
  Future<String?> get locale async {
    return _storage.read(key: AppConstants.keyLocale);
  }

  Future<void> setLocale(String locale) async {
    await _storage.write(key: AppConstants.keyLocale, value: locale);
  }

  // FCM Token
  Future<String?> get fcmToken async {
    return _storage.read(key: AppConstants.keyFcmToken);
  }

  Future<void> setFcmToken(String token) async {
    await _storage.write(key: AppConstants.keyFcmToken, value: token);
  }

  Future<void> removeFcmToken() async {
    await _storage.delete(key: AppConstants.keyFcmToken);
  }

  // Device ID
  Future<String?> get deviceId async {
    return _storage.read(key: AppConstants.keyDeviceId);
  }

  Future<void> setDeviceId(String id) async {
    await _storage.write(key: AppConstants.keyDeviceId, value: id);
  }

  // Clear Auth Data (keep biometric settings for re-login)
  Future<void> clearAuthData() async {
    await removeAuthToken();
    await removeAuthUser();
    // Note: biometricEnabled and biometricCode are intentionally NOT cleared
    // so user can login with biometric after logout
  }

  // Onboarding
  Future<bool> get hasSeenOnboarding async {
    final value = await _storage.read(key: AppConstants.keyHasSeenOnboarding);
    return value == 'true';
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await _storage.write(
      key: AppConstants.keyHasSeenOnboarding,
      value: value.toString(),
    );
  }

  // Clear All Data (full logout including savedNik)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if has valid auth session
  Future<bool> hasValidSession() async {
    final token = await authToken;
    final user = await authUser;
    return token != null && token.isNotEmpty && user != null && user.isNotEmpty;
  }

  // ====================
  // Client Auth Storage
  // ====================

  // Client Auth Token
  Future<String?> get clientAuthToken async {
    return _storage.read(key: AppConstants.keyClientAuthToken);
  }

  Future<void> setClientAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyClientAuthToken, value: token);
  }

  Future<void> removeClientAuthToken() async {
    await _storage.delete(key: AppConstants.keyClientAuthToken);
  }

  // Client Auth User
  Future<String?> get clientAuthUser async {
    return _storage.read(key: AppConstants.keyClientAuthUser);
  }

  Future<void> setClientAuthUser(String userJson) async {
    await _storage.write(key: AppConstants.keyClientAuthUser, value: userJson);
  }

  Future<void> removeClientAuthUser() async {
    await _storage.delete(key: AppConstants.keyClientAuthUser);
  }

  // Clear Client Auth Data
  Future<void> clearClientAuthData() async {
    await removeClientAuthToken();
    await removeClientAuthUser();
  }

  // Check if has valid client session
  Future<bool> hasValidClientSession() async {
    final token = await clientAuthToken;
    final user = await clientAuthUser;
    return token != null && token.isNotEmpty && user != null && user.isNotEmpty;
  }
}
