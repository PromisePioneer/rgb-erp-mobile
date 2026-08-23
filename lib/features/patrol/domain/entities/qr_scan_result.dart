import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Result of scanning a checkpoint QR code
/// Handles both old format (plain code) and new JSON format (code + secret_key)
class QRScanResult extends Equatable {
  /// The checkpoint code
  final String code;

  /// The TOTP secret key (if present in QR)
  final String? secretKey;

  const QRScanResult({
    required this.code,
    this.secretKey,
  });

  /// Parse QR content which can be:
  /// 1. Plain string code (old format, backward compatible): "CP-PROJ-01"
  /// 2. JSON with code and optional secret_key (new format): {"code": "CP-PROJ-01", "secret_key": "..."}
  factory QRScanResult.fromQRContent(String content) {
    if (content.isEmpty) {
      throw const FormatException('QR content is empty');
    }

    // Try to parse as JSON first (new format)
    if (content.startsWith('{')) {
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final code = json['code']?.toString();

        // If code is null or empty, throw FormatException (invalid QR)
        if (code == null || code.isEmpty) {
          throw const FormatException('QR JSON missing or empty "code" field');
        }

        return QRScanResult(
          code: code,
          secretKey: json['secret_key']?.toString(),
        );
      } on FormatException catch (e) {
        // If this is my own FormatException for missing code, rethrow it
        if (e.message.contains('code')) {
          rethrow;
        }
        // Otherwise, invalid JSON syntax - fall back to plain code (backward compatible)
        return QRScanResult(code: content);
      } catch (e) {
        // For other errors, fall back to plain code (backward compatible)
        return QRScanResult(code: content);
      }
    }

    // Plain code format (old format)
    return QRScanResult(code: content);
  }

  /// Check if this QR contains a secret_key (requires TOTP)
  bool get hasSecretKey => secretKey != null && secretKey!.isNotEmpty;

  /// Check if this is a legacy QR (no secret_key)
  bool get isLegacyQR => !hasSecretKey;

  @override
  List<Object?> get props => [code, secretKey];

  @override
  String toString() => 'QRScanResult(code: $code, hasSecretKey: $hasSecretKey)';
}
