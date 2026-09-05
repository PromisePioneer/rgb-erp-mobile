import 'dart:convert';
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
  final String userType; // 'employee' or 'client'

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
    this.userType = 'employee',
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
    String? userType,
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
      userType: userType ?? this.userType,
    );
  }

  bool get isClient => userType == 'client';
  bool get isEmployee => userType == 'employee';
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

      // Check for client auth first (client takes priority if both exist)
      final storage = _repository.storage;
      final hasClientSession = await storage.hasValidClientSession();

      if (hasClientSession) {
        // Restore client session
        final clientUserJson = await storage.clientAuthUser;
        final clientToken = await storage.clientAuthToken;

        if (clientUserJson != null) {
          final clientData = jsonDecode(clientUserJson) as Map<String, dynamic>;
          final user = User.fromJson({
            'id': clientData['id'],
            'code': null,
            'name': clientData['name'],
            'email': clientData['email'],
            'username': null,
            'nik': null,
            'department': null,
            'role': 'Client',
            'photo': null,
            'division': null,
            'siteId': null,
            'siteName': null,
            'areaId': null,
            'areaName': null,
            'privileges': <String>[],
            'hasFaceEnrollment': false,
          });

          _state = AuthState(
            user: user,
            token: clientToken,
            isAuthenticated: true,
            isLoading: false,
            biometricEnabled: biometricEnabled,
            biometricAvailable: biometricInfo.available,
            savedNik: null, // Clients don't use saved NIK
            biometryType: biometricInfo.biometryType,
            userType: 'client',
          );
          notifyListeners();
          return;
        }
      }

      // Try to restore employee user from storage
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
          userType: 'employee',
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
  Future<User?> login({
    required String code,
    required String password,
    String? fcmToken,
  }) async {
    
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final credentials = LoginCredentials(
        code: code,
        password: password,
        fcmToken: fcmToken,
      );

      
      final response = await _repository.login(credentials);
      

      _state = _state.copyWith(
        user: response.user,
        token: response.accessToken,
        isAuthenticated: true,
        isLoading: false,
        savedNik: code,
        userType: response.userType,
      );
      
      notifyListeners();

      // Register FCM token after successful login (only for employees)
      if (response.isEmployee) {
        await _registerFcmToken();
      }

      return response.user!;
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

      return response.user!;
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
      
    } catch (e) {
      
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
      
    } catch (e) {
      
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
          role: user.role,
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
