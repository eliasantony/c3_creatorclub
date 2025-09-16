import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';

class MembershipSuccessScreen extends ConsumerWidget {
  const MembershipSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.membershipTier ?? 'basic';
    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'You are Premium! 🎉',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Your subscription is active. Enjoy all premium features.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                // Use GoRouter to ensure we land on the main app shell reliably even
                // if the success screen was reached via an external browser return
                // (no guarantee a previous Navigator stack exists).
                onPressed: () => context.go('/rooms'),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
              Text('Tier: $tier', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
