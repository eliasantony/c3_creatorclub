import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/group.dart';

// Session guard so we don't re-open the ToS dialog repeatedly during rebuilds.
final _chatTosPromptedProvider = StateProvider.family<bool, String>(
  (ref, uid) => false,
);

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final profile = ref.watch(userProfileProvider).value;
    final isPremium = (profile?.membershipTier ?? 'basic') == 'premium';

    // If premium but ToS not accepted yet, show a blocking dialog once per session (per uid).
    if (profile != null && isPremium && (profile.chatTosAccepted != true)) {
      final prompted = ref.watch(_chatTosPromptedProvider(profile.uid));
      if (!prompted) {
        // Defer any provider writes/dialogs until after build completes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Double-check in case another frame already prompted.
          final alreadyPrompted = ref.read(
            _chatTosPromptedProvider(profile.uid),
          );
          if (alreadyPrompted) return;
          ref.read(_chatTosPromptedProvider(profile.uid).notifier).state = true;
          _showChatTosDialog(context: context, ref: ref, uid: profile.uid);
        });
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: !isPremium
          ? _Upsell()
          : groupsAsync.when(
              data: (groups) => _GroupsList(groups: groups),
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

Future<void> _showChatTosDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String uid,
}) async {
  bool saving = false;
  await showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Community Guidelines & Terms'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To participate in Community chat, you must agree to our Terms of Service and Community Guidelines. Highlights:',
                    ),
                    const SizedBox(height: 12),
                    _Bullet(
                      'Be respectful and constructive. No harassment or hate speech.',
                    ),
                    _Bullet('No spam, self-promotion, or scams.'),
                    _Bullet(
                      'Keep content appropriate and legal. No NSFW or illegal material.',
                    ),
                    _Bullet(
                      'Protect privacy. Don\'t share personal or confidential info.',
                    ),
                    _Bullet(
                      'Follow moderators\' directions; repeated violations may lead to removal.',
                    ),
                    _Bullet(
                      'Report issues via Profile > Support. Full Terms are in Profile > Legal.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        Future<void>(() async {
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .setChatTosAccepted(uid: uid);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save: $e')),
                              );
                            }
                          }
                        });
                      },
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I Agree'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({required this.groups});
  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: Text('No groups yet. Community channels will appear here.'),
      );
    }
    return ListView.separated(
      itemBuilder: (_, i) {
        final g = groups[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.group_outlined)),
          title: Text(g.name),
          subtitle: Text(g.type == 'community' ? 'Community' : 'Private'),
          onTap: () => context.push('/chat/${g.id}', extra: g),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: groups.length,
    );
  }
}

class _Upsell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Community chat is a Premium feature',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/membership'),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
