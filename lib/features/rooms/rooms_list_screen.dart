import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/room.dart';
import '../../data/repositories/rooms_repository.dart';
import 'widgets/room_card.dart';
import 'room_detail_screen.dart';

class RoomsListScreen extends ConsumerWidget {
  const RoomsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Rooms'),
        actions: [
          IconButton(
            tooltip: 'My Bookings',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => context.pushNamed('my_bookings'),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load rooms: $e')),
        data: (rooms) {
          final list = rooms.isNotEmpty ? rooms : _sampleRooms;
          return ListView(
            children: [
              const SectionHeader(title: 'Featured'),
              ...list
                  .take(2)
                  .map(
                    (r) => RoomCard(
                      room: r,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(room: r),
                        ),
                      ),
                    ),
                  ),
              const SectionHeader(title: 'All Spaces'),
              ...list.map(
                (r) => RoomCard(
                  room: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoomDetailScreen(room: r),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

// Temporary sample data for feel-good previews when Firestore is empty
const _sampleRooms = <Room>[
  Room(
    id: 'sample1',
    name: 'Podcast Studio – Neubau',
    description:
        'Cozy podcast studio with top-notch acoustic treatment and recording equipment.',
    neighborhood: 'Neubau',
    capacity: 3,
    facilities: ['podcast', 'acoustic', 'mic x3', 'wifi'],
    photos: [
      'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
    ],
    openHourStart: 6,
    openHourEnd: 23,
    priceCents: 6900,
    rating: 4.8,
  ),
  Room(
    id: 'sample2',
    name: 'Daylight Photo Loft – Leopoldstadt',
    description:
        'Bright and spacious photo loft with large windows and natural light.',
    neighborhood: 'Leopoldstadt',
    capacity: 4,
    facilities: ['lighting', 'backdrops', 'tripod', 'wifi'],
    photos: [
      'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
    ],
    openHourStart: 6,
    openHourEnd: 23,
    priceCents: 9900,
    rating: 4.6,
  ),
  Room(
    id: 'sample3',
    name: 'Meeting Room – Mariahilf',
    description:
        'Spacious meeting room equipped with a screen, whiteboard, and coffee station.',
    neighborhood: 'Mariahilf',
    capacity: 6,
    facilities: ['screen', 'whiteboard', 'coffee', 'wifi'],
    photos: [
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
    ],
    openHourStart: 6,
    openHourEnd: 23,
    priceCents: 5900,
    rating: 4.5,
  ),
  Room(
    id: 'sample4',
    name: 'Creator Corner – Wieden',
    description:
        'Creative space with a backdrop, lights, and props for photo shoots.',
    neighborhood: 'Wieden',
    capacity: 2,
    facilities: ['backdrop', 'lights', 'props', 'wifi'],
    photos: [
      'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
    ],
    openHourStart: 6,
    openHourEnd: 23,
    priceCents: 4900,
    rating: 4.4,
  ),
];
