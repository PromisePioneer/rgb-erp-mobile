import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';

/// Alarm alert overlay widget that shows on dashboard when patrol alarm is triggered
class PatrolAlarmAlert extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const PatrolAlarmAlert({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<PatrolAlarmAlert> createState() => _PatrolAlarmAlertState();
}

class _PatrolAlarmAlertState extends State<PatrolAlarmAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFDC2626), // red-600
              Color(0xFFB91C1C), // red-700
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alarm icon with pulse
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            const Text(
              '🚨 ALARM PATROLI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              children: [
                // Dismiss button
                Expanded(
                  child: SecondaryButton(
                    label: 'Tutup Alarm',
                    icon: IconMap.close,
                    onPressed: widget.onDismiss,
                    fullWidth: false,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Go to patrol button
                Expanded(
                  child: PrimaryButton(
                    label: 'Mulai Patroli',
                    icon: IconMap.directionsRun,
                    onPressed: widget.onTap,
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
