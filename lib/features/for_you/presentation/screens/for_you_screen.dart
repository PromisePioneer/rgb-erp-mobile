import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';

/// For You screen - placeholder
class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopGradientBackground(
      gradientHeight: 180,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('For You'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.slate800,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.indigo100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.indigo600,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Segera Hadir',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Fitur personalisasi berdasarkan aktivitas Anda sedang dalam pengembangan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
