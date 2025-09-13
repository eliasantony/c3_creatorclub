import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

class BookingRepository {
  BookingRepository(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final fa.FirebaseAuth _auth;

  /// Create a booking document.
  /// For Premium users, call with priceCents = 0 and status = 'confirmed'.
  /// For Basic users (Stripe flow), prefer creating after successful payment
  /// or mark as 'pending_payment' and confirm via webhook later.
  Future<String> createBooking({
    required String roomId,
    required DateTime startAt,
    required DateTime endAt,
    required int priceCents,
    String status = 'confirmed',
    String? paymentIntentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final data = <String, dynamic>{
      'roomId': roomId,
      'userId': user.uid,
      'startAt': Timestamp.fromDate(startAt.toUtc()),
      'endAt': Timestamp.fromDate(endAt.toUtc()),
      'priceCents': priceCents,
      'paymentIntentId': paymentIntentId,
      'status': status, // confirmed | pending_payment | canceled
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _firestore.collection('bookings').add(data);
    debugPrint('[BookingRepository] created booking ${doc.id}');
    return doc.id;
  }

  /// Stream all bookings for current user ordered by startAt desc (most recent first)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> userBookingsRaw() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Convenience: separate upcoming (startAt >= now) and past (startAt < now)
  Stream<({List<BookingData> upcoming, List<BookingData> past})>
  splitUserBookings() {
    return userBookingsRaw().map((docs) {
      final now = DateTime.now().toUtc();
      final upcoming = <BookingData>[];
      final past = <BookingData>[];
      for (final d in docs) {
        try {
          final data = BookingData.fromDoc(d);
          if (data.startAt.isAfter(now) || data.startAt.isAtSameMomentAs(now)) {
            upcoming.add(data);
          } else {
            past.add(data);
          }
        } catch (e) {
          debugPrint('[BookingRepository] failed to parse booking ${d.id}: $e');
        }
      }
      return (upcoming: upcoming, past: past);
    });
  }

  /// Watch a single booking by id (live updates of status / times)
  Stream<BookingData?> watchBooking(String id) {
    return _firestore.collection('bookings').doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      return BookingData(
        id: snap.id,
        roomId: data['roomId'] as String,
        startAt: (data['startAt'] as Timestamp).toDate().toUtc(),
        endAt: (data['endAt'] as Timestamp).toDate().toUtc(),
        priceCents: (data['priceCents'] ?? 0) as int,
        status: (data['status'] ?? 'confirmed') as String,
        paymentIntentId: data['paymentIntentId'] as String?,
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate().toUtc()
            : null,
      );
    });
  }
}

/// Simple booking data holder for list display.
class BookingData {
  BookingData({
    required this.id,
    required this.roomId,
    required this.startAt,
    required this.endAt,
    required this.priceCents,
    required this.status,
    this.paymentIntentId,
    this.createdAt,
  });
  final String id;
  final String roomId;
  final DateTime startAt;
  final DateTime endAt;
  final int priceCents;
  final String status;
  final String? paymentIntentId;
  final DateTime? createdAt;

  static BookingData fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return BookingData(
      id: doc.id,
      roomId: data['roomId'] as String,
      startAt: (data['startAt'] as Timestamp).toDate().toUtc(),
      endAt: (data['endAt'] as Timestamp).toDate().toUtc(),
      priceCents: (data['priceCents'] ?? 0) as int,
      status: (data['status'] ?? 'confirmed') as String,
      paymentIntentId: data['paymentIntentId'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate().toUtc()
          : null,
    );
  }
}

final userSplitBookingsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(bookingRepositoryProvider).splitUserBookings(),
);

final bookingProvider = StreamProvider.family.autoDispose<BookingData?, String>(
  (ref, id) {
    return ref.watch(bookingRepositoryProvider).watchBooking(id);
  },
);

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});
