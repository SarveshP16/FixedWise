import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/deposits/presentation/screens/deposit_detail_screen.dart';
import '../../features/deposits/presentation/screens/deposits_list_screen.dart';
import '../../features/deposits/presentation/screens/new_deposit_screen.dart';
import '../../features/holders/presentation/screens/holders_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/whats_new_screen.dart';
import 'app_shell.dart';

/// App-wide route table. A [StatefulShellRoute] gives each bottom-nav tab
/// (Home, Deposits, Calculator, Profile) its own independent navigation
/// stack that's preserved when switching tabs.
///
/// New Deposit, Deposit Detail, and Holders are declared as top-level
/// routes *outside* the shell rather than nested under Deposits/Profile —
/// same rationale as Pulse's router: a nested route would force the
/// Deposits branch onto the stack whenever you deep-link into a detail
/// screen, so the back button would land on the list instead of wherever
/// you actually came from. As independent top-level routes, each one
/// pushes onto the root navigator on top of whatever's showing and
/// fullscreens over the bottom nav.
///
/// Built by a provider (rather than a top-level singleton) so every
/// [ProviderScope] — each widget test included — gets its own [GoRouter]
/// with its own navigation state.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: '/deposits', builder: (context, state) => const DepositsListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/calculator', builder: (context, state) => const CalculatorScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(path: '/deposits/new', builder: (context, state) => const NewDepositScreen()),
      GoRoute(
        path: '/deposits/:id',
        builder: (context, state) => DepositDetailScreen(depositId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/holders', builder: (context, state) => const HoldersScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/whats-new', builder: (context, state) => const WhatsNewScreen()),
    ],
  );
});
