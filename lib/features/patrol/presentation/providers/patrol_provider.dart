import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:otp/otp.dart';
import '../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../data/repositories/patrol_repository.dart';

// ====================
// Repository Factory
// ====================

PatrolRepository createPatrolRepository(Dio dio) {
  return PatrolRepository(api: PatrolApi(dio));
}

// ====================
// State
// ====================

/// Patrol state
class PatrolState extends ChangeNotifier {
  final PatrolTodayStatus? todayStatus;
  final bool isLoading;
  final String? error;
  final bool isScanning;
  final PatrolScanResult? lastScanResult;
  final bool isCountingDown;
  final int countdownSeconds;
  final bool showAlarmAlert;
  final String? alarmMessage;

  // OTP state
  final PatrolOtpResponse? otpResponse;
  final bool isOtpExpired;

  PatrolState({
    this.todayStatus,
    this.isLoading = false,
    this.error,
    this.isScanning = false,
    this.lastScanResult,
    this.isCountingDown = false,
    this.countdownSeconds = 0,
    this.showAlarmAlert = false,
    this.alarmMessage,
    this.otpResponse,
    this.isOtpExpired = false,
  });

  bool get hasSchedule => todayStatus?.hasSchedule ?? false;
  int get nextExpectedSequence => todayStatus?.nextExpectedSequence ?? 1;
  int get totalCheckpoints => todayStatus?.totalCheckpoints ?? 0;
  bool get isRoundCompleted => lastScanResult?.isRoundCompleted ?? false;

  /// Get countdown text for the current round
  String? get roundCountdownText {
    final progress = todayStatus?.currentProgress;
    if (progress == null) return null;
    return progress.countdownText;
  }

  /// Check if current round is overdue
  bool get isRoundOverdue {
    return todayStatus?.currentProgress?.currentRoundIsOverdue ?? false;
  }

  /// Get minutes until next round (negative if overdue)
  int get minutesUntilDue {
    return todayStatus?.currentProgress?.minutesUntilDue ?? 0;
  }

  /// Get OTP countdown seconds
  int get otpCountdownSeconds {
    // TOTP changes every 30 seconds, calculate from current time
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = 30;
    return period - (now % period);
  }

  PatrolState copyWith({
    PatrolTodayStatus? todayStatus,
    bool? isLoading,
    String? error,
    bool? isScanning,
    PatrolScanResult? lastScanResult,
    bool? isCountingDown,
    int? countdownSeconds,
    bool? showAlarmAlert,
    String? alarmMessage,
    PatrolOtpResponse? otpResponse,
    bool? isOtpExpired,
    bool clearError = false,
    bool clearLastScanResult = false,
    bool clearTodayStatus = false,
    bool clearAlarm = false,
    bool clearOtp = false,
  }) {
    return PatrolState(
      todayStatus: clearTodayStatus ? null : (todayStatus ?? this.todayStatus),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isScanning: isScanning ?? this.isScanning,
      lastScanResult: clearLastScanResult ? null : (lastScanResult ?? this.lastScanResult),
      isCountingDown: isCountingDown ?? this.isCountingDown,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      showAlarmAlert: clearAlarm ? false : (showAlarmAlert ?? this.showAlarmAlert),
      alarmMessage: clearAlarm ? null : (alarmMessage ?? this.alarmMessage),
      otpResponse: clearOtp ? null : (otpResponse ?? this.otpResponse),
      isOtpExpired: isOtpExpired ?? this.isOtpExpired,
    );
  }
}

// ====================
// Notifier
// ====================

class PatrolNotifier extends ChangeNotifier {
  final PatrolRepository _repository;
  final LocationService _locationService;
  NotificationService? _notificationService;

  PatrolNotifier(
    this._repository,
    this._locationService, {
    this._notificationService,
  }) {
    // Set up alarm callback
    _setupAlarmCallback();
  }

  /// Callback for when patrol alarm is triggered
  void Function(String? message)? onAlarmTriggered;

  /// Static global callback for alarm navigation (works from anywhere)
  static void Function(String? message)? onAlarmNavigated;

  /// Navigation function to go to alarm screen
  void Function(String? message)? navigateToAlarmScreen;

  PatrolState _state = PatrolState();
  PatrolState get state => _state;

