import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/api_client.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/login/register_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/expenses/expenses_screen.dart';
import '../../presentation/screens/expenses/add_expense_screen.dart';
import '../../presentation/screens/expenses/scan_receipt_screen.dart';
import '../../presentation/screens/expenses/scan_result_screen.dart';
import '../../presentation/screens/expenses/expense_success_screen.dart';
import '../../data/models/expense_model.dart';
import '../../presentation/screens/goals/goals_screen.dart';
import '../../presentation/screens/goals/goal_create_screen.dart';
import '../../presentation/screens/goals/goal_contribute_screen.dart';
import '../../presentation/screens/goals/goal_created_screen.dart';
import '../../presentation/screens/goals/goal_detail_screen.dart';
import '../../presentation/screens/goals/goal_success_screen.dart';
import '../../data/models/goal_model.dart';
import '../../presentation/screens/analysis/analysis_screen.dart';
import '../../presentation/screens/analysis/analysis_categories_screen.dart';
import '../../presentation/screens/analysis/analysis_category_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/simulator/simulator_screen.dart';
import '../../presentation/screens/simulator/micro_savings_screen.dart';
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
          } else if (location.startsWith('/simulator')) {
            index = 4;
          } else if (location.startsWith('/profile')) {
            index = 5;
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
            // Hub 1A: decisión entre escanear con OCR o registro manual.
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
            path: '/simulator',
            builder: (context, state) => const SimulatorScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/simulator/micro-ahorro',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MicroSavingsScreen(),
      ),
      // ─── Flujo de metas (fullscreen sobre el Shell) ───────────────────────
      // /goals/create y /goals/success se declaran antes que /goals/:id para
      // que el parámetro no capture esas rutas.
      GoRoute(
        path: '/goals/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoalCreateScreen(),
      ),
      GoRoute(
        path: '/goals/created',
        // 1C-success: celebración al crear una meta (mismo estilo que 1D).
        // Recibe la meta recién creada vía `extra`.
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final goal = data?['goal'] as GoalModel?;
          if (goal == null) {
            // Acceso directo sin datos: volver a la lista.
            return const GoalsScreen();
          }
          return GoalCreatedScreen(goal: goal);
        },
      ),
      GoRoute(
        path: '/goals/success',
        // 1D: celebración al completar una meta. Recibe la meta + el delta
        // real del SmartScore vía `extra`.
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final goal = data?['goal'] as GoalModel?;
          if (goal == null) {
            // Acceso directo sin datos: volver a la lista.
            return const GoalsScreen();
          }
          return GoalSuccessScreen(
            goal: goal,
            scoreDelta: (data?['scoreDelta'] as int?) ?? 0,
          );
        },
      ),
      // ─── Flujo de aporte a meta (① ingresar monto) ────────────────────────
      // Se declara antes que /goals/:id para que el parámetro no la capture.
      GoRoute(
        path: '/goals/:id/contribute',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const GoalsScreen();
          return GoalContributeScreen(goalId: id);
        },
      ),
      GoRoute(
        path: '/goals/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const GoalsScreen();
          return GoalDetailScreen(goalId: id);
        },
      ),
      // ─── Flujo de Análisis (drill-down sobre el Shell) ────────────────────
      // 1B Categorías y (futuro) 1D Detalle son fullscreen con su propio
      // BottomNavBar. Reciben el mes seleccionado por `extra` desde 1A.
      // /analysis/categories se declara antes que /analysis/category/:key.
      GoRoute(
        path: '/analysis/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return AnalysisCategoriesScreen(
            mes: data?['mes'] as int?,
            anio: data?['anio'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/analysis/category/:key',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? 'otros';
          final data = state.extra as Map<String, dynamic>?;
          return AnalysisCategoryDetailScreen(
            categoryKey: key,
            mes: data?['mes'] as int?,
            anio: data?['anio'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/expenses/scan',
        parentNavigatorKey: rootNavigatorKey, // Open scanner fullscreen above ShellRoute
        builder: (context, state) => const ScanReceiptScreen(),
      ),
      GoRoute(
        path: '/expenses/scan/result',
        // 1D: resultado del análisis OCR con campos editables.
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            // Acceso directo sin datos: volver a escanear.
            return const ScanReceiptScreen();
          }
          return ScanResultScreen(scanData: data);
        },
      ),
      GoRoute(
        path: '/expenses/add',
        // Fullscreen sobre el Shell; la pantalla añade su propio
        // BottomNavBar + AppHeader (mismo patrón que micro-ahorro).
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          final prefilledData = state.extra as Map<String, dynamic>?;
          return AddExpenseScreen(
            initialCategory: category,
            prefilledData: prefilledData,
          );
        },
      ),
      GoRoute(
        path: '/expenses/success',
        // 2B: éxito compartido por las ramas manual y OCR.
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final expense = data?['expense'] as ExpenseModel?;
          if (expense == null) {
            // Acceso directo sin gasto: regresar al hub.
            return const ExpensesScreen();
          }
          return ExpenseSuccessScreen(
            expense: expense,
            prevScore: data?['prevScore'] as int?,
            newScore: data?['newScore'] as int?,
          );
        },
      ),
    ],
  );
}
