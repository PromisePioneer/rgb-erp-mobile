import '../environment/environment_config.dart';

/// App-wide constants for RGB ERP Mobile
class AppConstants {
  AppConstants._();

  // API Configuration - reads from .env file
  static String get apiBaseUrl => EnvironmentConfig.apiBaseUrl;
  static Duration get apiTimeout =>
      Duration(seconds: EnvironmentConfig.apiTimeout);
  static const Duration shortTimeout = Duration(seconds: 5);

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyAuthUser = 'auth_user';
  static const String keySavedNik = 'saved_nik';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyBiometricCode = 'biometric_code';
  static const String keyLocale = 'locale';

  // Client Auth Storage Keys
  static const String keyClientAuthToken = 'client_auth_token';
  static const String keyClientAuthUser = 'client_auth_user';

  // Attendance Storage Keys
  static const String keyAttendanceStatus = 'attendance_status';
  static const String keyAttendanceRecords = 'attendance_records';

  // Face Enrollment Storage Keys
  static const String keyFaceEnrollmentStatus = 'face_enrollment_status';
  static const String keyFaceEnrollmentId = 'face_enrollment_id';

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Panic Button
  static const Duration panicLongPressDuration = Duration(milliseconds: 500);
  static const Duration panicCountdownDuration = Duration(seconds: 3);

  // Location
  static const int locationAccuracy = 10; // meters
  static const Duration locationTimeout = Duration(seconds: 10);

  // Patrol
  static const int patrolPointsCount = 8;

  // Notification Storage Keys
  static const String keyFcmToken = 'fcm_token';
  static const String keyDeviceId = 'device_id';

  // Onboarding
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  // Notification IDs
  static const int patrolAlarmNotificationId = 1001;
  static const int shiftReminderNotificationId = 1002;

  // Validation
  static const int minPasswordLength = 6;
  static const int minNikLength = 4;

  // Face Recognition
  static const double livenessScoreThreshold = 0.8;
  static const int faceCaptureRetryCount = 3;
  static const Duration faceCaptureDelay = Duration(milliseconds: 500);
}
