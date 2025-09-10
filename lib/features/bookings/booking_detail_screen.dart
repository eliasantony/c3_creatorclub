import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/room.dart';

/// Args passed via router when confirming a booking for payment.
class BookingDetailArgs {
  const BookingDetailArgs({
    required this.room,
    required this.startAt,
    required this.endAt,
  });

  final Room room;
  final DateTime startAt;
  final DateTime endAt;
}

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.args});

  final BookingDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final room = args.room;
    final start = args.startAt;
    final end = args.endAt;

    final minutes = end.difference(start).inMinutes;
    final hours = minutes / 60.0;

    final pricePerHourCents = room.priceCents;
    final totalEuros = pricePerHourCents != null
        ? (pricePerHourCents * hours) / 100.0
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoomCard(room: room),
          const SizedBox(height: 16),
          _SummaryTile(
            icon: Icons.today_outlined,
            title: _dayLabel(start),
            subtitle:
                '${_two(start.hour)}:${_two(start.minute)} – ${_two(end.hour)}:${_two(end.minute)}  •  ${_fmtHours(hours)}',
          ),
          const SizedBox(height: 8),
          if (pricePerHourCents != null) ...[
            _SummaryTile(
              icon: Icons.attach_money_rounded,
              title: 'Price',
              subtitle:
                  '€${(pricePerHourCents / 100).toStringAsFixed(0)} / h  •  Total: €${totalEuros!.toStringAsFixed(2)}',
            ),
          ] else ...[
            _SummaryTile(
              icon: Icons.attach_money_rounded,
              title: 'Price',
              subtitle: 'Shown at payment',
            ),
          ],
          const SizedBox(height: 16),
          _PolicyBox(),
          const SizedBox(height: 120), // keep space for bottom bar
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_fmtHours(hours)} • ${_two(start.hour)}:${_two(start.minute)}–${_two(end.hour)}:${_two(end.minute)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      totalEuros != null
                          ? 'Total €${totalEuros.toStringAsFixed(2)}'
                          : 'Price shown at payment',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () async {
                  // TODO: Integrate Stripe PaymentSheet/Checkout via Functions
                  final messenger = ScaffoldMessenger.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  await Future.delayed(const Duration(seconds: 1));
                  if (context.mounted) Navigator.of(context).pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Payment flow coming soon (Stripe)'),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline),
                label: const Text('Pay now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
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
                  const SizedBox(height: 4),
                  if ((room.neighborhood ?? '').isNotEmpty)
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
                  if (room.capacity != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.group_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${room.capacity} people',
                          style: Theme.of(context).textTheme.bodySmall,
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _PolicyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Free cancellation up to 24 hours before your slot. Changes and refunds are handled according to our policy.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _dayLabel(DateTime d) =>
    '${_wday[d.weekday]}, ${_mon[d.month]} ${d.day}';
String _two(int n) => n.toString().padLeft(2, '0');
String _fmtHours(double hours) {
  final isInt = hours == hours.roundToDouble();
  return '${hours.toStringAsFixed(isInt ? 0 : 1)}h';
}

const _wday = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};
const _mon = {
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};
