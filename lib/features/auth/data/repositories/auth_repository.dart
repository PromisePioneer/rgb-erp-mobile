import 'dart:convert';
import '../../../../core/core.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/entities/login_response.dart';

/// Repository for authentication operations
class AuthRepository {
  final AuthApi _api;
  final StorageService _storage;
  final BiometricService _biometric;

  AuthRepository({
    required this._api,
    required this._storage,
    required this._biometric,
  });

  /// Expose storage for external access (e.g., client auth check)
  StorageService get storage => _storage;

  /// Login with credentials
  Future<LoginResponse> login(LoginCredentials credentials) async {
    final response = await _api.login(
      code: credentials.code,
      password: credentials.password,
      fcmToken: credentials.fcmToken,
    );

    final loginResponse = LoginResponse.fromJson(response);

    // Persist auth data based on user type
    if (loginResponse.user != null) {
      await _persistAuth(
        user: loginResponse.user!,
        token: loginResponse.accessToken,
        code: credentials.code,
        userType: loginResponse.userType,
      );
    }

    return loginResponse;
  }

  /// Login with biometric (uses stored credentials + device biometric verification)
  Future<LoginResponse> loginWithBiometric() async {
    // Verify biometric with device first
    final biometricResult = await _biometric.authenticate(
      reason: 'Authenticate to login',
    );

    if (!biometricResult.success) {
      throw ApiException(
        message: biometricResult.error ?? 'Biometric authentication failed',
      );
    }

    // Get saved NIK for biometric login
    final savedNik = await _storage.savedNik;
    if (savedNik == null) {
      throw ApiException(
        message: 'No saved credentials. Please login with password first.',
      );
    }

    // Get biometric code for server verification
    final biometricCode = await _storage.biometricCode;

    // Call backend to get new token
    final response = await _api.biometricLogin(
      code: savedNik,
      biometricToken: biometricCode,
    );

    final loginResponse = LoginResponse.fromJson(response);

    // Persist new auth data (biometric only for employees)
    if (loginResponse.user != null) {
      await _persistAuth(
        user: loginResponse.user!,
        token: loginResponse.accessToken,
        code: savedNik,
        userType: 'employee',
      );
    }

    return loginResponse;
  }

  /// Logout - clears local auth data
  Future<void> logout() async {
    try {
      // Try to notify server (but ignore errors)
      await _api.logout();
    } finally {
      // Always clear local data (both employee and client)
      await _storage.clearAuthData();
      await _storage.clearClientAuthData();
    }
  }

  /// Enable biometric login
  Future<void> enableBiometric(String code) async {
    // Verify biometric first
    final biometricResult = await _biometric.authenticate(
      reason: 'Authenticate to enable biometric login',
    );

    if (!biometricResult.success) {
      throw ApiException(
        message: biometricResult.error ?? 'Biometric verification failed',
      );
    }

    // Store biometric code
    await _storage.setBiometricCode(code);
    await _storage.setBiometricEnabled(true);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _storage.removeBiometricCode();
    await _storage.setBiometricEnabled(false);
  }

  /// Check biometric availability
  Future<BiometricInfo> checkBiometricAvailability() async {
    return await _biometric.checkAvailability();
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    return await _storage.biometricEnabled;
  }

  /// Get saved NIK (for auto-fill)
  Future<String?> getSavedNik() async {
    return await _storage.savedNik;
  }

  /// Hydrate auth state from storage (check if has valid session)
  Future<User?> hydrate() async {
    final hasSession = await _storage.hasValidSession();
    if (!hasSession) return null;

    final userJson = await _storage.authUser;
    if (userJson == null) return null;

    return User.fromJson(jsonDecode(userJson));
  }

  /// Get current token
  Future<String?> getToken() async {
    return await _storage.authToken;
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Persist auth data to secure storage
  Future<void> _persistAuth({
    required User user,
    required String token,
    required String code,
    String userType = 'employee',
  }) async {
    if (userType == 'client') {
      // Store as client auth
      await _storage.setClientAuthToken(token);
      await _storage.setClientAuthUser(jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'company_name': null,
      }));
    } else {
      // Store as employee auth
      await _storage.setAuthToken(token);
      await _storage.setAuthUser(jsonEncode(user.toJson()));
      await _storage.setSavedNik(code);
    }
  }
}
