/// API endpoint constants
/// Base URL: https://api.testing-erp-ges.tech/api
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
  static const String patrolOtp = '/patrol/otp';

  // ====================
  // Panic Alert Endpoints
  // ====================
  static const String panicAlert = '/panic-alert';
  static const String panicAlertStatus = '/panic-alert/status';

  // ====================
  // Report Endpoints
  // ====================
  static const String reports = '/report';
  static const String reportByArea = '/report/by-area';

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
  static const String shiftRespond = '/shift/{id}/respond';
  static const String shiftPendingResponses = '/shift/pending-responses';

  // ====================
  // Backup Offer Endpoints
  // ====================
  static const String backupOffers = '/backup-offers';
  static String backupOfferAccept(String id) => '/backup-offers/$id/accept';
  static String backupOfferReject(String id) => '/backup-offers/$id/reject';

  // ====================
  // Coordinator Endpoints
  // ====================
  static const String coordinatorAreas = '/coordinator/backup/areas';
  static const String coordinatorEscalations = '/coordinator/backup/escalations';

  // ====================
  // Payroll Endpoints
  // ====================
  static const String payroll = '/payroll';

  // ====================
  // Leave Endpoints
  // ====================
  static const String leave = '/leave';

  // ====================
  // Purchase Request Endpoints
  // ====================
  static const String purchaseRequests = '/purchase-requests';
  static String purchaseRequest(int id) => '/purchase-requests/$id';
  static String purchaseRequestSubmit(int id) => '/purchase-requests/$id/submit';
  static const String purchaseRequestProducts = '/purchase-requests/products-select-options';

  // ====================
  // Violation Report Endpoints
  // ====================
  static const String violationReportProjects = '/patrol-violation/projects';
  static const String violationReportEmployees = '/patrol-violation/employees';
  static const String violationReportSubmit = '/patrol-violation';
  static const String violationReportHistory = '/patrol-violation/history';
  static const String violationTypes = '/violation-types';
  static const String violationTypesList = '/violation-types/list';

  // ====================
  // Daily Task Endpoints
  // ====================
  static const String dailyTaskToday = '/daily-task/today';
  static const String dailyTask = '/daily-task';
  static const String dailyTaskItems = '/daily-task/items';
  static const String dailyTaskPositions = '/daily-task/positions';
  static const String dailyTaskTools = '/daily-task/tools';
  static const String dailyTaskChemicals = '/daily-task/chemicals';
  static const String dailyTaskPpes = '/daily-task/ppes';
  static const String dailyTaskMachines = '/daily-task/machines';
  static const String dailyTaskHistory = '/daily-task/history';

  // ====================
  // Daily Task Assignment Endpoints (Supervisor)
  // ====================
  static const String dailyTaskAssignments = '/admin/daily-task-assignments';
  static const String dailyTaskAssignmentEmployees = '/admin/daily-task-assignments/employees';

  // ====================
  // Daily Task Mobile Assignment Endpoints
  // ====================
  static const String dailyTaskMobileAssign = '/daily-task/assign';
  static const String dailyTaskMobileAssignEmployees = '/daily-task/assign/employees';
  static const String dailyTaskMyAssignments = '/daily-task/assignments/my';
  static const String dailyTaskReviewCriteria = '/daily-task/review-criteria';

  // ====================
  // Product Areas (Stok per Area/Client) for Mobile
  // ====================
  static const String productAreasByArea = '/product-areas/area';

  // ====================
  // Unified Inventory (Warehouse + Area tracking)
  // ====================
  static const String inventoryByArea = '/inventory-items/by-area';
  static const String inventoryScan = '/inventory-items/scan';
  static const String inventoryMovements = '/inventory-items';
  static const String inventoryCondition = '/inventory-items/condition';
  static const String inventoryTransfer = '/inventory-items/transfer';

  // ====================
  // Client API Endpoints (Mobile App for Clients)
  // ====================
  static const String clientDashboard = '/client/dashboard';
  static const String clientEmployees = '/client/employees';
  static const String clientAreas = '/client/areas';
  static const String clientAttendanceToday = '/client/attendance/today';
  static const String clientAttendance = '/client/attendance';
  static const String clientDailyTasks = '/client/daily-tasks';
  static const String clientPatrolReports = '/client/patrol-reports';
  static const String clientFieldReports = '/client/field-reports';
  static const String clientProfile = '/client/profile';
  static const String clientChangePassword = '/client/password';
  static const String clientScheduleDates = '/client/schedules/dates';
  static const String clientScheduleEmployees = '/client/schedules/employees';
}
