/// API endpoint constants
/// Base URL: https://somethinghappen.net/api
class ApiEndpoints {
  ApiEndpoints._();

  // ====================
  // Auth Endpoints
  // ====================
  static const String login = '/login';
  static const String logout = '/logout';
  static const String biometricLogin = '/auth/biometric';
  static const String user = '/user';
  static const String fcmToken = '/fcm-token';
  static const String changePassword = '/change-password';

  // ====================
  // Attendance Endpoints
  // ====================
  static const String attendanceToday = '/attendance/today';
  static const String attendance = '/attendance';
  static const String attendanceFaceVerify = '/attendance/face-verify';
  static const String attendanceTodayStatus = '/attendance/today-status';

  static String attendanceStatus(String jobUuid) =>
      '/attendance/status/$jobUuid';

  // ====================
  // Face Enrollment Endpoints
  // ====================
  static const String faceEnrollmentStatus = '/face-enrollment/status';
  static const String faceEnrollment = '/face-enrollment';
  static const String faceValidate = '/face-enrollment/validate';
  static const String liveness = '/liveness';

  // ====================
  // Dashboard Endpoints
  // ====================
  static const String dashboard = '/dashboard';
  static const String announcements = '/announcements';
  static const String teamMembers = '/team-members';

  // ====================
  // Patrol Endpoints
  // ====================
  static const String patrolScan = '/patrol/scan';
  static const String patrolTodayStatus = '/patrol/status';

  // ====================
  // Panic Alert Endpoints
  // ====================
  static const String panicAlert = '/panic-alert';
  static const String panicAlertStatus = '/panic-alert/status';

  // ====================
  // Report Endpoints
  // ====================
  static const String reports = '/reports';
  static const String dailyReports = '/reports/daily';

  // ====================
  // Notification Endpoints
  // ====================
  static const String notifications = '/notifications';
  static const String notificationRead = '/notifications/read';
  static const String deviceTokens = '/device-tokens';

  // ====================
  // Schedule Endpoints
  // ====================
  static const String schedule = '/schedule';

  // ====================
  // Payroll Endpoints
  // ====================
  static const String payroll = '/payroll';

  // ====================
  // Leave Endpoints
  // ====================
  static const String leave = '/leave';

  // ====================
  // Violation Report Endpoints
  // ====================
  static const String violationReportProjects = '/patrol-violation/projects';
  static const String violationReportEmployees = '/patrol-violation/employees';
  static const String violationReportSubmit = '/patrol-violation';
  static const String violationReportHistory = '/patrol-violation/history';
  static const String violationTypes = '/violation-types';
  static const String violationTypesList = '/violation-types/list';
}
