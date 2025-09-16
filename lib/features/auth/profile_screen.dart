import 'package:c3_creatorclub/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/config_repository.dart';
import '../../data/repositories/payment_repository.dart';
// If AppTokens is in another file, import it so we can read theme extensions.
// import '../../theme/app_theme.dart'; // make sure AppTokens is visible

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateChangesProvider);
    final profile = ref.watch(userProfileProvider);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final tokens = theme.extension<AppTokens>() ?? AppTokens.defaults;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile/edit'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        color: scheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      auth: auth,
                      profile: profile,
                      scheme: scheme,
                      text: text,
                      tokens: tokens,
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      profile: profile,
                      auth: auth,
                      scheme: scheme,
                      text: text,
                      tokens: tokens,
                    ),
                    const SizedBox(height: 16),
                    _ActionsCard(
                      onSignOut: () =>
                          ref.read(authRepositoryProvider).signOut(),
                      scheme: scheme,
                      text: text,
                      tokens: tokens,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Header -----------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.auth,
    required this.profile,
    required this.scheme,
    required this.text,
    required this.tokens,
  });

  final AsyncValue<dynamic> auth;
  final AsyncValue<dynamic> profile;
  final ColorScheme scheme;
  final TextTheme text;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(tokens.radiusLarge);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: profile.when(
        data: (p) {
          final String name = (p?.name as String?)?.trim() ?? '';
          final String email = (p?.email as String?)?.trim() ?? '';
          final String tier = (p?.membershipTier as String?) ?? 'Free';
          final String photo = (p?.photoUrl as String?) ?? '';
          final String initials = _initialsFrom(name.isNotEmpty ? name : email);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                photoUrl: photo.isEmpty ? null : photo,
                initials: initials,
                size: 72,
                scheme: scheme,
                tokens: tokens,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _HeaderTexts(
                  name: name.isEmpty ? 'Your Name' : name,
                  email: email.isEmpty ? '—' : email,
                  tier: tier,
                  text: text,
                  scheme: scheme,
                ),
              ),
            ],
          );
        },
        loading: () => Row(
          children: [
            _SkeletonCircle(size: 72),
            const SizedBox(width: 16),
            const Expanded(
              child: _SkeletonLines(lines: 3, maxWidthFactor: 0.7),
            ),
          ],
        ),
        error: (e, st) => Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load profile',
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTexts extends StatelessWidget {
  const _HeaderTexts({
    required this.name,
    required this.email,
    required this.tier,
    required this.text,
    required this.scheme,
  });

  final String name;
  final String email;
  final String tier;
  final TextTheme text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 6,
      children: [
        Text(
          name,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Icon(Icons.mail_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                email,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text(
              tier.isNotEmpty
                  ? tier[0].toUpperCase() + tier.substring(1)
                  : tier,
            ),
            avatar: const Icon(Icons.workspace_premium, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.initials,
    required this.size,
    required this.scheme,
    required this.tokens,
  });

  final String? photoUrl;
  final String initials;
  final double size;
  final ColorScheme scheme;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.6);

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipOval(
            child: photoUrl == null
                ? Center(
                    child: Text(
                      initials,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => const _Skeleton(),
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.edit, size: 14, color: scheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

// ---------- Info Card --------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.profile,
    required this.auth,
    required this.scheme,
    required this.text,
    required this.tokens,
  });

  final AsyncValue<dynamic> profile;
  final AsyncValue<dynamic> auth;
  final ColorScheme scheme;
  final TextTheme text;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SectionHeader(
            icon: Icons.person_outline,
            title: 'Account',
            scheme: scheme,
            text: text,
          ),
          profile.when(
            data: (p) => Column(
              children: [
                _KVTile(
                  label: 'Name',
                  value: (p?.name as String?) ?? '—',
                  icon: Icons.badge_outlined,
                ),
                _Divider(scheme: scheme),
                _KVTile(
                  label: 'Email',
                  value: (p?.email as String?) ?? '—',
                  icon: Icons.mail_outline,
                ),
                _Divider(scheme: scheme),
                _KVTile(
                  label: 'Profession',
                  value: (p?.profession as String?) ?? '—',
                  icon: Icons.work_outline,
                ),
                _Divider(scheme: scheme),
                _KVTile(
                  label: 'Tier',
                  value: ((p?.membershipTier as String?) ?? '—').isNotEmpty
                      ? ((p?.membershipTier as String?) ?? '—')[0]
                                .toUpperCase() +
                            ((p?.membershipTier as String?) ?? '—').substring(1)
                      : '—',
                  icon: Icons.workspace_premium_outlined,
                ),
              ],
            ),
            loading: () => const _SkeletonList(count: 5),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load account details.',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Actions Card -----------------------------------------------------

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.onSignOut,
    required this.scheme,
    required this.text,
    required this.tokens,
  });

  final VoidCallback onSignOut;
  final ColorScheme scheme;
  final TextTheme text;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.settings_outlined,
            title: 'Actions',
            scheme: scheme,
            text: text,
          ),
          const SizedBox(height: 8),
          // Manage subscription (shown if premium tier)
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(userProfileProvider).value;
              final isPremium = (user?.membershipTier ?? 'basic') == 'premium';
              if (!isPremium) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final pricing = await ref.read(
                        pricingConfigProvider.future,
                      );
                      final originBase = Uri.base;
                      final schemeOk =
                          originBase.scheme == 'http' ||
                          originBase.scheme == 'https';
                      final origin = schemeOk
                          ? '${originBase.scheme}://${originBase.authority}'
                          : (pricing?.checkoutBaseUrl ?? 'https://example.com');
                      final portalUrl = await ref
                          .read(paymentRepositoryProvider)
                          .createBillingPortalSession(
                            returnUrl: '$origin/membership',
                          );
                      final uri = Uri.parse(portalUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        throw Exception('Cannot launch portal');
                      }
                    } catch (e) {
                      debugPrint('Error opening portal: $e');
                      final es = e.toString();
                      String msg;
                      if (es.contains('Billing Portal not configured')) {
                        msg = 'Portal not configured (Stripe dashboard)';
                      } else if (es.contains(
                        'Stripe Billing Portal not configured',
                      )) {
                        msg =
                            'Enable & save Billing Portal settings in Stripe test mode, then retry.';
                      } else if (es.contains('failed-precondition')) {
                        msg =
                            'Subscription/customer not ready yet. Retry shortly.';
                      } else {
                        msg = 'Portal error: $e';
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Manage Subscription'),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/bookings'),
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('My Bookings'),
            ),
          ),
          // Existing About button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'Creator Club',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Place Media',
              ),
              icon: const Icon(Icons.info_outline),
              label: const Text('About'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: FilledButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(scheme.errorContainer),
                foregroundColor: WidgetStatePropertyAll(
                  scheme.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------- Shared bits ------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.scheme,
    required this.text,
  });

  final IconData icon;
  final String title;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.primaryContainer,
        child: Icon(icon, color: scheme.onPrimaryContainer),
      ),
      title: Text(
        title,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      dense: true,
    );
  }
}

class _KVTile extends StatelessWidget {
  const _KVTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: scheme.onSurfaceVariant),
      ),
      title: Text(label, style: text.bodyMedium),
      subtitle: Text(
        value,
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.scheme});
  final ColorScheme scheme;
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
      indent: 16,
      endIndent: 16,
    );
  }
}

// ---------- Skeletons (no extra packages) -----------------------------------

class _Skeleton extends StatelessWidget {
  const _Skeleton({double? width, double? height, BorderRadius? borderRadius})
    : _width = width,
      _height = height,
      _borderRadius = borderRadius;

  final double? _width;
  final double? _height;
  final BorderRadius? _borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: _borderRadius ?? BorderRadius.circular(6),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({this.lines = 3, this.maxWidthFactor = 1.0});
  final int lines;
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    final children = List.generate(lines, (i) {
      final w = maxWidthFactor - (i * 0.1);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FractionallySizedBox(
          widthFactor: w.clamp(0.5, 1.0),
          child: const _Skeleton(height: 14),
        ),
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _Skeleton(height: 16),
        );
      }),
    );
  }
}

// ---------- Helpers ----------------------------------------------------------

String _initialsFrom(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
