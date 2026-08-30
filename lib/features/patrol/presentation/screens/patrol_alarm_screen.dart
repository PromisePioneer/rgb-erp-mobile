import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';

/// Alarm screen that triggers when patrol alarm goes off
class PatrolAlarmScreen extends StatefulWidget {
  final String message;

  const PatrolAlarmScreen({
    super.key,
    this.message = 'Waktunya patroli checkpoint berikutnya!',
  });

  @override
  State<PatrolAlarmScreen> createState() => _PatrolAlarmScreenState();
}

class _PatrolAlarmScreenState extends State<PatrolAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Keep screen awake and set to full brightness
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Vibrate on entry
    _vibrate();
  }

  void _vibrate() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _dismiss() {
    // Stop alarm sound
    globalNotificationService.stopAlarm();
    context.pop();
  }

  void _startPatrol() {
    // Stop alarm sound
    globalNotificationService.stopAlarm();
    context.go('/patrol/scan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC2626),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated alarm icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Title
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  '🚨 ALARM PATROLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'JAM PATROLI SUDAH DIMULAI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(51),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const Spacer(),

              // Action buttons
              _buildActionButton(
                icon: IconMap.qrCodeScanner,
                label: 'MULAI PATROLI SEKARANG',
                isPrimary: true,
                onPressed: _startPatrol,
              ),
              const SizedBox(height: 16),

              _buildActionButton(
                icon: IconMap.close,
                label: 'TUTUP ALARM',
                isPrimary: false,
                onPressed: _dismiss,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: SecondaryButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}
