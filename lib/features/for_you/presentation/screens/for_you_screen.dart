import 'package:flutter/material.dart';
import 'package:forui/forui.dart';


import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../../../shared/widgets/layout/top_gradient_background.dart';

/// For You screen - placeholder
class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

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
                  color: AppColors.teal100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMap.star,
                  color: AppColors.teal600,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Segera Hadir',
                style: theme.typography.display.lg.copyWith(
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Fitur personalisasi berdasarkan aktivitas Anda sedang dalam pengembangan',
                  textAlign: TextAlign.center,
                  style: theme.typography.body.md.copyWith(
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
