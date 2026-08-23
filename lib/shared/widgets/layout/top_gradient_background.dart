import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Top gradient background widget - adds a subtle gradient at the top of the screen
/// Creates a premium, consistent look across all main screens in the app
class TopGradientBackground extends StatelessWidget {
  /// The child widget to display (usually the Scaffold body)
  final Widget child;

  /// Height of the gradient area from top
  final double gradientHeight;

  /// Colors for the gradient (top to bottom)
  final List<Color> colors;

  /// Background color for the rest of the screen
  final Color backgroundColor;

  const TopGradientBackground({
    super.key,
    required this.child,
    this.gradientHeight = 200,
    this.colors = const [AppColors.indigo50, Colors.white],
    this.backgroundColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          // Gradient layer at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          ),
          // Content layer
          child,
        ],
      ),
    );
  }
}
