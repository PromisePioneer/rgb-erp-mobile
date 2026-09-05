import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';

/// Biometric login section widget
class BiometricSection extends StatelessWidget {
  final bool enabled;
  final String? biometryType;
  final bool hasSavedCredentials;
  final VoidCallback? onBiometricLogin;
  final VoidCallback? onEnableBiometric;

  const BiometricSection({
    super.key,
    required this.enabled,
    this.biometryType,
    this.hasSavedCredentials = false,
    this.onBiometricLogin,
    this.onEnableBiometric,
  });

  String get _biometricLabel {
    switch (biometryType) {
      case 'Face ID':
        return 'Face ID';
      case 'Touch ID':
        return 'Touch ID';
      default:
        return 'Fingerprint';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasSavedCredentials && !enabled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        if (enabled && hasSavedCredentials) ...[
          // Biometric login button (prominent)
          GestureDetector(
            onTap: onBiometricLogin,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Icon(
                IconMap.fingerprint,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gunakan $_biometricLabel',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ] else if (hasSavedCredentials && !enabled) ...[
          // Enable biometric option
          GestureDetector(
            onTap: onEnableBiometric,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconMap.fingerprint,
                    size: 24,
                    color: AppColors.gray600,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Aktifkan $_biometricLabel',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Toggle biometric
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              enabled ? 'Nonaktifkan' : 'Aktifkan',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
              ),
            ),
            FSwitch(
              value: enabled,
              onChange: hasSavedCredentials
                  ? (value) {
                      if (!value) {
                        onEnableBiometric?.call();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
