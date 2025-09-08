import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/group.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final profile = ref.watch(userProfileProvider).value;
    final isPremium = (profile?.membershipTier ?? 'basic') == 'premium';
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
