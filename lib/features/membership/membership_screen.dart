import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/config_repository.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          final pricingAsync = ref.watch(pricingConfigProvider);
          final card = pricingAsync.when(
            data: (p) => _MembershipCard(isPremium: isPremium, pricing: p),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                _MembershipCard(isPremium: isPremium, pricing: null),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'You are Premium' : 'Go Premium',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Level up your creative workspace access. One simple monthly subscription.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (wide) Row(children: [Expanded(child: card)]) else card,
                const SizedBox(height: 40),
                if (!isPremium) _UpgradeCta() else const _PremiumActions(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MembershipCard extends ConsumerWidget {
  const _MembershipCard({required this.isPremium, required this.pricing});
  final bool isPremium;
  final PricingConfig? pricing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 32,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Premium Membership',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pricing != null)
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          '€${(pricing!.priceCents / 100).toStringAsFixed(2)} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const TextSpan(text: '/ month'),
                  ],
                ),
              )
            else
              const Text(
                'Pricing unavailable',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 16),
            _Feature(
              icon: Icons.chat_bubble_rounded,
              label: 'Unlimited community chat access',
            ),
            _Feature(
              icon: Icons.meeting_room_rounded,
              label: 'Book premium rooms earlier',
            ),
            _Feature(
              icon: Icons.flash_on_rounded,
              label: 'Priority booking window',
            ),
            _Feature(
              icon: Icons.auto_awesome_rounded,
              label: 'Exclusive creator events',
            ),
            _Feature(
              icon: Icons.cancel_schedule_send_rounded,
              label: 'Flexible cancellations',
            ),
            const SizedBox(height: 8),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _UpgradeCta extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UpgradeCta> createState() => _UpgradeCtaState();
}

class _UpgradeCtaState extends ConsumerState<_UpgradeCta> {
  bool _loading = false;
  String _resolveBaseOrigin(PricingConfig? pricing) {
    final base = Uri.base; // Might be file:// in debug mobile
    final scheme = base.scheme;
    final configured = pricing?.checkoutBaseUrl;
    if (scheme != 'http' && scheme != 'https') {
      if (configured != null && configured.startsWith('http')) {
        debugPrint(
          'Membership: Non-http base (${base.scheme}) -> using configured "$configured"',
        );
        return configured.replaceAll(RegExp(r'/+$'), '');
      }
      debugPrint(
        'Membership: Non-http base (${base.scheme}) and no checkoutBaseUrl; using placeholder https://example.com',
      );
      return 'https://example.com';
    }
    // Safe to build origin manually (avoid .origin which can throw on some schemes)
    final origin = '${base.scheme}://${base.authority}';
    if (configured != null && configured.startsWith('http')) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    return origin;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to unlock everything?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final payRepo = ref.read(paymentRepositoryProvider);
                    final pricing = await ref.read(
                      pricingConfigProvider.future,
                    );
                    if (pricing == null) {
                      throw Exception('No pricing config');
                    }
                    // On mobile, Uri.base.origin is often file:// leading to invalid checkout URL usage.
                    final origin = _resolveBaseOrigin(pricing);
                    final success = '$origin/membership-success';
                    final cancel = '$origin/membership-cancel';
                    final url = await payRepo.createMembershipCheckoutSession(
                      priceId: pricing.priceId,
                      successUrl: success,
                      cancelUrl: cancel,
                    );
                    // Navigate to processing screen so when user returns we poll status
                    if (context.mounted) {
                      context.push('/membership/processing');
                    }
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw Exception('Cannot launch checkout');
                    }
                  } catch (e) {
                    debugPrint('Error starting checkout: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to start checkout: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe now'),
        ),
        const SizedBox(height: 8),
        Text(
          'Cancel anytime. Billed monthly.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ManageSubscriptionCta extends ConsumerStatefulWidget {
  const _ManageSubscriptionCta();
  @override
  ConsumerState<_ManageSubscriptionCta> createState() =>
      _ManageSubscriptionCtaState();
}

class _ManageSubscriptionCtaState
    extends ConsumerState<_ManageSubscriptionCta> {
  bool _loading = false;
  String _resolveBaseOrigin(PricingConfig? pricing) {
    final base = Uri.base;
    final scheme = base.scheme;
    final configured = pricing?.checkoutBaseUrl;
    if (scheme != 'http' && scheme != 'https') {
      if (configured != null && configured.startsWith('http')) {
        debugPrint(
          'BillingPortal: Non-http base (${base.scheme}) -> using configured "$configured"',
        );
        return configured.replaceAll(RegExp(r'/+$'), '');
      }
      debugPrint(
        'BillingPortal: Non-http base (${base.scheme}) and no checkoutBaseUrl; using placeholder https://example.com',
      );
      return 'https://example.com';
    }
    final origin = '${base.scheme}://${base.authority}';
    if (configured != null && configured.startsWith('http')) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    return origin;
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _loading
        ? null
        : () async {
            setState(() => _loading = true);
            try {
              final payRepo = ref.read(paymentRepositoryProvider);
              final pricing = await ref.read(pricingConfigProvider.future);
              final origin = _resolveBaseOrigin(pricing);
              final portalUrl = await payRepo.createBillingPortalSession(
                returnUrl: '$origin/membership',
              );
              final uri = Uri.parse(portalUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                throw Exception('Cannot open portal');
              }
            } catch (e) {
              debugPrint('Error opening portal: $e');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Portal error: $e')));
            } finally {
              if (mounted) setState(() => _loading = false);
            }
          },
    child: _loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Open Billing Portal'),
  );
}

class _PremiumActions extends ConsumerStatefulWidget {
  const _PremiumActions();
  @override
  ConsumerState<_PremiumActions> createState() => _PremiumActionsState();
}

class _PremiumActionsState extends ConsumerState<_PremiumActions> {
  bool _canceling = false;
  bool _syncing = false;
  bool _immediate = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage your subscription',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const _ManageSubscriptionCta(),
            FilledButton.tonal(
              onPressed: _syncing
                  ? null
                  : () async {
                      setState(() => _syncing = true);
                      try {
                        final ok = await ref
                            .read(paymentRepositoryProvider)
                            .syncMembershipForUser();
                        ref.invalidate(userProfileProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Synced subscription'
                                  : 'No subscription found to sync',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _syncing = false);
                      }
                    },
              child: _syncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Refresh'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              onPressed: _canceling
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Cancel subscription?'),
                          content: StatefulBuilder(
                            builder: (c, setLocal) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'You can cancel at period end or immediately.',
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  value: _immediate,
                                  onChanged: (v) =>
                                      setLocal(() => _immediate = v),
                                  title: const Text('Cancel immediately'),
                                  subtitle: const Text(
                                    'Immediate: access ends now',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Keep'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      setState(() => _canceling = true);
                      try {
                        await ref
                            .read(paymentRepositoryProvider)
                            .cancelMembership(immediate: _immediate);
                        ref.invalidate(userProfileProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _immediate
                                  ? 'Canceled immediately'
                                  : 'Will cancel at period end',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cancel failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _canceling = false);
                      }
                    },
              child: _canceling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
