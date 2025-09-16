import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/room.dart';

class BookingSuccessArgs {
  const BookingSuccessArgs({
    required this.room,
    required this.startAt,
    required this.endAt,
    required this.bookingId,
    this.isPremium = false,
  });
  final Room room;
  final DateTime startAt;
  final DateTime endAt;
  final String bookingId;
  final bool isPremium;
}

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key, required this.args});
  final BookingSuccessArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final room = args.room;
    final start = args.startAt;
    final end = args.endAt;

    String two(int n) => n.toString().padLeft(2, '0');
    final hours = end.difference(start).inMinutes / 60.0;
    final hoursLabel = hours == hours.roundToDouble()
        ? '${hours.toStringAsFixed(0)}h'
        : '${hours.toStringAsFixed(1)}h';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.check_circle_rounded, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            'You\'re all set!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            args.isPremium
                ? 'Your Premium membership covered this booking.'
                : 'Your booking has been confirmed.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _RoomSummaryCard(room: room),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(
                '${two(start.hour)}:${two(start.minute)} – ${two(end.hour)}:${two(end.minute)}',
              ),
              subtitle: Text(
                '${start.year}-${two(start.month)}-${two(start.day)}  •  $hoursLabel',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: const Text('Booking ID'),
              subtitle: Text(args.bookingId),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () async {
              final event = Event(
                title: room.name,
                description:
                    'Booking at C3 Creator Club${args.isPremium ? ' (Premium)' : ''}',
                location: room.neighborhood ?? 'C3 Creator Club',
                startDate: start,
                endDate: end,
                iosParams: const IOSParams(reminder: Duration(minutes: 30)),
                androidParams: const AndroidParams(emailInvites: []),
              );
              await Add2Calendar.addEvent2Cal(event);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Calendar event created (check device calendar).',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('Add to Calendar'),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/bookings'),
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('View My Bookings'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.go('/rooms');
              } else {
                context.go('/rooms');
              }
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _RoomSummaryCard extends StatelessWidget {
  const _RoomSummaryCard({required this.room});
  final Room room;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = room.photos.isNotEmpty ? room.photos.first : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: imageUrl == null
                ? Container(color: scheme.surfaceContainerHighest)
                : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((room.neighborhood ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            room.neighborhood!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
