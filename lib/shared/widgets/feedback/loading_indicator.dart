import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Loading indicator widget using Forui's FCircularProgress
class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Map size to FCircularProgressSizeVariant
    final FCircularProgressSizeVariant progressSize;
    if (size <= 14) {
      progressSize = FCircularProgressSizeVariant.xs;
    } else if (size <= 16) {
      progressSize = FCircularProgressSizeVariant.sm;
    } else if (size <= 18) {
      progressSize = FCircularProgressSizeVariant.md;
    } else if (size <= 20) {
      progressSize = FCircularProgressSizeVariant.lg;
    } else {
      progressSize = FCircularProgressSizeVariant.xl;
    }

    // Use theme's default style
    return FCircularProgress(
      size: progressSize,
    );
  }
}

/// Loading indicator with text
class LoadingWithText extends StatelessWidget {
  final String? text;
  final double size;

  const LoadingWithText({
    super.key,
    this.text,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingIndicator(size: size),
        if (text != null) ...[
          const SizedBox(height: 8),
          Text(
            text!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
