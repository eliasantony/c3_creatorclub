import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/rooms_repository.dart';
import '../../data/models/room.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitAsync = ref.watch(userSplitBookingsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: splitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('Failed to load bookings: $e\n$st');
          return Center(child: Text('Failed to load bookings: $e'));
        },
        data: (split) {
          final upcoming = split.upcoming
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
          final past = split.past
            ..sort((a, b) => b.startAt.compareTo(a.startAt));

          final rooms = roomsAsync.asData?.value;
          Room? roomFor(String id) => rooms?.firstWhere(
            (r) => r.id == id,
            orElse: () => Room(
              id: id,
              name: 'Room $id',
              description: '',
              neighborhood: null,
              capacity: 0,
              facilities: const [],
              photos: const [],
              openHourStart: 0,
              openHourEnd: 24,
              priceCents: 0,
              rating: 0,
            ),
          );

          if (upcoming.isEmpty && past.isEmpty) {
            return _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionHeader(label: 'Upcoming'),
                ...upcoming.map(
                  (b) => _BookingTile(data: b, room: roomFor(b.roomId)),
                ),
                const SizedBox(height: 12),
              ],
              if (past.isNotEmpty) ...[
                const _SectionHeader(label: 'Past'),
                ...past.map(
                  (b) => _BookingTile(data: b, room: roomFor(b.roomId)),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.data, required this.room});
  final BookingData data;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = data.startAt.toLocal();
    final end = data.endAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final time =
        '${two(start.hour)}:${two(start.minute)}–${two(end.hour)}:${two(end.minute)}';
    final date = '${two(start.day)}.${two(start.month)}.${start.year}';
    final durationH = data.endAt.difference(data.startAt).inMinutes / 60.0;
    final durLabel = durationH == durationH.roundToDouble()
        ? '${durationH.toStringAsFixed(0)}h'
        : '${durationH.toStringAsFixed(1)}h';
    final price = data.priceCents == 0
        ? 'Included'
        : '€${(data.priceCents / 100).toStringAsFixed(2)}';
    final imageUrl = (room?.photos.isNotEmpty ?? false)
        ? room!.photos.first
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          'booking_detail_view',
          pathParameters: {'id': data.id},
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 72,
                  width: 92,
                  child: imageUrl == null
                      ? Container(color: scheme.surfaceVariant)
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room?.name ?? data.roomId,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 12),
                          _StatusChip(status: data.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$date  •  $time',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$durLabel  •  $price',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (status) {
      case 'pending_payment':
        bg = scheme.surfaceContainerHighest;
        fg = scheme.primary;
        break;
      case 'canceled':
        bg = scheme.errorContainer;
        fg = scheme.error;
        break;
      default:
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, color: fg),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'When you book a room it will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/rooms'),
              child: const Text('Explore Rooms'),
            ),
          ],
        ),
      ),
    );
  }
}
