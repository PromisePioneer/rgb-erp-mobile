import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/core.dart';
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
    final theme = FTheme.of(context);

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
            return FilterChip(
              label: Text(getName(item)),
              selected: isSelected,
              onSelected: (_) => onToggle(id),
              selectedColor: theme.colors.primary.withAlpha(51),
              checkmarkColor: theme.colors.primary,
              backgroundColor: theme.colors.card,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.foreground,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.border,
              ),
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
