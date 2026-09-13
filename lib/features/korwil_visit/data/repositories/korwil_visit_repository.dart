import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/korwil_visit_entity.dart';

/// Repository for Korwil Visit API calls
class KorwilVisitRepository {
  late final Dio _dio;

  KorwilVisitRepository() {
    final storage = StorageService();
    final factory = ApiClientFactory(storage: storage);
    _dio = factory.create();
  }

  /// Get list of visits (paginated)
  Future<List<KorwilVisitEntity>> getVisits({
    int page = 1,
    int perPage = 15,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (fromDate != null) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate;
      }

      final response = await _dio.get(
        '/korwil-visit',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => KorwilVisitEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get today's visits
  Future<List<KorwilVisitEntity>> getTodayVisits() async {
    try {
      final response = await _dio.get('/korwil-visit/today');

      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => KorwilVisitEntity.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get visit detail
  Future<KorwilVisitEntity> getVisitDetail(int id) async {
    try {
      final response = await _dio.get('/korwil-visit/$id');

      return KorwilVisitEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Create a new visit
  Future<KorwilVisitEntity> createVisit({
    required int clientId,
    required DateTime inTime,
    DateTime? outTime,
    required String areaName,
    String? position,
    String? clientNote,
    String? fieldFindings,
    String? fieldAction,
    String? solution,
    double? latitude,
    double? longitude,
    List<String>? photosBase64,
    List<File>? videos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'client_id': clientId,
        'in_time': inTime.toIso8601String(),
        'area_name': areaName,
      });

      if (outTime != null) {
        formData.fields.add(MapEntry('out_time', outTime.toIso8601String()));
      }
      if (position != null) formData.fields.add(MapEntry('position', position));
      if (clientNote != null) formData.fields.add(MapEntry('client_note', clientNote));
      if (fieldFindings != null) formData.fields.add(MapEntry('field_findings', fieldFindings));
      if (fieldAction != null) formData.fields.add(MapEntry('field_action', fieldAction));
      if (solution != null) formData.fields.add(MapEntry('solution', solution));
      if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
      if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));

      // Add photos as base64 strings
      if (photosBase64 != null) {
        for (final photo in photosBase64) {
          formData.fields.add(MapEntry('photos[]', photo));
        }
      }

      // Add videos as files
      if (videos != null) {
        for (final video in videos) {
          formData.files.add(MapEntry(
            'videos[]',
            await MultipartFile.fromFile(video.path),
          ));
        }
      }

      final response = await _dio.post(
        '/korwil-visit',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return KorwilVisitEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update an existing visit
  Future<KorwilVisitEntity> updateVisit({
    required int id,
    int? clientId,
    DateTime? inTime,
    DateTime? outTime,
    String? areaName,
    String? position,
    String? clientNote,
    String? fieldFindings,
    String? fieldAction,
    String? solution,
    double? latitude,
    double? longitude,
    int? status,
    List<String>? photos,
    List<File>? newVideos,
    List<int>? deletePhotoIds,
    List<int>? deleteVideoIds,
  }) async {
    try {
      final formData = FormData.fromMap({});

      if (clientId != null) formData.fields.add(MapEntry('client_id', clientId.toString()));
      if (inTime != null) formData.fields.add(MapEntry('in_time', inTime.toIso8601String()));
      if (outTime != null) {
        formData.fields.add(MapEntry('out_time', outTime.toIso8601String()));
      } else {
        formData.fields.add(const MapEntry('out_time', ''));
      }
      if (areaName != null) formData.fields.add(MapEntry('area_name', areaName));
      if (position != null) formData.fields.add(MapEntry('position', position));
      if (clientNote != null) formData.fields.add(MapEntry('client_note', clientNote));
      if (fieldFindings != null) formData.fields.add(MapEntry('field_findings', fieldFindings));
      if (fieldAction != null) formData.fields.add(MapEntry('field_action', fieldAction));
      if (solution != null) formData.fields.add(MapEntry('solution', solution));
      if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
      if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));
      if (status != null) formData.fields.add(MapEntry('status', status.toString()));

      // Add new photos
      if (photos != null) {
        for (final photo in photos) {
          formData.fields.add(MapEntry('photos[]', photo));
        }
      }

      // Add new videos
      if (newVideos != null) {
        for (final video in newVideos) {
          formData.files.add(MapEntry(
            'new_videos[]',
            await MultipartFile.fromFile(video.path),
          ));
        }
      }

      // Delete photos
      if (deletePhotoIds != null) {
        for (final photoId in deletePhotoIds) {
          formData.fields.add(MapEntry('delete_photo_ids[]', photoId.toString()));
        }
      }

      // Delete videos
      if (deleteVideoIds != null) {
        for (final videoId in deleteVideoIds) {
          formData.fields.add(MapEntry('delete_video_ids[]', videoId.toString()));
        }
      }

      final response = await _dio.post(
        '/korwil-visit/$id',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return KorwilVisitEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete a visit (soft delete)
  Future<void> deleteVisit(int id) async {
    try {
      await _dio.delete('/korwil-visit/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get client options for dropdown
  Future<List<ClientOption>> getClientOptions({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }

      final response = await _dio.get(
        '/korwil-visit/clients',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => ClientOption.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Submit a visit
  Future<KorwilVisitEntity> submitVisit(int id) async {
    try {
      final response = await _dio.post('/korwil-visit/$id/submit');
      return KorwilVisitEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
