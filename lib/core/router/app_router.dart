import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart' show FirebaseCheckScreen; // reuse existing screen
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/profile_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/profile_edit_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/rooms/rooms_list_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/membership/membership_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// Make router listen to auth state via a Riverpod provider
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final isSignedIn = authAsync.asData?.value != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/signin' || loc == '/register';
      if (!isSignedIn) {
        return isAuthRoute ? null : '/signin';
      }
      // Signed in: avoid staying on auth routes or root, send to rooms
      if (isAuthRoute || loc == '/') return '/rooms';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const FirebaseCheckScreen(),
      ),
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Tab shell
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/rooms',
            name: 'rooms',
            builder: (context, state) => const RoomsListScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListScreen(),
            redirect: (context, state) {
              // Simple premium gate: send non-premium users to membership
              // Note: we cannot read Riverpod here; enforce UX via screen buttons and deep link rules later.
              return null;
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile_edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/membership',
        name: 'membership',
        builder: (context, state) => const MembershipScreen(),
      ),
    ],
  );
});
