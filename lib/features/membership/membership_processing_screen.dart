import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/payment_repository.dart';

class MembershipProcessingScreen extends ConsumerStatefulWidget {
  const MembershipProcessingScreen({super.key});

  @override
  ConsumerState<MembershipProcessingScreen> createState() =>
      _MembershipProcessingScreenState();
}

class _MembershipProcessingScreenState
    extends ConsumerState<MembershipProcessingScreen> {
  Timer? _timer;
  int _attempts = 0;
  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 2), (t) {
      final profile = ref.read(userProfileProvider).value;
      if (profile?.membershipTier == 'premium') {
        t.cancel();
        if (mounted) {
          if (context.mounted) context.go('/membership/success');
        }
      } else if (++_attempts > 30) {
        // ~60 seconds
        t.cancel();
        // Attempt one manual sync with backend
        _attemptSync();
      }
    });
  }

  Future<void> _attemptSync() async {
    try {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final found = await paymentRepo.syncMembershipForUser();
      ref.invalidate(userProfileProvider);
      await Future.delayed(const Duration(seconds: 2));
      final profile = ref.read(userProfileProvider).value;
      if (profile?.membershipTier == 'premium' && mounted) {
        if (context.mounted) context.go('/membership/success');
        return;
      }
      if (mounted) setState(() {});
      if (!found && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription not located yet. If payment succeeded it may still be pending.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final failed =
        _attempts > 30 &&
        ref.watch(userProfileProvider).value?.membershipTier != 'premium';
    return Scaffold(
      appBar: AppBar(title: const Text('Activating Membership')),
      body: Center(
        child: failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('Still processing...'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _attempts = 0;
                      });
                      _start();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _attemptSync,
                    child: const Text('Force Sync Now'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 16),
                  Text('Finalizing your subscription...'),
                ],
              ),
      ),
    );
  }
}
