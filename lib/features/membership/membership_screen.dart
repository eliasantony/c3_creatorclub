import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final isPremiumProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return (profile?.membershipTier ?? 'basic') == 'premium';
});

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPremium ? 'You are Premium' : 'Upgrade to Premium',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Premium unlocks community chat and booking perks.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (!isPremium)
              FilledButton(
                onPressed: () {
                  // TODO: integrate Stripe Checkout
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stripe flow coming soon')),
                  );
                },
                child: const Text('Upgrade'),
              )
            else
              const Text('Thanks for supporting the community!'),
          ],
        ),
      ),
    );
  }
}
