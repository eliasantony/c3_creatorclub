import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SlotsRepository {
  SlotsRepository(this._functions, this._firestore);
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> lockSlot({
    required String roomId,
    required String yyyymmdd,
    required String slotId,
    int holdMinutes = 10,
  }) async {
    final callable = _functions.httpsCallable('lockSlot');
    await callable.call({
      'roomId': roomId,
      'yyyymmdd': yyyymmdd,
      'slotId': slotId,
      'holdMinutes': holdMinutes,
    });
  }

  Future<void> lockRange({
    required String roomId,
    required String yyyymmdd,
    required List<int> slots,
    int holdMinutes = 10,
  }) async {
    final callable = _functions.httpsCallable('lockSlotRange');
    await callable.call({
      'roomId': roomId,
      'yyyymmdd': yyyymmdd,
      'slots': slots,
      'holdMinutes': holdMinutes,
    });
  }

  Future<void> markBooked({
    required String roomId,
    required String yyyymmdd,
    required String slotId,
  }) async {
    final callable = _functions.httpsCallable('markSlotBooked');
    await callable.call({
      'roomId': roomId,
      'yyyymmdd': yyyymmdd,
      'slotId': slotId,
    });
  }

  /// Returns a set of disabled slot indices for the given date based on
  /// existing locked/booked docs in roomSlots/{roomId}/{yyyymmdd}.
  Future<Set<int>> fetchDisabledIndices({
    required String roomId,
    required String yyyymmdd,
  }) async {
    final qs = await _firestore
        .collection('roomSlots')
        .doc(roomId)
        .collection(yyyymmdd)
        .get();
    final disabled = <int>{};
    for (final d in qs.docs) {
      final data = d.data();
      final status = data['status'] as String?;
      if (status == 'booked' || status == 'locked') {
        final idx = int.tryParse(d.id);
        if (idx != null) disabled.add(idx);
      }
    }
    return disabled;
  }

  /// Realtime stream of disabled slots (locked or booked) for given date.
  Stream<Set<int>> watchDisabledIndices({
    required String roomId,
    required String yyyymmdd,
  }) {
    return _firestore
        .collection('roomSlots')
        .doc(roomId)
        .collection(yyyymmdd)
        .snapshots()
        .map((qs) {
          final disabled = <int>{};
          final self = FirebaseAuth.instance.currentUser?.uid;
          for (final d in qs.docs) {
            final data = d.data();
            final status = data['status'] as String?;
            final lockedBy = data['lockedBy'] as String?;
            // Hide slot only if booked OR locked by another user
            if (status == 'booked' ||
                (status == 'locked' && lockedBy != null && lockedBy != self)) {
              final idx = int.tryParse(d.id);
              if (idx != null) disabled.add(idx);
            }
          }
          return disabled;
        });
  }
}

final slotsRepositoryProvider = Provider<SlotsRepository>((ref) {
  return SlotsRepository(
    FirebaseFunctions.instance,
    FirebaseFirestore.instance,
  );
});
