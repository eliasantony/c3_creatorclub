import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/profile_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/onboarding_flow.dart';
import '../../features/auth/profile_edit_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/rooms/rooms_list_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../data/models/group.dart';
import '../../data/models/user_profile.dart';
// membership imported below already
import '../../features/membership/membership_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// Make router listen to auth state via a Riverpod provider
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final r =
      ref; // capture ref for reads inside redirect without re-creating router
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/rooms',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final authAsync = r.read(authStateChangesProvider);
      final profileAsync = r.read(userProfileProvider);
      final isSignedIn = authAsync.asData?.value != null;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/auth' || loc == '/signin' || loc == '/register';
      final isOnboarding = loc == '/onboarding';
      final isProfileRoute = loc.startsWith('/profile');
      if (!isSignedIn) {
        return isAuthRoute ? null : '/auth';
      }
      // Signed in: check profile completeness
      final profile = profileAsync.asData?.value;
      bool incomplete = false;
      if (profile == null) {
        // Wait until profile loads; do not force redirect to rooms yet
        // Keep user where they are unless on auth routes
        if (isAuthRoute) return '/rooms';
        if (isProfileRoute) return null;
        return null;
      } else {
        incomplete = _isProfileIncomplete(profile);
      }

      if (incomplete) {
        // Do not bounce away from the profile screen on refresh; only force onboarding elsewhere
        if (isOnboarding || isProfileRoute) return null;
        return '/onboarding';
      }

      // Profile complete: avoid auth and onboarding routes
      if (isAuthRoute || isOnboarding) return '/rooms';
      return null;
    },
    routes: <RouteBase>[
      // Root path is not used as an entry since we set initialLocation.
      // Combined auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Backward compat routes redirect to combined auth
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const AuthScreen(),
      ),
      // Onboarding flow
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingFlow(),
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
        path: '/chat/:id',
        name: 'chat_room',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          return ChatScreen(groupId: id, group: extra is Group ? extra : null);
        },
      ),
      GoRoute(
        path: '/membership',
        name: 'membership',
        builder: (context, state) => const MembershipScreen(),
      ),
    ],
  );
});

bool _isProfileIncomplete(UserProfile profile) {
  // Basic required fields exist from registration
  if (profile.name.isEmpty || profile.email.isEmpty) return true;
  // Enforce completion of these optional fields during onboarding
  if (profile.phone == null || profile.phone!.isEmpty) return true;
  if (profile.profession == null || profile.profession!.isEmpty) return true;
  if (profile.niche == null || profile.niche!.isEmpty) return true;
  if (profile.photoUrl == null || profile.photoUrl!.isEmpty) return true;
  return false;
}
