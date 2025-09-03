import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App shell with a Material 3 NavigationBar for MVP tabs
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem('Explore', Icons.meeting_room_outlined, '/rooms'),
    _TabItem('Chat', Icons.chat_bubble_outline, '/chat'),
    _TabItem('Profile', Icons.person_outline, '/profile'),
  ];

  int _locationToIndex(String location) {
    if (location.startsWith('/rooms')) return 0;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final target = _tabs[index].path;
          if (target != location) context.go(target);
        },
        destinations: _tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}
