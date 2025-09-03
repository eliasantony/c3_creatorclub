import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import 'auth_repository.dart';

final roomsCollectionProvider =
    Provider<CollectionReference<Map<String, dynamic>>>((ref) {
      final fs = ref.watch(firestoreProvider);
      return fs.collection('rooms');
    });

class RoomsRepository {
  RoomsRepository(this._collection);
  final CollectionReference<Map<String, dynamic>> _collection;

  Stream<List<Room>> watchRooms() {
    return _collection.snapshots().map(
      (snap) => snap.docs.map((d) {
        final data = {...d.data(), 'id': d.id};
        return Room.fromJson(data);
      }).toList(),
    );
  }
}

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository(ref.watch(roomsCollectionProvider));
});

final roomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomsRepositoryProvider).watchRooms();
});
