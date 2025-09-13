import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room.dart';
import '../../membership/membership_screen.dart';

class RoomCard extends ConsumerWidget {
  const RoomCard({super.key, required this.room, this.onTap});
  final Room room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    // Card corner radius handled by theme; previous dynamic radius logic removed.

    final hasPhoto = room.photos.isNotEmpty && (room.photos.first).isNotEmpty;
    final isPremium = ref.watch(isPremiumProvider);
    final priceText = (!isPremium && room.priceCents != null)
        ? '€${(room.priceCents! / 100).toStringAsFixed(0)}'
        : null;
    final ratingText = room.rating?.toStringAsFixed(1);

    // Facilities: show up to 3, then “+N more”
    final facilities = room.facilities;
    final visibleFacilities = facilities.take(3).toList();
    final remaining = facilities.length - visibleFacilities.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Image header with overlays ----------
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: room.photos.first,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (_, __) => _imageSkeleton(),
                          errorWidget: (_, __, ___) => _imageFallback(scheme),
                        )
                      : _imageFallback(scheme),
                ),
                // Gradient for legibility (bottom)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          scheme.scrim.withOpacity(0.25),
                          scheme.scrim.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                // Rating pill (top-left)
                if (ratingText != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _Pill(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      label: ratingText,
                      bg: scheme.surface.withOpacity(0.82),
                      fg: scheme.onSurface,
                    ),
                  ),
                // Price pill (bottom-right)
                if (priceText != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _Pill(
                      icon: Icons.euro_rounded,
                      label: '$priceText / h',
                      bg: scheme.primary,
                      fg: scheme.onPrimary,
                    ),
                  ),
              ],
            ),

            // ---------- Content ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    room.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Meta row (location + capacity)
                  _MetaRow(
                    neighborhood: room.neighborhood,
                    capacity: room.capacity,
                    color: scheme.onSurfaceVariant,
                    text: text,
                  ),
                  const SizedBox(height: 10),

                  // Facilities
                  if (visibleFacilities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in visibleFacilities)
                          Chip(
                            label: Text(f),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.all(4),
                          ),
                        if (remaining > 0)
                          ActionChip(
                            label: Text('+$remaining more'),
                            onPressed: onTap,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.meeting_room, size: 48, color: scheme.onSurfaceVariant),
    );
  }

  Widget _imageSkeleton() {
    return const DecoratedBox(decoration: BoxDecoration(color: Colors.black12));
  }
}

// ---------- Small pieces ------------------------------------------------------

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.neighborhood,
    required this.capacity,
    required this.color,
    required this.text,
  });

  final String? neighborhood;
  final int? capacity;
  final Color color;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if ((neighborhood ?? '').isNotEmpty) {
      items.addAll([
        Icon(Icons.location_on_outlined, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            neighborhood!,
            style: text.bodySmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]);
    }

    if (capacity != null) {
      if (items.isNotEmpty) items.add(_dot());
      items.addAll([
        Icon(Icons.group_outlined, size: 16, color: color),
        const SizedBox(width: 4),
        Text('${capacity!} ppl', style: text.bodySmall?.copyWith(color: color)),
      ]);
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(children: items);
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('•', style: text.bodySmall?.copyWith(color: color)),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.iconColor,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? fg),
              const SizedBox(width: 4),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}
