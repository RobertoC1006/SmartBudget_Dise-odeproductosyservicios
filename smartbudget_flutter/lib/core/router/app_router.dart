import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/api_client.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/login/register_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/expenses/expenses_screen.dart';
import '../../presentation/screens/expenses/scan_receipt_screen.dart';
import '../../presentation/screens/goals/goals_screen.dart';
import '../../presentation/screens/analysis/analysis_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/widgets/app_scaffold.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final hasToken = await ApiClient().hasToken();
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!hasToken) {
        if (isLoggingIn || isRegistering) {
          return null; // Let the user stay on login or register screen
        }
        return '/login'; // Redirect to login
      }

      if (hasToken && (isLoggingIn || isRegistering)) {
        return '/'; // If authenticated, redirect to home/dashboard
      }

      return null; // No redirection needed
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          // Determine the active index based on route path
          int index = 0;
          final location = state.matchedLocation;
          if (location.startsWith('/expenses')) {
            index = 1;
          } else if (location.startsWith('/goals')) {
            index = 2;
          } else if (location.startsWith('/analysis')) {
            index = 3;
          } else if (location.startsWith('/profile')) {
            index = 4;
          }

          return AppScaffold(
            currentIndex: index,
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/analysis',
            builder: (context, state) => const AnalysisScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/expenses/scan',
        parentNavigatorKey: rootNavigatorKey, // Open scanner fullscreen above ShellRoute
        builder: (context, state) => const ScanReceiptScreen(),
      ),
    ],
  );
}
