import 'package:dio/dio.dart';

/// API exception with user-friendly error messages
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code; // For structured error codes (e.g., patrol errors)
  final Map<String, List<String>>? validationErrors; // For Laravel validation errors

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
    this.validationErrors,
  });

  factory ApiException.fromDioException(DioException e) {
    String message;
    int? statusCode = e.response?.statusCode;
    String? code;
    Map<String, List<String>>? validationErrors;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server took too long to respond.';
        break;
      case DioExceptionType.badResponse:
        final parsed = _parseErrorData(e.response);
        message = parsed['message'] ?? 'Server error.';
        code = parsed['code'];
        validationErrors = parsed['validation_errors'];
        statusCode ??= e.response?.statusCode;
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('SocketException') ?? false) {
          message = 'No internet connection.';
        } else {
          message = 'Something went wrong. Please try again.';
        }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: e.response?.data,
      code: code,
      validationErrors: validationErrors,
    );
  }

  /// Get all validation errors as a single formatted message
  String get formattedValidationErrors {
    if (validationErrors == null || validationErrors!.isEmpty) {
      return message;
    }

    final List<String> errors = [];
    for (final entry in validationErrors!.entries) {
      for (final error in entry.value) {
        errors.add(error);
      }
    }
    return errors.join('\n');
  }

  static Map<String, dynamic> _parseErrorData(Response? response) {
    if (response == null) {
      return {'message': 'Server error. Please try again later.'};
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Check for Laravel validation errors (422 with 'errors' key)
      Map<String, List<String>>? validationErrors;
      if (data.containsKey('errors') && data['errors'] is Map) {
        validationErrors = {};
        final errors = data['errors'] as Map;
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            validationErrors[entry.key.toString()] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            validationErrors[entry.key.toString()] = [value];
          }
        }
      }

      return {
        'message': data['message']?.toString() ??
            data['error']?.toString() ??
            data['msg']?.toString() ??
            _statusCodeMessage(response.statusCode),
        'code': data['code']?.toString(),
        'validation_errors': validationErrors,
      };
    }

    return {
      'message': _statusCodeMessage(response.statusCode),
      'code': null,
    };
  }

  static String _statusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server is unavailable. Please try again later.';
      case 503:
        return 'Service temporarily unavailable.';
      default:
        return 'Something went wrong.';
    }
  }

  @override
  String toString() => message;
}

/// Extension for easy error handling
extension DioExceptionExtension on DioException {
  ApiException toApiException() => ApiException.fromDioException(this);
}
