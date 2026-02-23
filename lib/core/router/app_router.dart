import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/supabase_provider.dart';

// Route name constants — use these instead of raw strings throughout the app.
// Magic strings in navigation calls are a common source of bugs.
abstract class AppRoutes {
  static const splash    = '/';
  static const signIn    = '/sign-in';
  static const signUp    = '/sign-up';
  static const home      = '/home';
  static const budget    = '/budget';
  static const receipt   = '/receipt';
  static const analytics = '/analytics';
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    // redirect is called before every navigation event.
    // This is the single source of truth for auth-gating.
    redirect: (context, state) {
      // We read auth state from the Supabase singleton here because
      // GoRouter's redirect runs outside the Riverpod widget tree.
      // Auth state is re-evaluated on every route change.
      final session = ProviderScope.containerOf(context)
          .read(currentUserProvider);

      final isOnAuthRoute = state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.signUp;

      if (session == null && !isOnAuthRoute) {
        return AppRoutes.signIn;
      }

      if (session != null && isOnAuthRoute) {
        return AppRoutes.home;
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Sign In — Step 6')),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Sign Up — Step 6')),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Home — Step 6')),
        ),
      ),
      GoRoute(
        path: AppRoutes.budget,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Budget — Step 6')),
        ),
      ),
      GoRoute(
        path: AppRoutes.receipt,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Receipt — Step 7')),
        ),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Analytics — Step 8')),
        ),
      ),
    ],
  );
}

// The splash screen reads auth state and redirects immediately.
// It exists purely to give GoRouter a moment to evaluate the session
// before showing the first real screen — avoids a flash of the wrong UI.
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((_) => context.go(AppRoutes.home));
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}