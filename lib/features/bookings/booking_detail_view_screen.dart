import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/rooms_repository.dart';
import '../../data/models/room.dart';

class BookingDetailViewArgs {
  const BookingDetailViewArgs({required this.bookingId});
  final String bookingId;
}

class BookingDetailViewScreen extends ConsumerWidget {
  const BookingDetailViewScreen({super.key, required this.args});
  final BookingDetailViewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingProvider(args.bookingId));
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }
          final rooms = roomsAsync.asData?.value;
          Room? room = rooms?.firstWhere(
            (r) => r.id == booking.roomId,
            orElse: () => Room(
              id: booking.roomId,
              name: 'Room ${booking.roomId}',
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
          final start = booking.startAt.toLocal();
          final end = booking.endAt.toLocal();
          String two(int n) => n.toString().padLeft(2, '0');
          final date = '${start.year}-${two(start.month)}-${two(start.day)}';
          final time =
              '${two(start.hour)}:${two(start.minute)} – ${two(end.hour)}:${two(end.minute)}';
          final durationH =
              booking.endAt.difference(booking.startAt).inMinutes / 60.0;
          final durLabel = durationH == durationH.roundToDouble()
              ? '${durationH.toStringAsFixed(0)}h'
              : '${durationH.toStringAsFixed(1)}h';
          final priceLabel = booking.priceCents == 0
              ? 'Included (Premium)'
              : '€${(booking.priceCents / 100).toStringAsFixed(2)}';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text(room?.name ?? booking.roomId),
                subtitle: Text(room?.neighborhood ?? ''),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text('$date  •  $time'),
                  subtitle: Text('Duration $durLabel'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(priceLabel),
                  subtitle: Text('Status: ${booking.status}'),
                ),
              ),
              if (booking.paymentIntentId != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Payment Intent'),
                    subtitle: Text(booking.paymentIntentId!),
                  ),
                ),
              ],
              if (booking.createdAt != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Created'),
                    subtitle: Text(booking.createdAt!.toLocal().toString()),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          );
        },
      ),
    );
  }
}
