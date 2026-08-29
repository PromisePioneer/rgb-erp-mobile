import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../domain/models/backup_offer.dart';

/// Factory function to create BackupOfferRepository
BackupOfferRepository createBackupOfferRepository(Dio dio) {
  return BackupOfferRepository(dio);
}

/// Repository for backup offer operations
class BackupOfferRepository {
  final Dio _dio;

  BackupOfferRepository(this._dio);

  /// Get pending backup offers for the current user
  Future<BackupOfferListResponse> getPendingOffers() async {
    try {
      final response = await _dio.get(ApiEndpoints.backupOffers);
      return BackupOfferListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Accept a backup offer
  Future<AcceptBackupOfferResponse> acceptOffer(String offerId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.backupOfferAccept(offerId),
      );
      return AcceptBackupOfferResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Reject a backup offer
  Future<void> rejectOffer(String offerId, {String? reason}) async {
    try {
      await _dio.post(
        ApiEndpoints.backupOfferReject(offerId),
        data: reason != null ? {'reason': reason} : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
