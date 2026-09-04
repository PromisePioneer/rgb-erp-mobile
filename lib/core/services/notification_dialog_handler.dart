import '../../navigation/app_router.dart';
import '../../features/backup_offer/domain/models/backup_offer.dart';
import '../../features/backup_offer/domain/models/shift_response.dart';
import '../../features/backup_offer/data/repositories/backup_offer_repository.dart';
import '../../features/backup_offer/data/repositories/shift_response_repository.dart';
import '../../features/backup_offer/presentation/providers/backup_offer_provider.dart';
import '../../features/backup_offer/presentation/providers/shift_response_provider.dart';
import '../network/api_client.dart';
import 'storage_service.dart';
import 'notification_service_global.dart';

/// Global handler for showing notification screens
class NotificationDialogHandler {
  static final NotificationDialogHandler _instance = NotificationDialogHandler._internal();
  factory NotificationDialogHandler() => _instance;
  NotificationDialogHandler._internal();

  ShiftResponseNotifier? _shiftNotifier;
  BackupOfferNotifier? _backupNotifier;
  bool _initialized = false;

  /// Initialize the dialog handler with dependencies
  void init() {
    if (_initialized) return;

    final storage = StorageService();
    final dio = ApiClientFactory(storage: storage).create();
    final shiftRepo = ShiftResponseRepository(dio);
    final backupRepo = BackupOfferRepository(dio);

    _shiftNotifier = ShiftResponseNotifier(shiftRepo);
    _backupNotifier = BackupOfferNotifier(backupRepo);
    _initialized = true;
  }

  /// Handle shift reminder notification - navigate to shift response screen
  Future<void> handleShiftReminderNotification({
    String? message,
    String? scheduleId,
  }) async {
    

    if (scheduleId != null && scheduleId.isNotEmpty) {
      // Navigate directly with scheduleId from FCM payload
      
      _navigateToShiftResponseById(scheduleId);
    } else {
      // Fallback: fetch from API
      
      if (!_initialized) init();

      await _shiftNotifier?.loadPendingResponses();
      final shifts = _shiftNotifier?.state.pendingShifts;
      

      if (shifts != null && shifts.isNotEmpty) {
        final shift = shifts.first;
        
        _navigateToShiftResponse(shift);
      } else {
        
      }
    }
  }

  /// Handle backup offer notification - navigate to backup offer screen
  Future<void> handleBackupOfferNotification({
    String? message,
    String? offerId,
    String? scheduleId,
  }) async {
    

    if (!_initialized) init();

    await _backupNotifier?.loadPendingOffers();
    final offers = _backupNotifier?.state.offers;
    

    if (offers != null && offers.isNotEmpty) {
      final offer = offers.first;
      
      _navigateToBackupOffer(offer);
    } else {
      
    }
  }

  /// Navigate to shift response screen
  void _navigateToShiftResponse(PendingShiftResponse shift) {
    try {
      globalNotificationService.stopAlarm();

      // Delay navigation to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        appRouterProvider.push('/attendance/shift-response?shiftId=${shift.id}');
      });
    } catch (e) {
      
    }
  }

  /// Navigate to shift response screen by schedule ID (direct from FCM payload)
  void _navigateToShiftResponseById(String scheduleId) {
    try {
      globalNotificationService.stopAlarm();

      // Delay navigation to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        appRouterProvider.push('/attendance/shift-response?shiftId=$scheduleId');
      });
    } catch (e) {
      
    }
  }

  /// Navigate to backup offer screen
  void _navigateToBackupOffer(BackupOffer offer) {
    try {
      globalNotificationService.stopAlarm();

      // Delay navigation to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        appRouterProvider.push('/attendance/backup-offer?offerId=${offer.id}');
      });
    } catch (e) {
      
    }
  }
}

/// Global instance
final notificationDialogHandler = NotificationDialogHandler();
