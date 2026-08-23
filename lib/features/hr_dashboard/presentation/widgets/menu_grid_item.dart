import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// Menu grid item widget - circular icon with label below
class MenuGridItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String? badge;
  final VoidCallback onTap;

  const MenuGridItem({
    super.key,
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.badge,
    required this.onTap,
  });

  @override
  State<MenuGridItem> createState() => _MenuGridItemState();
}

class _MenuGridItemState extends State<MenuGridItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container with circular background
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppConstants.animationFast,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isPressed ? widget.fg.withAlpha(128) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: widget.bg.withAlpha(128),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Transform.scale(
              scale: _isPressed ? 0.92 : 1.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main icon centered
                  Center(
                    child: Icon(
                      widget.icon,
                      color: widget.fg,
                      size: 30,
                    ),
                  ),
                  // Badge (NEW, etc.) at top-right corner
                  if (widget.badge != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Label below icon
        SizedBox(
          width: 68,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
