import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingProcessingArgs {
  const BookingProcessingArgs({
    required this.paymentIntentId,
    required this.roomName,
  });
  final String paymentIntentId;
  final String roomName;
}

class BookingProcessingScreen extends ConsumerStatefulWidget {
  const BookingProcessingScreen({super.key, required this.args});
  final BookingProcessingArgs args;
  @override
  ConsumerState<BookingProcessingScreen> createState() =>
      _BookingProcessingScreenState();
}

class _BookingProcessingScreenState
    extends ConsumerState<BookingProcessingScreen> {
  String? _bookingId;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    final fs = ref.read(firestoreProvider);
    final authAsync = ref.read(authStateChangesProvider);
    final uid =
        authAsync.asData?.value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // If auth not ready yet, wait a brief moment then retry once.
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final effectiveUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    for (int i = 0; i < 30; i++) {
      // Firestore rule requires userId == auth.uid in query constraints; include it.
      final query = fs
          .collection('bookings')
          .where('userId', isEqualTo: effectiveUid)
          .where('paymentIntentId', isEqualTo: widget.args.paymentIntentId)
          .limit(1);
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        setState(() => _bookingId = snap.docs.first.id);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }
    setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_bookingId != null) {
      // Will be popped and success screen pushed by upstream caller.
      Future.microtask(() => Navigator.of(context).pop(_bookingId));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Processing payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Still waiting for confirmation from Stripe.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This can occasionally take a bit longer. You can wait a little more or go back – you will not be charged twice.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      child: const Text('Go back'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _failed = false;
                        });
                        _poll();
                      },
                      child: const Text('Retry polling'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Finalizing your booking for ${widget.args.roomName}...',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can close this screen; we\'ll save your booking once the payment is confirmed.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
