import 'package:flutter/material.dart';

class MembershipBadge extends StatelessWidget {
  const MembershipBadge({super.key, required this.tier});
  final String tier; // 'basic' | 'premium'

  @override
  Widget build(BuildContext context) {
    final isPremium = tier.toLowerCase() == 'premium';
    final theme = Theme.of(context);
    final color = isPremium
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final fg = isPremium
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPremium ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: isPremium ? 0 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          isPremium ? 'Premium' : 'Basic',
          style: theme.textTheme.labelMedium?.copyWith(
            color: isPremium ? fg : color,
          ),
        ),
      ),
    );
  }
}
