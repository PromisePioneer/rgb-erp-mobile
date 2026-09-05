import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/icons/forui_icon_map.dart';
import '../../domain/models/daily_task.dart';

/// A reusable multi-select chip group widget for tools, chemicals, and PPEs
class ChoiceChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final Set<int> selectedIds;
  final String Function(T) getName;
  final void Function(int id) onToggle;

  const ChoiceChipGroup({
    super.key,
    required this.label,
    required this.items,
    required this.selectedIds,
    required this.getName,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colors.mutedForeground,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items.map((item) {
            final id = _getId(item);
            final isSelected = selectedIds.contains(id);
            return _CustomChip(
              label: getName(item),
              isSelected: isSelected,
              onTap: () => onToggle(id),
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }

  int _getId(T item) {
    if (item is DailyTaskTool) return (item as DailyTaskTool).id;
    if (item is DailyTaskChemical) return (item as DailyTaskChemical).id;
    if (item is DailyTaskPpe) return (item as DailyTaskPpe).id;
    throw ArgumentError('Unsupported item type: $T');
  }
}

/// Custom chip widget using ForUI theming
class _CustomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final FThemeData theme;

  const _CustomChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colors.primary.withAlpha(26)
              : theme.colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colors.primary
                : theme.colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                IconMap.check,
                size: 14,
                color: theme.colors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