  Timer? _countdownTimer;
  Timer? _countdownBadgeTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownBadgeTimer?.cancel();
    super.dispose();
  }

  /// Setup alarm callback in notification service
  void _setupAlarmCallback() {
    if (_notificationService != null) {
      _notificationService!.onPatrolAlarmReceived = (message) {
        showAlarmAlert(message: message);
      };
    }
  }

  /// Set notification service (can be called after initialization)
  void setNotificationService(NotificationService service) {
    _notificationService = service;
    _setupAlarmCallback();
  }

  /// Show alarm alert (called when patrol alarm is triggered)
  void showAlarmAlert({String? message}) {
    
    final alarmMessage = message ?? 'Waktunya patroli checkpoint berikutnya!';
    _state = _state.copyWith(
      showAlarmAlert: true,
      alarmMessage: alarmMessage,
    );
    notifyListeners();

    // Navigate to alarm screen via static callback (works from anywhere)
    
    PatrolNotifier.onAlarmNavigated?.call(alarmMessage);
  }

  /// Dismiss alarm alert and stop alarm sound
  Future<void> dismissAlarm() async {
    // Stop alarm sound
    if (_notificationService != null) {
      await _notificationService!.stopAlarm();
    }
    _state = _state.copyWith(clearAlarm: true);
    notifyListeners();
  }

  /// Load today's patrol status
  Future<void> loadTodayStatus() async {
    
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      
      final status = await _repository.getTodayStatus();
      

      _state = _state.copyWith(
        todayStatus: status,
        isLoading: false,
      );

      
      notifyListeners();

      // Schedule/cancel patrol alarm based on new status
      await _updatePatrolAlarm(status);
    } on ApiException catch (e) {
      
      _state = _state.copyWith(
        isLoading: false,
        error: e.message,
      );
      notifyListeners();
    } catch (e) {
      
      _state = _state.copyWith(
        isLoading: false,
        error: 'Gagal memuat status patroli: $e',
      );
      notifyListeners();
    }
  }

  /// Update patrol alarm based on current status
  Future<void> _updatePatrolAlarm(PatrolTodayStatus status) async {
    if (_notificationService == null) return;

    final progress = status.currentProgress;

    // Cancel existing alarm if no schedule
    if (!status.hasSchedule || progress == null) {
      await _notificationService!.cancelPatrolAlarm();
      _countdownBadgeTimer?.cancel();
      return;
    }

    // Cancel if overdue (no point scheduling past alarm)
    if (progress.currentRoundIsOverdue) {
      await _notificationService!.cancelPatrolAlarm();
      // Start countdown badge timer for overdue state
      _startOverdueCountdown();
      return;
    }

    // Schedule alarm if we have a due time
    if (progress.currentRoundDueAt != null) {
      await _notificationService!.schedulePatrolAlarm(
        scheduledTime: progress.currentRoundDueAt!,
        roundInfo: 'Checkpoint #${status.nextExpectedSequence} harus selesai dalam ${progress.intervalMinutes} menit',
      );

      // Start countdown badge timer
      _startCountdownBadgeTimer(progress.currentRoundDueAt!);
    } else {
      // No due time - cancel any scheduled alarm
      await _notificationService!.cancelPatrolAlarm();
      _countdownBadgeTimer?.cancel();
    }
  }

  /// Start timer to update countdown badge every minute
  void _startCountdownBadgeTimer(DateTime dueAt) {
    _countdownBadgeTimer?.cancel();
    _countdownBadgeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Check if we've passed the due time
      if (DateTime.now().isAfter(dueAt)) {
        // Due time has passed - cancel timer, UI will show overdue state
        _countdownBadgeTimer?.cancel();
        // Just notify listeners to update UI, don't make API call
        notifyListeners();
      } else {
        // Force UI update to refresh countdown text
        notifyListeners();
      }
    });
  }

  /// Start countdown timer for overdue state (refresh every 30 seconds)
  void _startOverdueCountdown() {
    _countdownBadgeTimer?.cancel();
    _countdownBadgeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Force UI update to refresh overdue state
      notifyListeners();
    });
  }

  /// Fetch current OTP/checkpoint info from server
  Future<void> fetchOtp({String? qrCode}) async {
    try {
      final otp = await _repository.getOtp(qrCode: qrCode);
      _state = _state.copyWith(
        otpResponse: otp,
        isOtpExpired: !otp.hasTotp,
      );
      notifyListeners();
    } catch (e) {
      
    }
  }

  /// Perform a scan - get OTP, display it, then user inputs and submits
  Future<PatrolScanResult?> performScan(String qrContent) async {
    if (_state.isScanning) return null;

    _state = _state.copyWith(isScanning: true, clearError: true);
    notifyListeners();

    try {
      // Parse QR content
      final qrResult = QRScanResult.fromQRContent(qrContent);
      

      // Fetch checkpoint info to check if TOTP is needed
      await fetchOtp(qrCode: qrContent);
      final otpInfo = _state.otpResponse;

      // If checkpoint has TOTP but no secret key, we can't proceed
      if (otpInfo != null && otpInfo.hasTotp && qrResult.secretKey == null) {
        _state = _state.copyWith(
          isScanning: false,
          error: 'Checkpoint memerlukan OTP. QR code tidak valid atau corrupt.',
        );
        notifyListeners();
        return null;
      }

      // If no secret key, skip OTP and scan directly
      if (qrResult.secretKey == null) {
        
        return await _doScan(qrResult.code, null);
      }

      // Generate TOTP locally and return it for user to input
      final generatedOtp = generateTOTP(qrResult.secretKey!);
      

      // Store the generated OTP for validation
      _state = _state.copyWith(
        isScanning: false,
        // Return null to indicate we need user input
        // The UI should show the generated OTP and ask for input
      );
      notifyListeners();

      return null; // Caller should show OTP input dialog
    } catch (e) {
      _state = _state.copyWith(
        isScanning: false,
        error: 'Scan gagal: $e',
      );
      notifyListeners();
      return null;
    }
  }

  /// Submit OTP and complete the scan
  Future<PatrolScanResult?> submitOtpAndScan(
    String qrContent,
    String otp,
  ) async {
    if (_state.isScanning) return null;

    _state = _state.copyWith(isScanning: true, clearError: true);
    notifyListeners();

    try {
      // Parse QR content
      final qrResult = QRScanResult.fromQRContent(qrContent);

      // Perform scan with OTP (backend will validate)
      return await _doScan(qrResult.code, otp);
    } catch (e) {
      _state = _state.copyWith(
        isScanning: false,
        error: 'Scan gagal: $e',
      );
      notifyListeners();
      return null;
    }
  }

  /// Internal method to perform the actual scan API call
  Future<PatrolScanResult?> _doScan(String qrCode, String? otp) async {
    // Get current location
    LocationData? location;
    bool isMockLocation = false;
    try {
      location = await _locationService.getCurrentLocation();
      if (defaultTargetPlatform == TargetPlatform.android) {
        isMockLocation = false;
      }
    } on LocationException catch (e) {
      _state = _state.copyWith(
        isScanning: false,
        error: e.message,
      );
      notifyListeners();
      return null;
    }

    // Perform scan
    final result = await _repository.scan(
      qrCode: qrCode,
      latitude: location.latitude,
      longitude: location.longitude,
      otp: otp,
      isMockLocation: isMockLocation,
      scannedAtLocal: DateTime.now().toIso8601String(),
    );

    _state = _state.copyWith(
      isScanning: false,
      lastScanResult: result,
    );
    notifyListeners();

    // If TOO_FAST, start countdown
    if (!result.success &&
        result.errorCode == 'TOO_FAST' &&
        result.minGapRemainingSeconds != null) {
      _startCountdown(result.minGapRemainingSeconds!);
    }

    // If scan was successful, reload status
    if (result.success) {
      await loadTodayStatus();
    }

    return result;
  }

  /// Generate TOTP code from secret key
  /// Uses SHA1 algorithm, 6 digits, 30-second interval (Google Authenticator standard)
  String generateTOTP(String secretKey) {
    try {
      // Clean the secret key (remove spaces, uppercase)
      final cleanSecret = secretKey.replaceAll(' ', '').toUpperCase();

      // Generate current TOTP using Google Authenticator compatible settings
      final code = OTP.generateTOTPCodeString(
        cleanSecret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true, // Use Google Authenticator compatible settings
        length: 6,
        interval: 30,
      );

      return code;
    } catch (e) {
      
      return '';
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    _state = _state.copyWith(
      isCountingDown: true,
      countdownSeconds: seconds,
    );
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newSeconds = _state.countdownSeconds - 1;
      if (newSeconds <= 0) {
        timer.cancel();
        _state = _state.copyWith(
          isCountingDown: false,
          countdownSeconds: 0,
        );
      } else {
        _state = _state.copyWith(countdownSeconds: newSeconds);
      }
      notifyListeners();
    });
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  /// Clear last scan result
  void clearLastScanResult() {
    _state = _state.copyWith(clearLastScanResult: true);
    notifyListeners();
  }

  /// Cancel all scheduled alarms (call on logout)
  Future<void> cancelAllAlarms() async {
    if (_notificationService != null) {
      await _notificationService!.cancelPatrolAlarm();
    }
    _countdownBadgeTimer?.cancel();
  }
}
