import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/login_credentials.dart';
import '../../data/repositories/auth_repository.dart';

// ====================
// Repository Factory
// ====================

AuthRepository createAuthRepository(Dio dio) {
  return AuthRepository(
    api: AuthApi(dio),
    storage: StorageService(),
    biometric: BiometricService(),
  );
}

// ====================
// State
// ====================

/// Auth state
class AuthState extends ChangeNotifier {
  final User? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final String? savedNik;
  final String? biometryType;

  AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.savedNik,
    this.biometryType,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? biometricEnabled,
    bool? biometricAvailable,
    String? savedNik,
    String? biometryType,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      savedNik: savedNik ?? this.savedNik,
      biometryType: biometryType ?? this.biometryType,
    );
  }
}

// ====================
// Notifier
// ====================

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super();

  AuthState _state = AuthState();
  AuthState get state => _state;

  /// Initialize auth state from storage
  Future<void> hydrate() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Check biometric availability
      final biometricInfo = await _repository.checkBiometricAvailability();

      // Get saved NIK
      final savedNik = await _repository.getSavedNik();

      // Check if biometric is enabled
      final biometricEnabled = await _repository.isBiometricEnabled();

      // Try to restore user from storage
      final user = await _repository.hydrate();

      if (user != null) {
        _state = AuthState(
          user: user,
          token: await _repository.getToken(),
          isAuthenticated: true,
          isLoading: false,
          biometricEnabled: biometricEnabled,
          biometricAvailable: biometricInfo.available,
          savedNik: savedNik,
          biometryType: biometricInfo.biometryType,
        );

        // Register FCM token after restoring session
        _registerFcmToken();
      } else {
        _state = AuthState(
          isLoading: false,
          biometricAvailable: biometricInfo.available,
          savedNik: savedNik,
          biometryType: biometricInfo.biometryType,
        );
      }
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Login with NIK and password
  Future<User> login({
    required String code,
    required String password,
    String? fcmToken,
  }) async {
    print('AUTH_PROVIDER: Starting login for code: $code');
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final credentials = LoginCredentials(
        code: code,
        password: password,
        fcmToken: fcmToken,
      );

      print('AUTH_PROVIDER: Calling repository.login()');
      final response = await _repository.login(credentials);
      print('AUTH_PROVIDER: Repository login succeeded');

      _state = _state.copyWith(
        user: response.user,
        token: response.accessToken,
        isAuthenticated: true,
        isLoading: false,
        savedNik: code,
      );
      print('AUTH_PROVIDER: State updated, isAuthenticated=true');
      notifyListeners();

      // Register FCM token after successful login
      await _registerFcmToken();

      return response.user;
    } on ApiException catch (e) {
      print('AUTH_PROVIDER: ApiException - ${e.message}');
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      rethrow;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Login failed. Please try again.',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Login with biometric
  Future<User> loginWithBiometric() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final response = await _repository.loginWithBiometric();

      _state = _state.copyWith(
        user: response.user,
        token: response.accessToken,
        isAuthenticated: true,
        isLoading: false,
      );
      notifyListeners();

      // Register FCM token after successful biometric login
      await _registerFcmToken();

      return response.user;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      rethrow;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Biometric login failed. Please try again.',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Register FCM token with backend
  Future<void> _registerFcmToken() async {
    try {
      // Access the singleton notification service
      final notifService = globalNotificationService;
      await notifService.registerCurrentToken();
      print('AUTH_PROVIDER: FCM token registered');
    } catch (e) {
      print('AUTH_PROVIDER: Failed to register FCM token: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Unregister FCM token before logout
      await _unregisterFcmToken();

      await _repository.logout();

      _state = AuthState(
        savedNik: _state.savedNik,
        biometricAvailable: _state.biometricAvailable,
        biometricEnabled: _state.biometricEnabled,
        biometryType: _state.biometryType,
      );
    } catch (e) {
      _state = AuthState(
        savedNik: _state.savedNik,
        biometricAvailable: _state.biometricAvailable,
        biometricEnabled: _state.biometricEnabled,
        biometryType: _state.biometryType,
      );
    }
    notifyListeners();
  }

  /// Unregister FCM token
  Future<void> _unregisterFcmToken() async {
    try {
      final notifService = globalNotificationService;
      await notifService.unregisterToken();
      print('AUTH_PROVIDER: FCM token unregistered');
    } catch (e) {
      print('AUTH_PROVIDER: Failed to unregister FCM token: $e');
    }
  }

  /// Enable biometric
  Future<void> enableBiometric(String code) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await _repository.enableBiometric(code);

      _state = _state.copyWith(
        biometricEnabled: true,
        isLoading: false,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      rethrow;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to enable biometric.',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Disable biometric
  Future<void> disableBiometric() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await _repository.disableBiometric();

      _state = _state.copyWith(
        biometricEnabled: false,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to disable biometric.',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Change password
  /// Returns true if successful
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal mengubah password',
      );
      notifyListeners();
      return false;
    }
  }

  /// Update hasFaceEnrollment flag (call after successful face enrollment)
  void setFaceEnrollment(bool enrolled) {
    if (_state.user != null) {
      final user = _state.user!;
      _state = _state.copyWith(
        user: User(
          id: user.id,
          code: user.code,
          name: user.name,
          email: user.email,
          username: user.username,
          nik: user.nik,
          department: user.department,
          position: user.position,
          photo: user.photo,
          division: user.division,
          siteId: user.siteId,
          siteName: user.siteName,
          areaId: user.areaId,
          areaName: user.areaName,
          privileges: user.privileges,
          hasFaceEnrollment: enrolled,
        ),
      );
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }
}

// ====================
// Provider
// ====================

// Provider is set up in main.dart with MultiProvider
