import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/receipt/presentation/screens/receipt_screen.dart';
import '../providers/supabase_provider.dart';
import '../widgets/app_shell.dart';
import 'home_screen.dart';

abstract class AppRoutes {
  static const splash    = '/';
  static const signIn    = '/sign-in';
  static const signUp    = '/sign-up';
  static const home      = '/home';
  static const budget    = '/budget';
  static const receipt   = '/receipt';
  static const analytics = '/analytics';
}

/// Bridges the Supabase auth stream into a [ChangeNotifier] so
/// GoRouter can listen to it via [refreshListenable] and re-run
/// redirect on every auth state change.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey  = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final _authNotifier      = _AuthChangeNotifier();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final session = ProviderScope.containerOf(context)
          .read(currentUserProvider);

      final location = state.matchedLocation;

      // Treat splash, sign-in, and sign-up all as "unauthenticated" routes.
      // Splash is included here so that after _authNotifier fires,
      // redirect moves the user off the splash screen in both directions.
      final isUnauthRoute =
          location == AppRoutes.splash ||
          location == AppRoutes.signIn ||
          location == AppRoutes.signUp;

      // No session → send to sign in (unless already on an unauth route)
      if (session == null && !isUnauthRoute) return AppRoutes.signIn;

      // Has session → send to home (away from splash or auth screens)
      if (session != null && isUnauthRoute) return AppRoutes.home;

      // No session on splash specifically → send to sign in
      if (session == null && location == AppRoutes.splash) {
        return AppRoutes.signIn;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, __) => const SignUpScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.budget,
            builder: (_, __) => const BudgetScreen(),
          ),
          GoRoute(
            path: AppRoutes.receipt,
            builder: (_, __) => const ReceiptScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (_, __) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Minimal splash screen — just a spinner.
/// All navigation logic is handled by GoRouter's redirect above.
/// This screen exists only to give the router a landing point while
/// the Supabase session is being resolved on app startup.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}