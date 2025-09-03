import 'package:flutter/material.dart';

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.startHour,
    required this.endHour,
    this.onTapIndex,
    this.selectedStartIndex,
    this.selectedEndIndex,
    this.columns = 4,
    this.compact = true,
    this.disabledIndices = const {},
  });

  final int startHour; // e.g., 6
  final int endHour; // e.g., 23
  final ValueChanged<int>? onTapIndex;
  final int? selectedStartIndex;
  final int? selectedEndIndex; // treated as exclusive when both provided
  final int columns;
  final bool compact;
  final Set<int> disabledIndices;

  List<TimeOfDay> _buildSlots() {
    final slots = <TimeOfDay>[];
    for (var h = startHour; h < endHour; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }
    return slots;
  }

  bool _isIndexSelected(int index) {
    final s = selectedStartIndex;
    final e = selectedEndIndex;
    if (s == null) return false;
    if (e == null) return index == s;
    final start = s < e ? s : e;
    final end = s < e ? e : s; // exclusive
    return index >= start && index < end;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slots = _buildSlots();
    final textStyle = compact
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: compact ? 2.8 : 2.2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final t = slots[index];
          final label = t.format(context);
          final selected = _isIndexSelected(index);
          final disabled = disabledIndices.contains(index);

          final ButtonStyle style = OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            textStyle: textStyle,
            foregroundColor: selected
                ? scheme.onPrimary
                : (disabled ? scheme.onSurfaceVariant : null),
            backgroundColor: selected
                ? scheme.primary
                : (disabled ? scheme.surfaceVariant : null),
            side: disabled
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                  ),
          ).merge(const ButtonStyle(visualDensity: VisualDensity.compact));

          return OutlinedButton(
            style: style,
            onPressed: (onTapIndex == null || disabled)
                ? null
                : () => onTapIndex!(index),
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        },
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
