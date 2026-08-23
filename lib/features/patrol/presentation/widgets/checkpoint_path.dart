import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Node status for checkpoint path
enum CheckpointNodeStatus {
  completed,
  active,
  locked,
}

/// A checkpoint node for the path visualization
class CheckpointNode {
  final int sequence;
  final CheckpointNodeStatus status;
  final String name;

  const CheckpointNode({
    required this.sequence,
    required this.status,
    required this.name,
  });
}

/// Level-map style checkpoint path visualization
/// Nodes arranged in a zig-zag vertical pattern
class CheckpointPath extends StatelessWidget {
  final List<CheckpointNode> nodes;
  final void Function(CheckpointNode)? onNodeTap;
  final double width;

  const CheckpointPath({
    super.key,
    required this.nodes,
    this.onNodeTap,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: nodes.isEmpty ? 100 : (nodes.length * 80.0),
      child: CustomPaint(
        painter: _CheckpointPathPainter(nodes: nodes),
        child: Stack(
          children: nodes.asMap().entries.map((entry) {
            final index = entry.key;
            final node = entry.value;
            return _buildNode(context, node, index);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context, CheckpointNode node, int index) {
    // Calculate position - zig-zag pattern
    final isLeft = index % 2 == 0;
    final xOffset = isLeft ? 20.0 : width - 70;
    final yOffset = index * 70.0 + 20;

    Color nodeColor;
    Color textColor;
    IconData icon;
    double nodeSize = 50;
    double fontSize = 16;

    switch (node.status) {
      case CheckpointNodeStatus.completed:
        nodeColor = AppColors.teal500;
        textColor = Colors.white;
        icon = Icons.check;
        break;
      case CheckpointNodeStatus.active:
        nodeColor = AppColors.primary;
        textColor = Colors.white;
        icon = Icons.navigation;
        nodeSize = 58;
        fontSize = 18;
        break;
      case CheckpointNodeStatus.locked:
        nodeColor = AppColors.slate300;
        textColor = AppColors.slate500;
        icon = Icons.lock;
        break;
    }

    return Positioned(
      left: xOffset,
      top: yOffset,
      child: GestureDetector(
        onTap: onNodeTap != null ? () => onNodeTap!(node) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Node circle
            Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                border: node.status == CheckpointNodeStatus.active
                    ? Border.all(color: AppColors.indigo200, width: 3)
                    : null,
                boxShadow: node.status == CheckpointNodeStatus.active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(77),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: icon == Icons.navigation
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: textColor, size: 20),
                          Text(
                            '${node.sequence}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: textColor, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '${node.sequence}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: fontSize - 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 4),
            // Node label
            SizedBox(
              width: 80,
              child: Text(
                node.name,
                style: TextStyle(
                  fontSize: 10,
                  color: node.status == CheckpointNodeStatus.locked
                      ? AppColors.slate400
                      : AppColors.slate600,
                  fontWeight: node.status == CheckpointNodeStatus.active
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckpointPathPainter extends CustomPainter {
  final List<CheckpointNode> nodes;

  _CheckpointPathPainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;

    final completedPaint = Paint()
      ..color = AppColors.teal500
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final lockedPaint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length - 1; i++) {
      final current = nodes[i];
      final next = nodes[i + 1];

      final isLeft = i % 2 == 0;
      final nextIsLeft = (i + 1) % 2 == 0;

      // Calculate start and end points (center of nodes)
      final startX = isLeft ? 20.0 + 25.0 : size.width - 70 + 25;
      final startY = i * 70.0 + 20 + 25;
      final endX = nextIsLeft ? 20.0 + 25 : size.width - 70 + 25;
      final endY = (i + 1) * 70.0 + 20 + 25;

      final start = Offset(startX, startY.toDouble());
      final end = Offset(endX, endY.toDouble());

      Paint paint;
      if (current.status == CheckpointNodeStatus.completed &&
          next.status != CheckpointNodeStatus.locked) {
        paint = completedPaint;
      } else if (next.status == CheckpointNodeStatus.locked) {
        paint = lockedPaint;
      } else {
        paint = completedPaint;
      }

      // Draw dashed line for locked segments
      if (next.status == CheckpointNodeStatus.locked) {
        _drawDashedLine(canvas, start, end, dashPaint);
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double current = 0;
    while (current < distance) {
      final dashEnd = current + dashWidth;
      canvas.drawLine(
        start + direction * current,
        start + direction * (dashEnd > distance ? distance : dashEnd),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CheckpointPathPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}
